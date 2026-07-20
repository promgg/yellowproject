NX_GR = NX_GR or {}

local gravesById = {}
local sessions = {}
local activeBySource = {}
local prayCooldown = {}
local started = false

local function configError(message)
    print(('^1[nx_graverobbery] Config error:^7 %s'):format(message))
end

local function validateConfig()
    local ok = true
    local seen = {}

    for _, grave in ipairs(Config.Graves) do
        if not NX_GR.IsValidId(grave.id) then
            configError(('invalid grave id: %s'):format(tostring(grave.id)))
            ok = false
        elseif seen[grave.id] then
            configError(('duplicate grave id: %s'):format(grave.id))
            ok = false
        end
        seen[grave.id] = true

        if not Config.Villages[grave.villageId] then
            configError(('grave %s uses missing villageId %s'):format(grave.id, tostring(grave.villageId)))
            ok = false
        end

        if not Config.RewardPools[grave.rewardPool] then
            configError(('grave %s uses missing rewardPool %s'):format(grave.id, tostring(grave.rewardPool)))
            ok = false
        end

        if not grave.coords or type(grave.coords.x) ~= 'number' or type(grave.coords.y) ~= 'number' or type(grave.coords.z) ~= 'number' then
            configError(('grave %s has invalid coords'):format(grave.id))
            ok = false
        end

        if (grave.robbery.cooldownMinutes or 0) < 0 then
            configError(('grave %s has negative cooldown'):format(grave.id))
            ok = false
        end

        if not grave.robbery.requiredItem or grave.robbery.requiredItem == '' or (grave.robbery.requiredItemAmount or 0) < 1 then
            configError(('grave %s has invalid required item settings'):format(grave.id))
            ok = false
        end
    end

    return ok
end

local function rebuildGraveLookup()
    gravesById = {}
    for _, grave in ipairs(Config.Graves) do
        gravesById[grave.id] = grave
    end
end

local function cancelSession(token, reason)
    local session = sessions[token]
    if not session then return end

    NX_GR.Cooldowns.Release(session.graveId, token)
    sessions[token] = nil
    if activeBySource[session.source] == token then
        activeBySource[session.source] = nil
    end
    TriggerClientEvent('nx_graverobbery:client:cancelSession', session.source, reason)
    NX_GR.Cooldowns.Sync(session.graveId)
end

local function cancelSourceSession(source, reason)
    local token = activeBySource[source]
    if token then
        cancelSession(token, reason)
    end
end

local function validateStart(source, graveId)
    if not NX_GR.Security.CheckRateLimit(source, 'requestStart') then return nil end
    if not started then return nil, 'unavailable' end

    if not NX_GR.IsValidId(graveId) or not gravesById[graveId] then
        NX_GR.Security.Log(source, 'requestStart', 'invalid_grave', { graveId = tostring(graveId) })
        return nil, 'unavailable'
    end

    local grave = gravesById[graveId]
    local character = NX_GR.VORP.GetCharacter(source)
    if not character then return nil, 'unavailable' end

    if not grave.enabled or not grave.robbery.enabled then return nil, 'unavailable' end
    if not Config.Villages[grave.villageId] or not Config.Villages[grave.villageId].enabled then return nil, 'unavailable' end
    if activeBySource[source] then
        NX_GR.Security.Log(source, 'requestStart', 'already_in_session', { character = character, graveId = grave.id, villageId = grave.villageId })
        return nil, 'unavailable'
    end

    -- กันตั้งแต่ต้น (ตอนกด E ค้าง) ไม่ให้เริ่มขุดหลุมศพในเมืองบ้านเกิดตัวเองได้เลย
    local playerVillageId = NX_GR.CitySelect.GetPlayerVillageId(source, character)
    if playerVillageId and playerVillageId == grave.villageId then
        return nil, 'own_village'
    end

    if not NX_GR.Schedule.IsVillageOpenNow(grave.villageId) then
        return nil, 'not_open_yet'
    end

    -- ต้องอยู่ในวงอีเวนต์ของสุสานนั้นจริงๆ ถึงจะขุดได้ (เมืองที่ไม่มีอีเวนต์เช่นแดนใต้ผ่านตลอด)
    -- ปิดช่องยิง requestStart จากนอกวงตรงๆ โดยไม่เคยเข้าวงเลย
    if not NX_GR.Event.IsOccupant(source, grave.villageId) then
        NX_GR.Security.Log(source, 'requestStart', 'not_in_zone', { character = character, graveId = grave.id, villageId = grave.villageId })
        return nil, 'not_in_zone'
    end

    if not NX_GR.Cooldowns.IsAvailable(grave.id) then
        local state = NX_GR.Cooldowns.Get(grave.id)
        return nil, state and state.state == 'reserved' and 'reserved' or 'cooldown'
    end

    if not NX_GR.Security.IsAllowedTime() then return nil, 'unavailable' end
    if not NX_GR.Security.IsAliveAndOnFoot(source, character) then return nil, 'unavailable' end

    local near = NX_GR.Security.IsNearGrave(source, grave, Config.Security.startDistanceTolerance)
    if not near then
        NX_GR.Security.Log(source, 'requestStart', 'too_far', { character = character, graveId = grave.id, villageId = grave.villageId })
        return nil, 'too_far'
    end

    if Config.Security.requirePlayerVillage and not playerVillageId then
        return nil, 'no_village'
    end

    if not NX_GR.VORP.HasItem(source, grave.robbery.requiredItem, grave.robbery.requiredItemAmount) then
        return nil, 'need_shovel'
    end

    return { grave = grave, character = character }
end

RegisterNetEvent('nx_graverobbery:server:requestStart', function(graveId)
    local source = source
    local result, reason = validateStart(source, graveId)
    if Config.Debug then
        print(('[nx_graverobbery] requestStart source=%s grave=%s result=%s reason=%s'):format(
            source, tostring(graveId), result and 'ok' or 'rejected', tostring(reason)
        ))
    end
    if not result then
        if reason then NX_GR.VORP.Notify(source, NX_GR.Locale(reason)) end
        return
    end

    local token = NX_GR.Security.NewToken(source, result.grave.id)
    if not NX_GR.Cooldowns.Reserve(result.grave.id, token) then
        NX_GR.VORP.Notify(source, NX_GR.Locale('reserved'))
        return
    end

    local current = os.time()
    sessions[token] = {
        token = token,
        source = source,
        characterId = result.character.charIdentifier,
        graveId = result.grave.id,
        villageId = result.grave.villageId,
        startedAt = current,
        earliestCompleteAt = current + Config.Security.minimumDigDurationSeconds,
        expiresAt = current + Config.Security.sessionExpireSeconds,
        used = false,
    }
    activeBySource[source] = token

    NX_GR.Cooldowns.Sync(result.grave.id)
    TriggerClientEvent('nx_graverobbery:client:startSession', source, {
        token = token,
        graveId = result.grave.id,
        durationMs = Config.Digging.durationMs,
        animation = Config.Digging,
        skillCheck = Config.SkillCheck,
    })
end)

RegisterNetEvent('nx_graverobbery:server:complete', function(token)
    local source = source
    if not NX_GR.Security.CheckRateLimit(source, 'complete') then return end
    if type(token) ~= 'string' then return end

    local session = sessions[token]
    if not session then
        NX_GR.Security.Log(source, 'complete', 'missing_session')
        return
    end

    local grave = gravesById[session.graveId]
    local character = NX_GR.VORP.GetCharacter(source)
    local current = os.time()

    if session.source ~= source then
        NX_GR.Security.Log(source, 'complete', 'wrong_source', { graveId = session.graveId, villageId = session.villageId })
        return
    end

    if not character or character.charIdentifier ~= session.characterId then
        NX_GR.Security.Log(source, 'complete', 'character_changed', { character = character, graveId = session.graveId, villageId = session.villageId })
        cancelSession(token, 'unavailable')
        return
    end

    if session.used or current > session.expiresAt then
        NX_GR.Security.Log(source, 'complete', session.used and 'token_reuse' or 'expired_session', { character = character, graveId = session.graveId, villageId = session.villageId })
        cancelSession(token, 'unavailable')
        return
    end

    if current < session.earliestCompleteAt then
        NX_GR.Security.Log(source, 'complete', 'completed_too_fast', { character = character, graveId = session.graveId, villageId = session.villageId })
        cancelSession(token, 'unavailable')
        return
    end

    local near = NX_GR.Security.IsNearGrave(source, grave, Config.Security.completeDistanceTolerance)
    if not near or not NX_GR.Security.IsAliveAndOnFoot(source, character) then
        NX_GR.Security.Log(source, 'complete', 'failed_revalidation', { character = character, graveId = session.graveId, villageId = session.villageId })
        cancelSession(token, 'too_far')
        return
    end

    local state = NX_GR.Cooldowns.Get(grave.id)
    if not state or state.state ~= 'reserved' or state.reservedBy ~= token then
        NX_GR.Security.Log(source, 'complete', 'reservation_mismatch', { character = character, graveId = grave.id, villageId = grave.villageId })
        cancelSession(token, 'unavailable')
        return
    end

    if not NX_GR.VORP.HasItem(source, grave.robbery.requiredItem, grave.robbery.requiredItemAmount) then
        cancelSession(token, 'need_shovel')
        return
    end

    if grave.robbery.consumeItem and not NX_GR.VORP.RemoveItem(source, grave.robbery.requiredItem, grave.robbery.requiredItemAmount) then
        NX_GR.Security.Log(source, 'complete', 'remove_item_failed', { character = character, graveId = grave.id, villageId = grave.villageId })
        cancelSession(token, 'unavailable')
        return
    end

    -- ให้รางวัลก่อนตัดสิทธิ์หลุม — ถ้า inventory เต็ม/add item ล้มเหลว หลุมยังไม่ถูกใช้ ผู้เล่นลองใหม่ได้
    -- (เดิมสลับลำดับ ทำให้หลุมถูกเผาทิ้งไปเปล่าๆ ถ้า reward ล้มเหลวหลัง commit คูลดาวน์ไปแล้ว)
    if not NX_GR.Rewards.Give(source, character, grave) then
        cancelSession(token, nil) -- Rewards.Give แจ้งเตือนสาเหตุไปแล้ว (inventory_full ฯลฯ) ไม่ต้องซ้ำ
        return
    end

    session.used = true
    if not NX_GR.Cooldowns.Commit(grave, character) then
        NX_GR.Security.Log(source, 'complete', 'cooldown_commit_failed', { character = character, graveId = grave.id, villageId = grave.villageId })
        cancelSession(token, 'unavailable')
        return
    end

    sessions[token] = nil
    activeBySource[source] = nil
    NX_GR.Cooldowns.Sync(grave.id)
    NX_GR.EventNotify.Refresh(grave.villageId)

    NX_GR.Alerts.Dispatch(grave)
end)

RegisterNetEvent('nx_graverobbery:server:cancel', function(token, reason)
    local source = source
    if not NX_GR.Security.CheckRateLimit(source, 'cancel') then return end
    local session = sessions[token]
    if not session or session.source ~= source then
        NX_GR.Security.Log(source, 'cancel', 'invalid_token')
        return
    end
    cancelSession(token, reason == 'skill_failed' and 'failed' or nil)
end)

RegisterNetEvent('nx_graverobbery:server:pray', function(graveId)
    local source = source
    if not NX_GR.Security.CheckRateLimit(source, 'pray') then return end
    if not Config.Pray.enabled then return end

    local current = os.time()
    if prayCooldown[source] and prayCooldown[source] > current then return end
    prayCooldown[source] = current + Config.Pray.cooldownSeconds

    local grave = gravesById[graveId]
    if not grave then return end

    local near = NX_GR.Security.IsNearGrave(source, grave, Config.Security.startDistanceTolerance)
    if not near then return end

    TriggerClientEvent('nx_graverobbery:client:startPray', source, { graveId = graveId, durationMs = Config.Pray.durationMs })
end)

RegisterNetEvent('nx_graverobbery:server:requestState', function()
    local source = source
    if not NX_GR.Security.CheckRateLimit(source, 'requestState') then return end
    NX_GR.Cooldowns.Sync(nil, source)
end)

local function adminReply(source, message)
    if source == 0 then
        print(('[nx_graverobbery] %s'):format(message))
    else
        NX_GR.VORP.Notify(source, message)
    end
end

local function requireAdmin(source)
    if NX_GR.VORP.IsAdmin(source) then return true end
    adminReply(source, NX_GR.Locale('admin_denied'))
    return false
end

-- log ตัวตนแอดมินที่สั่ง reset ไว้ด้วย ไม่ใช่แค่ผลลัพธ์ — ตรวจสอบย้อนหลังได้ว่าใครกดอะไร
local function logAdminAction(source, action, data)
    local identifier = source > 0 and NX_GR.VORP.GetIdentifier(source) or 'console'
    NX_GR.Security.Log(source, 'admin', ('%s by %s'):format(action, tostring(identifier)), data)
end

RegisterCommand('gravereset', function(source, args)
    if not requireAdmin(source) then return end
    local graveId = args[1]
    local grave = graveId and gravesById[graveId]
    if grave and NX_GR.Cooldowns.ResetGrave(graveId) then
        NX_GR.Cooldowns.Sync(graveId)
        NX_GR.EventNotify.Refresh(grave.villageId)
        logAdminAction(source, 'gravereset', { graveId = graveId, villageId = grave.villageId })
        adminReply(source, NX_GR.Locale('reset_done'))
    end
end, false)

RegisterCommand('graveresetvillage', function(source, args)
    if not requireAdmin(source) then return end
    local villageId = args[1]
    if not villageId then return end
    NX_GR.Cooldowns.ResetVillage(villageId, gravesById)
    NX_GR.Cooldowns.Sync()
    NX_GR.EventNotify.Refresh(villageId)
    logAdminAction(source, 'graveresetvillage', { villageId = villageId })
    adminReply(source, NX_GR.Locale('reset_done'))
end, false)

RegisterCommand('graveresetall', function(source)
    if not requireAdmin(source) then return end
    NX_GR.Cooldowns.ResetAll()
    NX_GR.Cooldowns.Sync()
    NX_GR.EventNotify.RefreshAll()
    logAdminAction(source, 'graveresetall')
    adminReply(source, NX_GR.Locale('reset_done'))
end, false)

RegisterCommand('graveinfo', function(source, args)
    if not requireAdmin(source) then return end
    local graveId = args[1]
    local grave = graveId and gravesById[graveId]
    if not grave then return end
    local state = NX_GR.Cooldowns.Get(graveId)
    adminReply(source, ('%s village=%s state=%s availableAt=%s'):format(graveId, grave.villageId, state and state.state or 'unknown', state and tostring(state.availableAt) or 'nil'))
end, false)

RegisterCommand('gravecheck', function(source)
    if not requireAdmin(source) then return end
    local coords = NX_GR.Security.GetPlayerCoords(source)
    if not coords then return end

    local nearest, nearestDistance
    for _, grave in pairs(gravesById) do
        local distance = NX_GR.Distance(coords, grave.coords)
        if not nearestDistance or distance < nearestDistance then
            nearest = grave
            nearestDistance = distance
        end
    end

    if nearest then
        local state = NX_GR.Cooldowns.Get(nearest.id)
        adminReply(source, ('nearest=%s distance=%.2f village=%s state=%s'):format(nearest.id, nearestDistance, nearest.villageId, state and state.state or 'unknown'))
    end
end, false)

AddEventHandler('playerDropped', function()
    local droppedSource = source
    cancelSourceSession(droppedSource, nil)
    prayCooldown[droppedSource] = nil
    NX_GR.Security.ClearPlayer(droppedSource)
    NX_GR.CitySelect.InvalidatePlayer(droppedSource)
end)

AddEventHandler('vorp:SelectedCharacter', function(source)
    cancelSourceSession(source, 'unavailable')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for token in pairs(sessions) do
        cancelSession(token, nil)
    end
end)

CreateThread(function()
    if not validateConfig() then return end
    rebuildGraveLookup()
    NX_GR.Cooldowns.Init(gravesById)
    started = true
    NX_GR.Cooldowns.Sync()

    while true do
        Wait((Config.Security.cleanupIntervalSeconds or 30) * 1000)
        NX_GR.Cooldowns.CleanupExpired()
        local current = os.time()
        for token, session in pairs(sessions) do
            if current > session.expiresAt then
                NX_GR.Security.Log(session.source, 'cleanup', 'session_expired', { graveId = session.graveId, villageId = session.villageId })
                cancelSession(token, 'unavailable')
            end
        end
    end
end)
