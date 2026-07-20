LP_DM = LP_DM or {}

-- ── ฟังการตายจาก vorp_core โดยตรง ──
--
-- vorp_core/client/respawnsystem.lua:218-236 poll IsPlayerDead() แล้วยิง event นี้ให้พร้อมใช้
-- (killerServerId มาจาก GetPedSourceOfDeath + IsPedAPlayer, deathCause มาจาก GetPedCauseOfDeath)
-- source = เหยื่อ — เป็นเส้นทางที่ทำงานจริงบน RDR3 และมี lp_leaderboard/lp_airdropteam ใช้อยู่แล้ว
--
-- เดิมไฟล์นี้รับ event ของตัวเองจาก client ที่ดักด้วย gameEventTriggered ซึ่งเป็นของ GTA5
-- ไม่เคยยิงบน RDR3 = ไม่เคยมีอะไรมาถึงตรงนี้เลย
--
-- ⚠️ MJ-Respwan/core/client.lua:476 ยิง event เดียวกันนี้ซ้ำอีกตัวนอกเหนือจาก vorp_core เอง
--    ถ้าทั้งคู่ทำงานพร้อมกัน หนึ่งการตายจะมาถึงสองครั้ง ต้องกันซ้ำต่อเหยื่อที่นี่
--    (คูลดาวน์คู่ผู้ฆ่า-เหยื่อ 10 นาทีกันได้อยู่แล้วก็จริง แต่พึ่งมันอย่างเดียวไม่ได้ —
--     มันจะกลืน event ซ้ำไปเงียบๆ ทำให้แยกไม่ออกว่าเป็นการยิงซ้ำหรือเป็นคิลจริงที่โดนคูลดาวน์)
local lastDeathAt = {} -- [victimSource] = os.clock() ครั้งล่าสุดที่รับการตายของคนนี้
local DEATH_DEDUPE_SECONDS = 1.0

RegisterNetEvent('vorp_core:Server:OnPlayerDeath', function(killerServerId, deathCause)
    local victimSource = source
    if not LP_DM.Event.IsActive() then return end

    local currentClock = os.clock()
    if lastDeathAt[victimSource] and (currentClock - lastDeathAt[victimSource]) < DEATH_DEDUPE_SECONDS then
        return
    end
    lastDeathAt[victimSource] = currentClock

    killerServerId = tonumber(killerServerId)
    deathCause = tonumber(deathCause)
    if not killerServerId or killerServerId == 0 then return end -- ตายเองจากสิ่งแวดล้อม/NPC
    if not deathCause then return end
    if killerServerId == victimSource then return end
    if not GetPlayerName(killerServerId) then return end -- ต้องเป็นผู้เล่นที่ต่ออยู่จริงตอนนี้เท่านั้น

    local ok, reason = LP_DM.Event.ReportKill(killerServerId, victimSource, deathCause)
    if Config.Debug then
        print(('[lp_deathmatch] death victim=%s killer=%s cause=%s ok=%s reason=%s'):format(
            victimSource, killerServerId, tostring(deathCause), tostring(ok), tostring(reason)
        ))
    end
end)

RegisterNetEvent('lp_deathmatch:server:requestState', function()
    local requestSource = source
    if not LP_DM.Security.CheckRateLimit(requestSource, 'requestState') then return end

    local payload = LP_DM.Event.GetSyncPayload()
    if payload then
        TriggerClientEvent('lp_deathmatch:client:start', requestSource, payload)
    end
end)

local function adminReply(source, message)
    if source == 0 then
        print(('[lp_deathmatch] %s'):format(message))
    else
        LP_DM.VORP.Notify(source, message)
    end
end

local function requireAdmin(source)
    if LP_DM.VORP.IsAdmin(source) then return true end
    adminReply(source, LP_DM.Locale('admin_denied'))
    return false
end

RegisterCommand('dmforcestart', function(source)
    if not requireAdmin(source) then return end
    if LP_DM.Event.IsActive() then
        adminReply(source, LP_DM.Locale('already_running'))
        return
    end
    LP_DM.Schedule.MarkTriggeredToday()
    LP_DM.Event.Start()
    adminReply(source, LP_DM.Locale('force_started'))
end, false)

RegisterCommand('dmforceend', function(source)
    if not requireAdmin(source) then return end
    if not LP_DM.Event.IsActive() then
        adminReply(source, LP_DM.Locale('not_running'))
        return
    end
    LP_DM.Event.End()
    adminReply(source, LP_DM.Locale('force_ended'))
end, false)

AddEventHandler('playerDropped', function()
    local droppedSource = source
    LP_DM.Security.ClearPlayer(droppedSource)
    LP_DM.CitySelect.InvalidatePlayer(droppedSource)
    lastDeathAt[droppedSource] = nil
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if LP_DM.Event.IsActive() then
        TriggerClientEvent('lp_deathmatch:client:end', -1, { cities = {}, groups = {}, aborted = true })
    end
end)

CreateThread(function()
    while true do
        Wait(30000)
        if LP_DM.Schedule.ShouldStartNow() then
            LP_DM.Event.Start()
        end
    end
end)
