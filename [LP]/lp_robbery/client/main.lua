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

-- ── Result mailbox for the bank request→confirm round trip (store has no
-- request/confirm dance anymore — it's a single lockpick-gated loot call) ────
local lastBankResult = nil -- { id, subId, success }

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

-- ── Face the interaction point before playing any lockpick/plant animation ──
-- ไม่งั้นท่าเล่นลอย ๆ กลางอากาศไม่หันเข้าเคาน์เตอร์/ตู้เซฟ — คำนวณ heading จาก
-- ตำแหน่งผู้เล่น -> จุดเป้าหมาย แล้วหันทันที (SetEntityHeading, ไม่รอ turn ค่อยๆหมุน
-- เพราะกำลังจะ disableMovement ต่อทันทีอยู่แล้ว) — pattern เดียวกับ rsg-doorlock.
local function faceTarget(coords)
    local ped = PlayerPedId()
    local pc = GetEntityCoords(ped)
    SetEntityHeading(ped, GetHeadingFromVector_2d(coords.x - pc.x, coords.y - pc.y))
end

-- ── หาเครื่องคิดเงินจริงในโลก (Config.RegisterModel) ใกล้จุดที่ config ไว้ ──────────
-- เรียกตอนจะ interact เท่านั้น (ไม่ใช่ทุก tick) — ถ้าเจอ object จริง ใช้พิกัดของมันหันหน้า
-- แทนพิกัดที่ config เล็งไว้คร่าว ๆ, หาไม่เจอก็ fallback กลับไปใช้ spot.coords เดิม
local function resolveStoreFacePoint(spot)
    if spot.kind ~= 'store' or not Config.RegisterModel then return spot.coords end
    local hash = GetHashKey(Config.RegisterModel)
    local obj = GetClosestObjectOfType(spot.coords.x, spot.coords.y, spot.coords.z, Config.RegisterSearchRadius, hash, false, false, false)
    if obj ~= 0 then
        return GetEntityCoords(obj)
    end
    return spot.coords
end

-- ── Hand prop builder ────────────────────────────────────────────────────────
-- Config.Props เก็บ bone เป็น "ชื่อ" (resolve ผ่าน GetEntityBoneIndexByName) ปกติ
-- แต่บาง prop (เช่นไดนาไมต์) ตำแหน่งที่ดูถูกต้องอ้างอิงจาก bone ID ดิบ (GetPedBoneIndex)
-- แทน — ใส่ def.boneId เป็นตัวเลขเพื่อใช้ทางนั้นแทน def.bone. ส่งผลลัพธ์เป็น field
-- `prop` ให้ lp_progbar สร้าง/แปะ/ลบเองครบทุกทาง.
local function buildProp(def)
    if not def or not def.model then return nil end
    local ped = PlayerPedId()
    local bone = def.boneId and GetPedBoneIndex(ped, def.boneId)
        or GetEntityBoneIndexByName(ped, def.bone or 'SKEL_R_Hand')
    return {
        model    = def.model,
        bone     = bone,
        coords   = def.coords,
        rotation = def.rotation,
    }
end

-- ── Manual hand-prop (for the lockpick MINIGAME phase, which runs BEFORE
-- lp_progbar:Progress() starts and so isn't covered by its built-in prop
-- lifecycle). Spawned right before exports.lp_minigame:Lockpick() and kept
-- attached straight through the following progress bar — the tool stays in
-- the player's hand continuously across both phases instead of popping in
-- only once progbar starts. Same spawn/attach math as lp_progbar's own
-- internal spawnProp(), duplicated here since it isn't exported.
local activeHandProp = nil

local function spawnHandProp(def)
    if not def or not def.model then return nil end
    local hash = GetHashKey(def.model)
    RequestModel(hash)
    local guard = 0
    while not HasModelLoaded(hash) and guard < 200 do
        Wait(0)
        guard = guard + 1
    end
    if not HasModelLoaded(hash) then return nil end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local obj = CreateObject(hash, coords.x, coords.y, coords.z, true, true, true)
    SetModelAsNoLongerNeeded(hash)

    local bone = GetEntityBoneIndexByName(ped, def.bone or 'SKEL_R_Hand')
    local c = def.coords or { x = 0.0, y = 0.0, z = 0.0 }
    local r = def.rotation or { x = 0.0, y = 0.0, z = 0.0 }
    AttachEntityToEntity(obj, ped, bone, c.x, c.y, c.z, r.x, r.y, r.z, true, true, false, true, 2, true, false, false)

    activeHandProp = obj
    return obj
end

local function removeHandProp()
    local obj = activeHandProp
    activeHandProp = nil
    if obj and DoesEntityExist(obj) then
        DetachEntity(obj, true, true)
        DeleteEntity(obj)
    end
end

-- ── Action flows ──────────────────────────────────────────────────────────────
-- ร้าน: ขั้นตอนเดียว — เดินเข้าไป [E] -> lockpick -> progbar -> sv:lootStore
-- (ไม่มีระเบิด ไม่มี plant/wait อีกต่อไป — ธนาคารเท่านั้นที่ยังใช้ small_bomb)
local function startStoreLoot(spot)
    if isBusy then return end
    isBusy = true
    faceTarget(resolveStoreFacePoint(spot)) -- หันเข้าเครื่องคิดเงินจริง (ถ้าหาเจอ) ก่อนเล่นมินิเกม/ท่างัด

    -- lockpick gate — พลาด = แจ้งเตือนเฉย ๆ ไม่ยิง sv:lootStore, ไม่เปลี่ยน state
    -- กด [E] ใหม่ได้ทันที (poll loop โชว์ prompt เดิมต่อ)
    local heldDuringMinigame = false
    if Config.Lockpick.EnabledForStore then
        spawnHandProp(Config.Props.loot) -- ถือเหล็กงัดตั้งแต่ตอนเล่นมินิเกม ไม่ใช่แค่ตอน progbar
        heldDuringMinigame = true
        local picked = exports.lp_minigame:Lockpick(Config.Lockpick.Store)
        if not picked then
            removeHandProp()
            exports.pNotify:SendNotification({ type = 'error', text = 'งัดไม่สำเร็จ ลองใหม่อีกครั้ง', timeout = 3000 })
            isBusy = false
            return
        end
    end

    exports.lp_progbar:Progress({
        duration = Config.LootDuration.store,
        label = 'กำลังงัดตู้เซฟ...',
        controlDisables = { disableMovement = true },
        animation = { animDict = 'script_common@jail_cell@unlock@key', anim = 'action', flags = 1 }, -- ท่ามือรื้อ/งัด
        -- ถ้าถือเหล็กงัดมาจากตอนมินิเกมแล้ว ไม่ต้องให้ progbar สร้าง prop ซ้ำ (จะเห็น 2 ชิ้น)
        prop = heldDuringMinigame and nil or buildProp(Config.Props.loot),
    }, function(cancelled)
        if heldDuringMinigame then removeHandProp() end
        if cancelled then
            exports.pNotify:SendNotification({ type = 'error', text = 'ยกเลิก', timeout = 3000 })
            isBusy = false
            return
        end
        TriggerServerEvent('lp_robbery:sv:lootStore', spot.id)
        isBusy = false
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

        faceTarget(spot.coords) -- หันเข้าตู้เซฟก่อนวางระเบิด

        exports.lp_progbar:Progress({
            duration = Config.PlantDuration,
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

-- ธนาคาร: หลังระเบิดห้องนิรภัยแล้วเข้า cooldown 'unlocking' — เก็บของขั้นนี้
-- (lockpick gate ปิดอยู่ตาม Config.Lockpick.EnabledForBank เผื่อเปิดใช้ภายหลัง)
local function startBankLoot(spot)
    if isBusy then return end
    isBusy = true
    faceTarget(spot.coords) -- หันเข้าตู้เซฟก่อนเล่นมินิเกม/ท่างัด

    local heldDuringMinigame = false
    if Config.Lockpick.EnabledForBank then
        spawnHandProp(Config.Props.loot) -- ถือเหล็กงัดตั้งแต่ตอนเล่นมินิเกม ไม่ใช่แค่ตอน progbar
        heldDuringMinigame = true
        local picked = exports.lp_minigame:Lockpick(Config.Lockpick.Bank)
        if not picked then
            removeHandProp()
            exports.pNotify:SendNotification({ type = 'error', text = 'งัดไม่สำเร็จ ลองใหม่อีกครั้ง', timeout = 3000 })
            isBusy = false
            return
        end
    end

    exports.lp_progbar:Progress({
        duration = Config.LootDuration.bank,
        label = 'กำลังเก็บของ...',
        controlDisables = { disableMovement = true },
        animation = { animDict = 'script_common@jail_cell@unlock@key', anim = 'action', flags = 1 }, -- ท่ามือรื้อ/งัด (ตามต้นฉบับ)
        -- ถ้าถือเหล็กงัดมาจากตอนมินิเกมแล้ว ไม่ต้องให้ progbar สร้าง prop ซ้ำ (จะเห็น 2 ชิ้น)
        prop = heldDuringMinigame and nil or buildProp(Config.Props.loot),
    }, function(cancelled)
        if heldDuringMinigame then removeHandProp() end
        if cancelled then
            exports.pNotify:SendNotification({ type = 'error', text = 'ยกเลิก', timeout = 3000 })
            isBusy = false
            return
        end
        TriggerServerEvent('lp_robbery:sv:lootBank', spot.id, spot.subId)
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

                if nearest.kind == 'store' then
                    -- ร้าน: ขั้นตอนเดียว (lockpick) — สถานะที่เป็นไปได้มีแค่ fresh กับ 'looted' (cooldown)
                    if type(state) == 'table' and state.state == 'looted' then
                        local remaining = (state.relootAt or 0) - now
                        if remaining > 0 then
                            setDisplay('display', '🔒 เพิ่งถูกปล้น งัดได้อีกใน ' .. FormatTime(remaining), nearest.stateKey)
                        elseif within then
                            setDisplay('hold', '[E] งัดตู้เซฟ', nearest.stateKey, function() startStoreLoot(nearest) end)
                        else
                            clearDisplay()
                        end
                    elseif within then
                        setDisplay('hold', '[E] งัดตู้เซฟ', nearest.stateKey, function() startStoreLoot(nearest) end)
                    else
                        clearDisplay()
                    end
                else
                    -- ธนาคาร: bomb-plant -> fuse -> explosion -> unlocking cooldown -> เก็บของ (ไม่เปลี่ยน)
                    if type(state) == 'table' and state.state == 'looted' then
                        local remaining = (state.relootAt or 0) - now
                        if remaining > 0 then
                            setDisplay('display', '🔒 เพิ่งถูกปล้น งัดได้อีกใน ' .. FormatTime(remaining), nearest.stateKey)
                        elseif within then
                            setDisplay('hold', '[E] วางระเบิด', nearest.stateKey, function() startBank(nearest) end)
                        else
                            clearDisplay()
                        end
                    elseif type(state) == 'table' and state.state == 'unlocking' then
                        local remaining = state.unlockTime - now
                        if remaining > 0 then
                            setDisplay('display', '🔴 ห้องนิรภัยกำลังเย็นตัว: ' .. FormatTime(remaining), nearest.stateKey)
                        elseif within then
                            setDisplay('hold', '[E] เก็บของ', nearest.stateKey, function() startBankLoot(nearest) end)
                        else
                            setDisplay('display', '🟢 พร้อมเก็บของ - เข้าใกล้อีก', nearest.stateKey)
                        end
                    elseif within then
                        setDisplay('hold', '[E] วางระเบิด', nearest.stateKey, function() startBank(nearest) end)
                    else
                        clearDisplay()
                    end
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
    removeHandProp() -- กันเหล็กงัดค้างมือถ้า stop ระหว่างมินิเกม (progbar เคลียร์ prop ของตัวเองแล้ว)
    for blip in pairs(alertBlips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    alertBlips = {}
end)
