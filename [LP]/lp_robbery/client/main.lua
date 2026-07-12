-- lp_robbery / client/main.lua
-- Client only ever REQUESTS or CONFIRMS — it never decides a robbery's outcome.
-- All state (nil/unlocking/open/looted) lives in GlobalState.lp_robbery_states,
-- written exclusively by the server. This file: distance-poll for the hold-E
-- interaction (coarse, not per-frame), a state-change-gated status display, and
-- the client-side minigame/progress-bar choreography.

-- ── Server time sync (os.time() doesn't exist client-side) ──────────────────
local ServerTimeOffset = 0

RegisterNetEvent('lp_robbery:cl:syncTime', function(serverTime)
    ServerTimeOffset = serverTime - (GetGameTimer() / 1000)
end)

local function GetServerTime()
    return math.floor((GetGameTimer() / 1000) + ServerTimeOffset)
end

CreateThread(function()
    repeat Wait(1000) until LocalPlayer.state.IsInSession
    TriggerServerEvent('lp_robbery:sv:requestTime')
end)

local function FormatTime(seconds)
    seconds = math.max(0, math.floor(seconds))
    local mins = math.floor(seconds / 60)
    local secs = seconds % 60
    return ('%02d:%02d'):format(mins, secs)
end

-- ── Flattened interaction spots (built once) ─────────────────────────────────
local spots = {}
for id, store in pairs(Config.Stores) do
    spots[#spots + 1] = {
        kind = 'store', id = id, subId = nil,
        coords = store.coords, label = store.label, stateKey = 'store_' .. id,
    }
end
for id, bank in pairs(Config.Banks) do
    for vi, vault in ipairs(bank.vaults) do
        spots[#spots + 1] = {
            kind = 'bank', id = id, subId = vi,
            coords = vault.coords, label = bank.label, stateKey = id .. '_' .. vi,
        }
    end
end

-- ── Busy flag (blocks re-entry while a request/minigame/progressbar is running) ──
local isBusy = false

-- ── Result mailboxes for the request→confirm round trip ─────────────────────
local lastStoreResult = nil -- { id, success }
local lastBankResult  = nil -- { id, subId, success }

RegisterNetEvent('lp_robbery:cl:storeRequestResult', function(storeId, success)
    lastStoreResult = { id = storeId, success = success }
end)

RegisterNetEvent('lp_robbery:cl:bankRequestResult', function(bankId, vaultId, success)
    lastBankResult = { id = bankId, subId = vaultId, success = success }
end)

-- ── lp_textui display state machine ──────────────────────────────────────────
-- kind: nil (hidden) | 'hold' (interactive, TextUIHold) | 'display' (plain TextUI)
local shownKind, shownText, shownKey = nil, nil, nil

local function clearDisplay()
    if shownKind == 'hold' then
        exports.lp_textui:CancelHold()
    elseif shownKind == 'display' then
        exports.lp_textui:HideUI()
    end
    shownKind, shownText, shownKey = nil, nil, nil
end

local function setDisplay(kind, text, key, cb)
    if shownKind == kind and shownText == text and shownKey == key then return end -- no change, skip (perf)

    if shownKind == 'hold' then
        exports.lp_textui:CancelHold()
    elseif shownKind == 'display' then
        exports.lp_textui:HideUI()
    end

    if kind == 'hold' then
        exports.lp_textui:TextUIHold(text, Config.HoldMs, function()
            shownKind, shownText, shownKey = nil, nil, nil -- lp_textui already auto-hid on hold completion
            cb()
        end, Config.KEY_E)
    else
        exports.lp_textui:TextUI(text)
    end
    shownKind, shownText, shownKey = kind, text, key
end

-- ── Hand prop builder ────────────────────────────────────────────────────────
-- Config.Props เก็บ bone เป็น "ชื่อ" — resolve เป็น index ตรงนี้ (ตามที่ RDR3 build
-- นี้ต้องการ) แล้วส่งเป็น field `prop` ให้ lp_progbar สร้าง/แปะ/ลบเองครบทุกทาง.
local function buildProp(def)
    if not def or not def.model then return nil end
    return {
        model    = def.model,
        bone     = GetEntityBoneIndexByName(PlayerPedId(), def.bone or 'SKEL_R_Hand'),
        coords   = def.coords,
        rotation = def.rotation,
    }
end

-- ── Action flows ──────────────────────────────────────────────────────────────
local function startRobbery(spot)
    if isBusy then return end
    isBusy = true
    lastStoreResult = nil
    TriggerServerEvent('lp_robbery:sv:requestStore', spot.id)

    CreateThread(function()
        local deadline = GetGameTimer() + 5000
        while not lastStoreResult and GetGameTimer() < deadline do Wait(0) end
        local res = lastStoreResult
        lastStoreResult = nil

        if not res or res.id ~= spot.id or not res.success then
            isBusy = false
            return
        end

        local ok = exports.lp_minigame:Spacebar()
        if not ok then
            exports.pNotify:SendNotification({ type = 'error', text = 'ระเบิดเสียเปล่า! ของหมดแล้ว', timeout = 4000 })
            isBusy = false
            return
        end

        exports.lp_progbar:Progress({
            duration = Config.PlantDuration.store,
            label = 'กำลังวางระเบิด...',
            controlDisables = { disableMovement = true },
            animation = { task = 'WORLD_HUMAN_CROUCH_INSPECT' }, -- นั่งยองวางระเบิด (lp_progbar หยุดท่าให้เองตอนจบ/ยกเลิก)
            prop = buildProp(Config.Props.plant), -- มัดไดนาไมต์ในมือ (lp_progbar ลบให้เองทุกทาง)
        }, function(cancelled)
            if cancelled then
                exports.pNotify:SendNotification({ type = 'error', text = 'ยกเลิก', timeout = 3000 })
                isBusy = false
                return
            end
            TriggerServerEvent('lp_robbery:sv:confirmStore', spot.id)
            isBusy = false
        end)
    end)
end

local function startBank(spot)
    if isBusy then return end
    isBusy = true
    lastBankResult = nil
    TriggerServerEvent('lp_robbery:sv:requestBank', spot.id, spot.subId)

    CreateThread(function()
        local deadline = GetGameTimer() + 5000
        while not lastBankResult and GetGameTimer() < deadline do Wait(0) end
        local res = lastBankResult
        lastBankResult = nil

        if not res or res.id ~= spot.id or res.subId ~= spot.subId or not res.success then
            isBusy = false
            return
        end

        exports.lp_progbar:Progress({
            duration = Config.PlantDuration.bank,
            label = 'กำลังวางระเบิด...',
            controlDisables = { disableMovement = true },
            animation = { task = 'WORLD_HUMAN_CROUCH_INSPECT' }, -- นั่งยองวางระเบิด
            prop = buildProp(Config.Props.plant), -- มัดไดนาไมต์ในมือ
        }, function(cancelled)
            if cancelled then
                exports.pNotify:SendNotification({ type = 'error', text = 'ยกเลิก', timeout = 3000 })
                isBusy = false
                return
            end

            exports.pNotify:SendNotification({
                type = 'error', text = 'หนีเร็ว! ระเบิดใน 15 วิ!', timeout = Config.BankFuseTime * 1000,
            })

            CreateThread(function()
                Wait(Config.BankFuseTime * 1000)
                TriggerServerEvent('lp_robbery:sv:confirmBankBlow', spot.id, spot.subId)
                isBusy = false
            end)
        end)
    end)
end

local function startLoot(spot)
    if isBusy then return end
    isBusy = true
    local duration = (spot.kind == 'bank') and Config.LootDuration.bank or Config.LootDuration.store

    exports.lp_progbar:Progress({
        duration = duration,
        label = 'กำลังเก็บของ...',
        controlDisables = { disableMovement = true },
        animation = { animDict = 'script_common@jail_cell@unlock@key', anim = 'action', flags = 1 }, -- ท่ามือรื้อ/งัด (ตามต้นฉบับ)
        prop = buildProp(Config.Props.loot), -- เหล็กงัดในมือ
    }, function(cancelled)
        if cancelled then
            exports.pNotify:SendNotification({ type = 'error', text = 'ยกเลิก', timeout = 3000 })
            isBusy = false
            return
        end
        TriggerServerEvent('lp_robbery:sv:loot', spot.kind, spot.id, spot.subId)
        isBusy = false
    end)
end

-- ── Explosion sync + police alert ────────────────────────────────────────────
RegisterNetEvent('lp_robbery:cl:syncExplosion', function(bankId, vaultId)
    local bank = Config.Banks[bankId]
    local vault = bank and bank.vaults and bank.vaults[vaultId]
    if not vault then return end

    local pos = vault.coords
    local pc = GetEntityCoords(PlayerPedId())
    if #(pc - pos) > 150.0 then return end -- everyone near renders/hears it; far clients skip the FX

    AddExplosion(pos.x, pos.y, pos.z, Config.Explosion.type, Config.Explosion.radius, true, false, 1.0)
    if #(pc - pos) <= 40.0 then
        ShakeGameplayCam(Config.Explosion.cameraShake, Config.Explosion.shake)
    end
    exports.pNotify:SendNotification({ type = 'success', text = 'ห้องนิรภัยถูกระเบิด! กำลังเย็นตัวลง...', timeout = 5000 })
end)

local alertBlips = {}

RegisterNetEvent('lp_robbery:cl:policeAlert', function(label, coords)
    exports.pNotify:SendNotification({
        type = 'alert', text = ('แจ้งเตือน: มีการปล้นที่ %s'):format(label), timeout = 15000,
    })
    PlaySoundFrontend('Core_Fill_Up', 'Consumption_Sounds', true, 0)

    if not coords then return end

    local blip = BlipAddForCoords(1664425300, coords.x, coords.y, coords.z)
    SetBlipSprite(blip, GetHashKey('blip_ambient_hitching_post'), true)
    Citizen.InvokeNative(0x9CB1A1623062F402, blip, CreateVarString(10, 'LITERAL_STRING', label or 'Robbery')) -- _SET_BLIP_NAME_FROM_PLAYER_STRING
    Citizen.InvokeNative(0x662D364ABF16DE2F, blip, GetHashKey('BLIP_MODIFIER_MP_COLOR_8')) -- red modifier
    alertBlips[blip] = true

    SetTimeout(300000, function()
        if DoesBlipExist(blip) then RemoveBlip(blip) end
        alertBlips[blip] = nil
    end)
end)

-- ── Main poll thread (coarse, ~500ms — NOT per-frame) ────────────────────────
CreateThread(function()
    repeat Wait(1000) until LocalPlayer.state.IsInSession
    while true do
        Wait(500)
        if not isBusy then
            local pos = GetEntityCoords(PlayerPedId())
            local nearest, nearestDist = nil, nil
            for _, s in ipairs(spots) do
                local d = #(pos - s.coords)
                if d <= Config.DisplayRange and (not nearestDist or d < nearestDist) then
                    nearest, nearestDist = s, d
                end
            end

            if not nearest then
                clearDisplay()
            else
                local states = GlobalState.lp_robbery_states or {}
                local state = states[nearest.stateKey]
                local within = nearestDist <= Config.Range
                local now = GetServerTime()

                if type(state) == 'table' and state.state == 'looted' then
                    -- เพิ่งถูกปล้น: โชว์เวลานับถอยหลังจนกว่าจะงัดได้อีก (relootAt); หมดเวลา = ตีเป็น fresh
                    local remaining = (state.relootAt or 0) - now
                    if remaining > 0 then
                        setDisplay('display', '🔒 เพิ่งถูกปล้น งัดได้อีกใน ' .. FormatTime(remaining), nearest.stateKey)
                    elseif within then
                        setDisplay('hold', '[E] วางระเบิด', nearest.stateKey, function()
                            if nearest.kind == 'bank' then startBank(nearest) else startRobbery(nearest) end
                        end)
                    else
                        clearDisplay()
                    end
                elseif type(state) == 'table' and state.state == 'unlocking' then
                    local remaining = state.unlockTime - now
                    if remaining > 0 then
                        local icon = (nearest.kind == 'bank') and '🔴 ห้องนิรภัยกำลังเย็นตัว: ' or '🟠 ตู้เซฟกำลังปลดล็อค: '
                        setDisplay('display', icon .. FormatTime(remaining), nearest.stateKey)
                    elseif within then
                        setDisplay('hold', '[E] เก็บของ', nearest.stateKey, function() startLoot(nearest) end)
                    else
                        setDisplay('display', '🟢 พร้อมเก็บของ - เข้าใกล้อีก', nearest.stateKey)
                    end
                elseif within then
                    setDisplay('hold', '[E] วางระเบิด', nearest.stateKey, function()
                        if nearest.kind == 'bank' then startBank(nearest) else startRobbery(nearest) end
                    end)
                else
                    clearDisplay()
                end
            end
        end
    end
end)

-- ── Cleanup ───────────────────────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    clearDisplay()
    exports.lp_textui:HideUI()
    for blip in pairs(alertBlips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    alertBlips = {}
end)
