--[[
    lp_textui — key-prompt text UI with an arc progress ring

    Two independent axes, both borrowed from rimlay-toastify:

    A) Interaction mode — show() vs showHold()
       (1) Plain show — caller owns the timing/input, lp_textui just displays.
       (2) Hold-to-interact — lp_textui owns the key polling + ring itself;
           caller just gets a callback when the hold actually completes.
           Releasing early silently resets the ring; the callback never fires.

    B) Position mode — normal vs world-anchored
       (1) Normal — fixed at bottom-center of the screen (default).
       (2) World-anchored — floats above a 3D world coordinate, re-projected
           to screen space every frame via GetScreenCoordFromWorldCoord.
           Hides itself automatically when the point goes off-screen/behind
           the camera. Pass `worldAnchor = { coords = vector3, offset = vector3|nil }`
           as the last argument to TextUI/TextUIHold to enable it.

    ------------------------------------------------------------------
    USAGE
    ------------------------------------------------------------------

    -- (1) Plain show — key badge auto-extracted from "[E]" in the message:
    exports.lp_textui:TextUI("[E] เพื่อเปิดประตู")
    exports.lp_textui:TextUI("เปิดประตู", "E")   -- or pass the key explicitly
    exports.lp_textui:HideUI()

    -- Externally-driven ring (you control start/stop/reset yourself):
    exports.lp_textui:StartProgress(3000)
    exports.lp_textui:StopProgress()   -- freeze the ring where it is
    exports.lp_textui:ResetProgress()  -- snap the ring back to empty

    -- (2) Hold-to-interact — lp_textui polls the key itself every frame:
    exports.lp_textui:TextUIHold("[E] ค้างเพื่อขุด", 3000, function()
        print("held for the full 3s")
    end)
    -- optional 4th arg: control hash to poll (defaults to E, 0x17BEC168)
    exports.lp_textui:CancelHold()   -- abort early, no callback, hides UI

    -- World-anchored (3rd arg on TextUI, 5th on TextUIHold) — floats over a chest, NPC, etc:
    exports.lp_textui:TextUI("[E] เปิดหีบ", nil, { coords = chestCoords, offset = vector3(0.0, 0.0, 0.3) })
    exports.lp_textui:TextUIHold("[E] ค้างเพื่อขุด", 3000, callback, nil, { coords = digSpot })

    -- Server-triggered (same event names, fire via TriggerClientEvent):
    --   lp_textui:client:show(message, key, worldAnchor)
    --   lp_textui:client:hide()
    --   lp_textui:client:showHold(message, holdMs, callback, controlCode, worldAnchor)  -- same-client only (funcref)
    --   lp_textui:client:cancelHold()

    ------------------------------------------------------------------
    EXPORTS
      TextUI(message, key, worldAnchor, ownerName)   -- ownerName optional; defaults to invoking resource
      HideUI(ownerName)
      StartProgress(duration)
      StopProgress()
      ResetProgress()
      TextUIHold(message, holdMs, callback, controlCode, worldAnchor, ownerName)
      CancelHold(ownerName)
      IsHoldActive(ownerName)
    ------------------------------------------------------------------
]]

local isShowing  = false
local holdActive = false
local holdGen    = 0
local worldGen   = 0
local currentOwner = nil
local holdOwner = nil
local isSuppressed = false
local suppressOwners = {}
local suppressGen = {}
local setSitRestScenariosBlocked
local blockNearbyAmbientPrompts

-- โหมด world: คำนวณตำแหน่งจอทุกเฟรม (native เบา) แต่ยิง SendNUIMessage เฉพาะตอนค่าที่จอ
-- เปลี่ยนจริงเท่านั้น — ตอนผู้เล่น/กล้องนิ่ง (เคสส่วนใหญ่ตอนยืนอ่าน/รอโต้ตอบ) พิกัดจอจะเท่าเดิม
-- ทุกเฟรม ยิง NUI message ซ้ำๆ ทั้งที่ไม่มีอะไรเปลี่ยนคือส่วนที่กิน resmon จริง (cost หลักอยู่ที่
-- IPC/serialize ข้าม CEF ไม่ใช่ตัว native เอง) ตัดตรงนี้ลด SendNUIMessage ได้เกือบทั้งหมดตอนยืนนิ่ง
-- generation counter กัน thread เก่าค้างทับ thread ใหม่เมื่อสลับ anchor/ปิด UI
local WORLD_POS_EPSILON = 0.0008 -- หน่วย normalized 0-1 ของจอ ต่ำกว่านี้ถือว่าไม่ขยับ (ไม่ต้องส่งซ้ำ)

local function worldPosThread(anchor)
    worldGen = worldGen + 1
    local gen = worldGen
    Citizen.CreateThread(function()
        local lastOnScreen, lastSx, lastSy = nil, nil, nil
        while gen == worldGen and isShowing do
            local ox, oy, oz = 0.0, 0.0, 0.0
            if anchor.offset then ox, oy, oz = anchor.offset.x or 0.0, anchor.offset.y or 0.0, anchor.offset.z or 0.0 end
            local onScreen, sx, sy = GetScreenCoordFromWorldCoord(
                anchor.coords.x + ox, anchor.coords.y + oy, anchor.coords.z + oz
            )
            local changed = onScreen ~= lastOnScreen
                or lastSx == nil or math.abs(sx - lastSx) > WORLD_POS_EPSILON
                or lastSy == nil or math.abs(sy - lastSy) > WORLD_POS_EPSILON
            if changed then
                SendNUIMessage({ action = 'lp_textui:worldPos', onScreen = onScreen and true or false, x = sx, y = sy })
                lastOnScreen, lastSx, lastSy = onScreen, sx, sy
            end
            Citizen.Wait(0)
        end
    end)
end

local function resolveOwner(ownerName)
    return tostring(ownerName or GetInvokingResource() or GetCurrentResourceName())
end

local function canAcquire(owner)
    if currentOwner == owner then return true end
    return currentOwner == nil and not isShowing and not holdActive
end

local function TextUI(message, key, worldAnchor, ownerName)
    if isSuppressed then return false end

    local owner = resolveOwner(ownerName)
    if not canAcquire(owner) then return false end

    isShowing = true
    currentOwner = owner
    worldGen  = worldGen + 1 -- ปิด world thread เก่า (ถ้ามี) ก่อนเปิดของใหม่
    SendNUIMessage({ action = 'lp_textui:show', message = message or '', key = key, world = worldAnchor ~= nil })
    if worldAnchor then worldPosThread(worldAnchor) end
    return true
end

local function HideUI(ownerName)
    local owner = resolveOwner(ownerName)
    if currentOwner ~= nil and currentOwner ~= owner then return false end
    if currentOwner == nil and holdOwner ~= nil and holdOwner ~= owner then return false end
    if not isShowing and not holdActive then return false end

    if holdActive and (holdOwner == nil or holdOwner == owner) then
        holdActive = false
        holdOwner = nil
        holdGen = holdGen + 1
        setSitRestScenariosBlocked(false)
        blockNearbyAmbientPrompts(false)
    end

    isShowing = false
    currentOwner = nil
    worldGen  = worldGen + 1 -- หยุด world thread ที่รันอยู่ (ถ้ามี)
    SendNUIMessage({ action = 'lp_textui:hide' })
    return true
end

local function StartProgress(duration)
    if isSuppressed then return false end
    SendNUIMessage({ action = 'lp_textui:progress', duration = duration })
    return true
end

local function StopProgress()
    SendNUIMessage({ action = 'lp_textui:progress_stop' })
end

local function ResetProgress()
    SendNUIMessage({ action = 'lp_textui:progress_reset' })
end

local function setHoldProgress(pct)
    SendNUIMessage({ action = 'lp_textui:holdProgress', pct = pct })
end

-- ปิด/เปิด ambient scenario ที่ทำให้ตัวละครนั่ง/พักเองใกล้ก้อนหิน ต้นไม้ ฯลฯ
-- ระหว่างกดค้าง (DisableControlAction เพียงอย่างเดียวกันไม่ได้ เพราะ engine
-- สั่ง TASK_START_SCENARIO เองอีกชั้นหนึ่ง ไม่ได้เช็คผ่าน IsControlPressed)
-- flag 472-475 อ้างอิงจาก CPED_CONFIG_FLAGS (femga/rdr3_discoveries)
setSitRestScenariosBlocked = function(blocked)
    local ped = PlayerPedId()
    SetPedConfigFlag(ped, 472, blocked) -- PCF_DisableSittingScenarios
    SetPedConfigFlag(ped, 473, blocked) -- PCF_DisableAutoSittingScenarios
    SetPedConfigFlag(ped, 474, blocked) -- PCF_DisableRestingScenarios
    SetPedConfigFlag(ped, 475, blocked) -- PCF_DisableAutoRestingScenarios
end

-- ม้า/NPC ใกล้ๆ ขโมยปุ่ม E ไปตอนถือค้าง (native ambient action ของเกม — ขึ้นม้า, จับคอ/บีบคอ NPC —
-- เป็นระบบ context-prompt คนละระบบกับ DisableControlAction/IsDisabledControlPressed
-- ต้องกันที่ ped config flag ของเป้าหมายเอง)
-- flag 136 = PCF_CannotBeMounted (ม้า, ใช้จริงใน bcc-stables), flag 169 = PCF_DisableGrappleByPlayer
-- (NPC จับคอ/บีบคอ — คนละ flag กับม้า) 3m ครอบคลุมระยะที่ native เริ่มขึ้น prompt เผื่อไว้พอดี
-- เก็บค่าเดิมของแต่ละตัวไว้ก่อนแก้ (GetPedConfigFlag) แล้วคืนค่าจริงตอนจบ ไม่ยิง false มั่ว
-- เพราะบาง ped (เช่นม้าคนอื่นที่ไม่ใช่เจ้าของ) ปกติก็ตั้ง flag ป้องกันไว้อยู่แล้วโดย default
local guardedPeds = {} -- [pedHandle] = { flag = 136|169, original = bool }

blockNearbyAmbientPrompts = function(blocked)
    if not blocked then
        for ped, data in pairs(guardedPeds) do
            if DoesEntityExist(ped) then
                SetPedConfigFlag(ped, data.flag, data.original)
            end
        end
        guardedPeds = {}
        return
    end

    local playerCoords = GetEntityCoords(PlayerPedId())
    for _, entity in pairs(GetGamePool('CPed')) do
        if DoesEntityExist(entity) and not IsPedAPlayer(entity) and guardedPeds[entity] == nil then
            local dist = #(playerCoords - GetEntityCoords(entity))
            if dist <= 3.0 then
                -- IsThisModelAHorse คืนค่าเป็นเลข 0/1 ไม่ใช่ boolean จริง — ใน Lua เลข 0 เป็น truthy
                -- (ต่างจากภาษาอื่น) เช็คแบบ `if IsThisModelAHorse(...)` เฉยๆ จะติด true เสมอ ต้อง
                -- เทียบค่าตรงๆ กับ true/1 เท่านั้นถึงจะถูก
                local isHorseRaw = IsThisModelAHorse(GetEntityModel(entity))
                local isHorse = isHorseRaw == true or isHorseRaw == 1
                local flag = isHorse and 136 or 169
                guardedPeds[entity] = { flag = flag, original = GetPedConfigFlag(entity, flag, true) }
                SetPedConfigFlag(entity, flag, true)
            end
        end
    end
end

-- ── Mode 2: hold-to-interact — polls controlCode itself, drives the ring,
-- fires callback() only on a full, uninterrupted hold. Release early = reset.
local function TextUIHold(message, holdMs, callback, controlCode, worldAnchor, ownerName)
    if isSuppressed then return false end

    local owner = resolveOwner(ownerName)
    if not canAcquire(owner) then return false end
    controlCode = controlCode or 0x17BEC168 -- E

    if not TextUI(message, nil, worldAnchor, owner) then return false end
    setHoldProgress(0)
    holdActive = true
    holdOwner  = owner
    holdGen    = holdGen + 1
    local gen  = holdGen
    setSitRestScenariosBlocked(true)
    blockNearbyAmbientPrompts(true)

    Citizen.CreateThread(function()
        local heldStart = nil
        local lastSentPct = nil -- ปัดเป็นจำนวนเต็มก่อนส่ง กันยิง SendNUIMessage ทุกเฟรมทั้งที่ % ยังไม่ขยับ
        while gen == holdGen and holdActive do
            Citizen.Wait(0)
            -- กันปุ่มชนกับ ambient scenario ของเกมหลัก (เช่น นั่งลงเองใกล้ก้อนหิน/ต้นไม้)
            -- โดยบล็อกไม่ให้ native เห็นปุ่มนี้ แล้วอ่านผ่าน IsDisabledControlPressed แทน
            DisableControlAction(0, controlCode, true)
            if IsDisabledControlPressed(0, controlCode) then
                heldStart = heldStart or GetGameTimer()
                local elapsed = GetGameTimer() - heldStart
                local pct = math.min(100, (elapsed / holdMs) * 100)
                local pctRounded = math.floor(pct + 0.5)
                if pctRounded ~= lastSentPct then
                    setHoldProgress(pct)
                    lastSentPct = pctRounded
                end
                if elapsed >= holdMs then
                    holdActive = false
                    holdOwner = nil
                    HideUI(owner)
                    setSitRestScenariosBlocked(false)
                    blockNearbyAmbientPrompts(false)
                    -- callback may be a cross-resource funcref that's since gone away
                    local ok, err = pcall(callback)
                    if not ok then print('[lp_textui] TextUIHold callback error: ' .. tostring(err)) end
                    return
                end
            elseif heldStart then
                heldStart = nil
                setHoldProgress(0) -- released before completing -> reset, no callback
            end
        end
    end)
    return true
end

local function CancelHold(ownerName)
    local owner = resolveOwner(ownerName)
    if not holdActive or (holdOwner ~= nil and holdOwner ~= owner) then return false end
    holdActive = false
    holdOwner  = nil
    holdGen    = holdGen + 1
    HideUI(owner)
    setSitRestScenariosBlocked(false)
    blockNearbyAmbientPrompts(false)
    return true
end

local function IsHoldActive(ownerName)
    local owner = resolveOwner(ownerName)
    return holdActive == true and holdOwner == owner and currentOwner == owner and isShowing == true
end

-- Temporarily blocks every TextUI caller while a full-screen NUI is open.
-- Suppression is tracked per invoking resource so a bank -> locker handoff, or
-- two overlapping UIs, cannot release another resource's active lock.
local function SetSuppressed(state, releaseDelayMs, ownerName)
    local owner = tostring(ownerName or GetInvokingResource() or "lp_textui")
    suppressGen[owner] = (suppressGen[owner] or 0) + 1
    local gen = suppressGen[owner]

    if state == true then
        suppressOwners[owner] = true
        isSuppressed = true
        local activeOwner = holdOwner or currentOwner
        if activeOwner then
            CancelHold(activeOwner)
            HideUI(activeOwner)
        end
        return
    end

    local delay = math.max(0, tonumber(releaseDelayMs) or 0)
    if delay == 0 then
        suppressOwners[owner] = nil
        isSuppressed = next(suppressOwners) ~= nil
        return
    end

    SetTimeout(delay, function()
        if gen == suppressGen[owner] then
            suppressOwners[owner] = nil
            isSuppressed = next(suppressOwners) ~= nil
        end
    end)
end

-- กัน ped ที่ถูกกันไว้ค้าง flag ถาวรถ้า resource นี้ restart กลางที่ถือค้างพอดี
-- (guardedPeds เป็น local state หายตอน restart แต่ flag บนตัว ped ในโลกยังอยู่ ต้องคืนค่าก่อน)
AddEventHandler('onResourceStop', function(res)
    if suppressOwners[res] then
        suppressGen[res] = (suppressGen[res] or 0) + 1
        suppressOwners[res] = nil
        isSuppressed = next(suppressOwners) ~= nil
    end

    local activeOwner = holdOwner or currentOwner
    if activeOwner == res or (activeOwner and activeOwner:sub(1, #res + 1) == res .. ':') then
        if activeOwner then
            CancelHold(activeOwner)
            HideUI(activeOwner)
        end
    end

    if res ~= GetCurrentResourceName() then return end
    blockNearbyAmbientPrompts(false)
end)

exports('TextUI', TextUI)
exports('HideUI', HideUI)
exports('StartProgress', StartProgress)
exports('StopProgress', StopProgress)
exports('ResetProgress', ResetProgress)
exports('TextUIHold', TextUIHold)
exports('CancelHold', CancelHold)
exports('IsHoldActive', IsHoldActive)
exports('SetSuppressed', SetSuppressed)

RegisterNetEvent('lp_textui:client:show', TextUI)
RegisterNetEvent('lp_textui:client:hide', HideUI)
RegisterNetEvent('lp_textui:client:progress', StartProgress)
RegisterNetEvent('lp_textui:client:progressStop', StopProgress)
RegisterNetEvent('lp_textui:client:progressReset', ResetProgress)
RegisterNetEvent('lp_textui:client:showHold', TextUIHold)
RegisterNetEvent('lp_textui:client:cancelHold', CancelHold)
RegisterNetEvent('lp_textui:client:suppress', SetSuppressed)

-- ── Test commands (F8 console) ──────────────────────────────────────────
-- /textui_test        show "[E] ..." once (key auto-extracted from brackets)
-- /textui_progress    show + externally-driven ring fill over 3s (StartProgress), then hide
-- /textui_test_hold   real hold-to-interact — hold E for 3s to fire the callback, release early to reset
-- /textui_test_world  world-anchored prompt floating 1m in front of you — walk around, it tracks
-- /textui_hide        hide / cancel any active hold immediately

RegisterCommand('textui_test', function()
    TextUI('[E] Testing lp_textui')
end, false)

RegisterCommand('textui_test_world', function()
    local ped    = PlayerPedId()
    local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 1.5, 0.5)
    TextUI('[E] ทดสอบลอยติดพิกัดโลก', nil, { coords = coords })
end, false)

RegisterCommand('textui_progress', function()
    TextUI('[E] ทดสอบ progress ring (ควบคุมจากภายนอก)')
    StartProgress(3000)
    Citizen.SetTimeout(3000, HideUI)
end, false)

RegisterCommand('textui_test_hold', function()
    TextUIHold('[E] ค้างไว้ 3 วิเพื่อทดสอบ hold-to-interact', 3000, function()
        print('[lp_textui] textui_test_hold: held to completion!')
    end)
end, false)

RegisterCommand('textui_hide', function()
    CancelHold()
    HideUI()
end, false)

-- ── Reposition higher while mounted/in a vehicle (horse, wagon, cart) ──────
CreateThread(function()
    local lastState = false
    while true do
        Citizen.Wait(500)
        if isShowing then
            local ped = PlayerPedId()
            local state = IsPedOnMount(ped) or IsPedInAnyVehicle(ped, false)
            if state ~= lastState then
                lastState = state
                SendNUIMessage({ action = 'lp_textui:mounted', mounted = state })
            end
        end
    end
end)
