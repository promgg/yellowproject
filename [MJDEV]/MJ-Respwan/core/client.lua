local Keys = {
    -- Mouse buttons
    ["MOUSE1"] = 0x07CE1E61,
    ["MOUSE2"] = 0xF84FA74F,
    ["MOUSE3"] = 0xCEE12B50,
    ["MWUP"] = 0x3076E97C,
    ["A"] = 0x7065027D,
    ["B"] = 0x4CC0E2FE,
    ["C"] = 0x9959A6F0,
    ["D"] = 0xB4E465B4,
    ["E"] = 0xCEFD9220,
    ["F"] = 0xB2F377E8,
    ["G"] = 0x760A9C6F,
    ["H"] = 0x24978A28,
    ["I"] = 0xC1989F95,
    ["J"] = 0xF3830D8E,
    ["L"] = 0x80F28E95,
    ["M"] = 0xE31C6A41,
    ["N"] = 0x4BC9DABB,
    ["O"] = 0xF1301666,
    ["P"] = 0xD82E0BD2,
    ["Q"] = 0xDE794E3E,
    ["R"] = 0xE30CD707,
    ["S"] = 0xD27782E3,
    ["U"] = 0xD8F73058,
    ["V"] = 0x7F8D09B8,
    ["W"] = 0x8FD015D8,
    ["X"] = 0x8CC9CD42,
    ["Z"] = 0x26E9DC00,
    ["RIGHTBRACKET"] = 0xA5BDCD3C,
    ["LEFTBRACKET"] = 0x430593AA,
    ["CTRL"] = 0xDB096B85,
    ["TAB"] = 0xB238FE0B,
    ["SHIFT"] = 0x8FFC75D6,
    ["SPACEBAR"] = 0xD9D0E1C0,
    ["ENTER"] = 0xC7B5340A,
    ["BACKSPACE"] = 0x156F7119,
    ["LALT"] = 0x8AAA0AD4,
    ["DEL"] = 0x4AF4D473,
    ["PGUP"] = 0x446258B6,
    ["PGDN"] = 0x3C3DD371,
    ["F1"] = 0xA8E3F467,
    ["F4"] = 0x1F6D95E5,
    ["F6"] = 0x3C0A40F2,
    ["1"] = 0xE6F612E4,
    ["2"] = 0x1CE6D9EB,
    ["3"] = 0x4F49CC4C,
    ["4"] = 0x8F9F9E58,
    ["5"] = 0xAB62E997,
    ["6"] = 0xA1FDE2A6,
    ["7"] = 0xB03A913B,
    ["8"] = 0x42385422,
    ["DOWN"] = 0x05CA7C52,
    ["UP"] = 0x6319DB71,
    ["LEFT"] = 0xA65EBAB4,
    ["RIGHT"] = 0xDEB34313
}

local cam
local angleY = 0.0
local angleZ = 0.0
local passive = false
local isDead = false
-- ต้องอยู่ scope บนสุดเดียวกับ isDead (ไม่ใช่ local แยกไว้ตรง DEATH HANDLER ด้านล่าง) เพราะทุก
-- จุดที่ตั้ง isDead = false (E-press, item revive, admin revive, vorp_core:respawnPlayer,
-- playerSpawned) ต้อง reset ตัวนี้ด้วย ไม่งั้น DEATH HANDLER ที่ท้ายไฟล์จะไม่ยอมเช็ค isDead ซ้ำ
-- ตอนตายรอบถัดไป (sentDeathLog ค้างที่ true ตลอด เพราะ path ปกติของมันเช็คแค่ isDead ที่ถูกรีเซ็ต
-- ไปก่อนหน้านี้แล้วจากที่อื่น เลยไม่มีจังหวะไหนที่ isDead ยังเป็น true ตอน IsPlayerDead() กลับเป็น false)
local sentDeathLog = false
-- วนตรวจจับการกดปุ่ม
local CoolDown = 60
local lastHelpRequest = 0   -- GetGameTimer()/1000 ครั้งล่าสุดที่กดขอความช่วยเหลือ
local lastClearBody = 0     -- GetGameTimer()/1000 ครั้งล่าสุดที่กด CLEAR BODY

-- ===== สถานะปุ่มบนหน้าจอตาย =====
-- respawnReady = ปุ่ม RESPAWN เปิดใช้เมื่อ countdown ถึง 0 (ขับจาก StartAutoRespawn)
local respawnReady = false
local clearBodyEnabled     = (Config.Buttons and Config.Buttons.clearBody) or false
local callHelpEnabled      = (Config.Buttons and Config.Buttons.callHelp) or false
local leaveActivityEnabled = (Config.Buttons and Config.Buttons.leaveActivity) or false
local callDoctorEnabled    = (Config.Buttons and Config.Buttons.callDoctor) or false

-- map ชื่อปุ่ม -> control hash (จากตาราง Keys ด้านบน)
local btnKeys = {
    clearBody     = Keys[Config.Keys.clearBody]     or Keys['G'],
    respawn       = Keys[Config.Keys.respawn]       or Keys['E'],
    leaveActivity = Keys[Config.Keys.leaveActivity] or Keys['X'],
    callDoctor    = Keys[Config.Keys.callDoctor]    or Keys['B'],
    callHelp      = Keys[Config.Keys.callHelp]      or Keys['H'],
}

-- ส่งสถานะ enable/disable ของปุ่มทั้ง 5 ไปให้ NUI
local function SendButtonStates()
    SendNUIMessage({
        type          = 'buttons',
        clearBody     = clearBodyEnabled,    -- ซ่อนไว้ก่อน (Config.Buttons.clearBody)
        respawn       = respawnReady,        -- เปิดเมื่อ countdown = 0
        leaveActivity = leaveActivityEnabled,
        callDoctor    = callDoctorEnabled,
        callHelp      = callHelpEnabled,     -- ซ่อนไว้ก่อน (Config.Buttons.callHelp)
    })
end

-- แจ้งเตือนผ่าน pNotify — pcall กัน error กรณี resource pNotify ยังไม่ขึ้น/ไม่ได้ ensure
local function Notify(text, ntype, timeout)
    pcall(function()
        exports.pNotify:SendNotification({
            type = ntype or 'info',
            text = text,
            timeout = timeout or 3000,
        })
    end)
end

-- ฟังก์ชันปัดทศนิยม
local function round(value, decimals)
    local power = 10 ^ (decimals or 0)
    return math.floor(value * power + 0.5) / power
end

function ProcessNewPosition()
    local mouseX = 0.0
    local mouseY = 0.0

    -- keyboard
    if (IsInputDisabled(0)) then
        -- rotation
        mouseX = GetDisabledControlNormal(1, 0x6BC904FC) * 8.0
        mouseY = GetDisabledControlNormal(1, 0x84574AE8) * 8.0

        -- controller
    else
        -- rotation
        mouseX = GetDisabledControlNormal(1, 0x6BC904FC) * 0.5
        mouseY = GetDisabledControlNormal(1, 0x84574AE8) * 0.5
    end

    angleZ = angleZ - mouseX -- around Z axis (left / right)
    angleY = angleY + mouseY -- up / down
    -- limit up / down angle to 90°
    if (angleY > 89.0) then
        angleY = 89.0
    elseif (angleY < -89.0) then
        angleY = -89.0
    end

    local pCoords = GetEntityCoords(PlayerPedId())

    local behindCam = {
        x = pCoords.x + ((Cos(angleZ) * Cos(angleY)) + (Cos(angleY) * Cos(angleZ))) / 2 * (0.5 + 0.5),
        y = pCoords.y + ((Sin(angleZ) * Cos(angleY)) + (Cos(angleY) * Sin(angleZ))) / 2 * (0.5 + 0.5),
        z = pCoords.z + ((Sin(angleY))) * (0.5 + 0.5)
    }
    local rayHandle = StartShapeTestRay(pCoords.x, pCoords.y, pCoords.z + 0.5, behindCam.x, behindCam.y, behindCam.z,
        -1, PlayerPedId(), 0)
    local a, hitBool, hitCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHandle)

    local maxRadius = 3.5
    if (hitBool and Vdist(pCoords.x, pCoords.y, pCoords.z + 0.0, hitCoords) < 0.5 + 0.5) then
        maxRadius = Vdist(pCoords.x, pCoords.y, pCoords.z + 0.0, hitCoords)
    end

    local offset = {
        x = ((Cos(angleZ) * Cos(angleY)) + (Cos(angleY) * Cos(angleZ))) / 2 * maxRadius,
        y = ((Sin(angleZ) * Cos(angleY)) + (Cos(angleY) * Sin(angleZ))) / 2 * maxRadius,
        z = ((Sin(angleY))) * maxRadius
    }

    local pos = {
        x = pCoords.x + offset.x,
        y = pCoords.y + offset.y,
        z = pCoords.z + offset.z
    }

    return pos
end

local function StartDeathCam()
    ClearFocus()
    -- reset มุมกล้องทุกครั้งที่เริ่มตาย ไม่งั้นตายรอบถัดไปกล้องเริ่มจากมุมค้างเดิม
    angleZ = 0.0
    angleY = 0.0
    local playerPed = PlayerPedId()
    local pos = GetEntityCoords(playerPed)
    cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", pos.x, pos.y, pos.z, 0, 0, 0, GetGameplayCamFov(), false, 0)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 1000, true, false, 0)
end

local function ProcessCamControls()

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(PlayerPedId())
    Citizen.InvokeNative(0x05AB44D906738426)

    local newPos = ProcessNewPosition()

    Citizen.InvokeNative(0xF9EE7D419EE49DE6, cam, newPos.x, newPos.y, newPos.z)
    Citizen.InvokeNative(0x948B39341C3A40C2, cam, playerCoords.x, playerCoords.y, playerCoords.z)
end

local function EndDeathCam()
    NetworkSetInSpectatorMode(false, PlayerPedId())
    ClearFocus()
    RenderScriptCams(false, false, 0, true, false, 0)
    DestroyCam(cam, false)
    cam = nil
    DestroyAllCams(true)
end

-- ลูป free-look ของ death cam — เดิม ProcessCamControls ไม่เคยถูกเรียกเลย กล้องเลยล็อคนิ่ง
-- ที่นี่ขับมันทุกเฟรมตอน isDead (และกล้องยังอยู่) ให้หมุนรอบศพตามเมาส์ได้ (orbit จำกัดก้ม/เงย 89°)
Citizen.CreateThread(function()
    while true do
        if isDead and cam then
            Citizen.Wait(0)
            ProcessCamControls()
        else
            Citizen.Wait(200)
        end
    end
end)

-- ===== การกระทำของปุ่มทั้ง 5 (hotkey ต่อปุ่ม ไม่ใช้เมาส์/NUI focus) =====

-- ปุ่ม 2/3: เกิดใหม่ที่โรงพยาบาล — ยกตรรกะ E-respawn เดิมจาก StartAutoRespawn มาไว้ที่เดียว
-- (RESPAWN AT HOSPITAL และ LeaveActivityRespawn ใช้ตัวเดียวกัน ต่างกันแค่ "รอ countdown หรือไม่")
local function RespawnAtHospital()
    DoScreenFadeOut(1000)
    Wait(1000)

    EndDeathCam()
    TriggerServerEvent("vorp_core:PlayerRespawnInternal", true)
    FreezeEntityPosition(PlayerPedId(), false)

    DoScreenFadeIn(1500)
    isDead = false
    sentDeathLog = false
    CloseUi()

    TriggerServerEvent("vorp:ImDead", false)
    LocalPlayer.state:set('isDead', false, true)
end

-- ปุ่ม 1: CLEAR BODY [G] — resync ร่างเพื่อแก้ design/desync ของศพ (เทียบเท่า clear body ของ ESX)
local function ClearBody()
    local now = GetGameTimer() / 1000
    if now - lastClearBody < Config.ClearBodyCooldown then
        local remaining = math.ceil(Config.ClearBodyCooldown - (now - lastClearBody))
        Notify('กรุณารอสักครู่ (' .. remaining .. ' วินาที)', 'error', 3000)
        return
    end
    lastClearBody = now

    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    -- ตอกพิกัดเดิมซ้ำ + สั่ง ragdoll ใหม่ เพื่อบังคับให้ network re-render ร่าง (แก้ร่างค้าง/ลอย)
    SetEntityCoordsNoOffset(ped, c.x, c.y, c.z, false, false, false)
    SetPedToRagdoll(ped, 2000, 2000, 0, false, false, false)
    Notify('ซิงค์ร่างกายใหม่แล้ว', 'success', 3000)
end

-- ปุ่ม 5: CALL FOR HELP [H] — ส่งสัญญาณขอความช่วยเหลือให้ผู้เล่นใกล้เคียง (แทนระบบ G/MJ-Alert-Doctor เดิม)
local function CallForHelp()
    local now = GetGameTimer() / 1000
    if now - lastHelpRequest < Config.HelpCooldown then
        local remaining = math.ceil(Config.HelpCooldown - (now - lastHelpRequest))
        Notify('กรุณารอสักครู่ (' .. remaining .. ' วินาที)', 'error', 3000)
        return
    end
    lastHelpRequest = now
    -- ส่งแค่ trigger ให้ server (server ใช้พิกัดฝั่ง server เอง กัน spoof — ดู core/server.lua)
    TriggerServerEvent('MJ-ReSpwan:server:callHelp')
    Notify('ส่งสัญญาณขอความช่วยเหลือแล้ว', 'success', 3000)
end

-- thread รับ input แบบ "กดค้าง" (hold) ระหว่างตาย — ทำงานเฉพาะตอน isDead
-- ใช้ IsDisabledControl* เพราะตอนตายเกมปิด control ผู้เล่นอัตโนมัติ (IsControlJustPressed จะไม่ยิงเลย
-- = สาเหตุเดิมที่ G/H กดไม่ติด) — ตัวนี้อ่านปุ่มได้ไม่ว่า control จะถูกปิดหรือไม่
-- กดค้างครบ Config.HoldTime ปุ่มถึงทำงาน + ส่งสถานะ fill ให้ NUI (start/done/cancel) ให้แถบไล่เอง
Citizen.CreateThread(function()
    local HoldTime = Config.HoldTime or 600
    local order = { 'clearBody', 'respawn', 'leaveActivity', 'callHelp' }

    -- ปุ่มนี้ "พร้อมกด" ตอนนี้ไหม (ให้ตรงกับสถานะที่ส่งให้ NUI ใน SendButtonStates)
    local function canPress(id)
        if id == 'respawn' then return respawnReady end
        if id == 'leaveActivity' then return leaveActivityEnabled end
        if id == 'clearBody' then return clearBodyEnabled end
        if id == 'callHelp' then return callHelpEnabled end
        return true
    end

    local function fireAction(id)
        if id == 'clearBody' then ClearBody()
        elseif id == 'respawn' then RespawnAtHospital()
        elseif id == 'leaveActivity' then RespawnAtHospital()
        elseif id == 'callHelp' then CallForHelp()
        end
    end

    local held = nil        -- id ปุ่มที่กำลังกดค้าง
    local heldSince = 0
    local fired = false

    while true do
        if isDead then
            Citizen.Wait(0)

            if held then
                -- ยังกดค้าง + ปุ่มยังพร้อมอยู่ไหม
                if canPress(held) and IsDisabledControlPressed(0, btnKeys[held]) then
                    if not fired and (GetGameTimer() - heldSince) >= HoldTime then
                        fired = true
                        SendNUIMessage({ type = 'hold', id = held, state = 'done' })
                        fireAction(held)
                    end
                else
                    -- ปล่อยก่อนครบ (หรือปุ่มถูกปิด) -> ยกเลิก fill
                    SendNUIMessage({ type = 'hold', id = held, state = 'cancel' })
                    held = nil
                    fired = false
                end
            else
                -- ยังไม่กดค้าง -> หาปุ่มที่พร้อม + เพิ่งเริ่มกด
                for i = 1, #order do
                    local id = order[i]
                    if canPress(id) and IsDisabledControlJustPressed(0, btnKeys[id]) then
                        held = id
                        heldSince = GetGameTimer()
                        fired = false
                        SendNUIMessage({ type = 'hold', id = id, state = 'start', duration = HoldTime })
                        break
                    end
                end
            end
        else
            held = nil
            fired = false
            Citizen.Wait(200)
        end
    end
end)

-- export: activity เรียกเมื่อผู้เล่นออกจากกิจกรรม -> เกิดใหม่ที่ รพ. ทันที (ข้าม countdown)
exports('LeaveActivityRespawn', function()
    if not isDead then return end
    Citizen.CreateThread(RespawnAtHospital)
end)

-- export: เปิด/ปิดปุ่ม LEAVE ACTIVITY ในหน้าจอ (+คีย์) เผื่อ activity อยากให้ปุ่มในจอกดได้ (default ปิด)
exports('SetLeaveActivityButton', function(enabled)
    leaveActivityEnabled = enabled and true or false
    if isDead then SendButtonStates() end
end)

-- รับสัญญาณขอความช่วยเหลือ -> ปัก blip ชั่วคราว + แจ้งเตือน
RegisterNetEvent('MJ-ReSpwan:client:helpBlip')
AddEventHandler('MJ-ReSpwan:client:helpBlip', function(coords)
    if type(coords) ~= 'table' then return end
    Notify('มีคนต้องการความช่วยเหลือใกล้คุณ', 'warning', 5000)

    local blip = BlipAddForCoords(1664425300, coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
    SetBlipSprite(blip, joaat('blip_ambient_medic'), true)
    SetBlipScale(blip, 1.2)
    Citizen.InvokeNative(0x9CB1A1623062F402, blip, 'ต้องการความช่วยเหลือ') -- SetBlipName

    Citizen.SetTimeout(Config.HelpBlipTime, function()
        if blip and DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end)
end)

-- ระหว่างตายเกมปิด control อัตโนมัติ — เปิดคีย์ที่ระบบอื่นยังต้องใช้ตอนตายกลับ (chat/เมนู ฯลฯ)
-- (ปุ่มบนหน้าจอตายเองใช้ IsDisabledControl* อยู่แล้ว ไม่ต้องพึ่ง thread นี้)
-- iterate + เช็ค nil กัน native error กรณีชื่อคีย์ไม่มีในตาราง Keys (เดิม 'K'/'T'/'DELETE' เป็น nil
-- ทำให้ thread ตายกลางคันทุกเฟรม → คีย์ที่อยู่หลังมัน (H/Z/F6/X/ENTER) ไม่เคยถูกเปิด)
local enableWhileDead = { 'N', 'E', 'H', 'Z', 'F6', 'X', 'ENTER', 'DEL' }
Citizen.CreateThread(function()
    while true do
        if isDead then
            Citizen.Wait(0)
            for i = 1, #enableWhileDead do
                local h = Keys[enableWhileDead[i]]
                if h then EnableControlAction(0, h, true) end
            end
        else
            Citizen.Wait(500)
        end
    end
end)

RegisterNetEvent("vorp_core:respawnPlayer", function()
    DoScreenFadeOut(0)
    DisplayRadar(false)
    SetMinimapHideFow(false)
    CloseUi()
    EndDeathCam()
    isDead = false
    sentDeathLog = false
end)
AddEventHandler('playerSpawned', function()
    DoScreenFadeOut(0)
    DisplayRadar(false)
    SetMinimapHideFow(false)
    CloseUi()
    EndDeathCam()
    isDead = false
    sentDeathLog = false
end)

local function playAnimation(dict, anim, duration)
    local ped<const> = PlayerPedId()
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        repeat
            Wait(0)
        until HasAnimDictLoaded(dict)
    end
    SetCurrentPedWeapon(ped, GetHashKey('weapon_unarmed'), true)
    TaskPlayAnim(ped, dict, anim, 8.0, 8.0, -1, 1, 0, false, false, false) -- -1 = loop
    Wait(duration)
    ClearPedTasks(ped)
end

-- category มาจาก Config.Items[item].category ที่ server ส่งมา ('heal' = bandage_s/bandage_xl,
-- 'quick' = painkiller/stamina) — fallback เป็น 'heal' ถ้า item เก่าไม่มี category กำหนดไว้
-- (เดิมโค้ดนี้เรียก Progress() แค่โชว์ UI แถบ แล้วแยกไปเล่นท่าเองผ่าน playAnimation() ซึ่งเป็นแค่
-- TaskPlayAnim + Wait(duration) ตรงๆ ไม่มีจุดเช็คยกเลิกเลย — กด canCancel เท่าไหร่ก็ไม่มีผลกับท่าจริง
-- ย้ายมาส่ง animation เข้า Progress() ตรงๆ แทน ให้ progbar (lp_progbar) เป็นเจ้าของท่าเต็มๆ รวมกลไกยกเลิก
-- (Backspace) ที่มีอยู่แล้วในตัว — ยกเลิกได้แค่ท่า/UI เท่านั้น ไอเทม/เลือดเสียไปแล้วตั้งแต่กดใช้ (server
-- ทำงานทันทีไม่รอ client กลับมา ไม่เปลี่ยนพฤติกรรมส่วนนี้)
RegisterNetEvent("MJ-ReSpwan:Client:HealAnim", function(category, itemName)
    local animData = Config.Animations[category] or Config.Animations.heal
    -- ใช้ lp_progbar แทน MJ-Progressbar — lp_progbar เป็นเจ้าของท่า/prop/ยกเลิกเต็มๆ เหมือนเดิม
    -- lp_progbar ไม่มีฟีเจอร์โชว์ไอคอนไอเทม เลยตัด icon/name ออก (พฤติกรรมอื่นคงเดิมทุกอย่าง:
    -- duration/label/canCancel/controlDisables(disableSprint)/animation/prop(boneName) — lp_progbar
    -- ถูกเสริมให้รองรับ disableSprint + prop.boneName แล้ว)
    -- pcall กัน crash กรณี lp_progbar ยังไม่ขึ้น — เลือด/ไอเทมถูกจัดการฝั่ง server ไปแล้ว ท่า/แถบพลาดได้ไม่พัง
    pcall(function()
        exports.lp_progbar:Progress({
            duration = animData.duration,
            label = 'Heal',
            useWhileDead = false,
            canCancel = animData.canCancel,
            controlDisables = animData.controlDisables or {},
            animation = { animDict = animData.dict, anim = animData.anim, flags = animData.flags },
            prop = animData.prop, -- ผ้าพันแผล (heal) / ขวดยา (quick) — lp_progbar สร้าง/แปะ/ลบให้เอง
        })
    end)
end)

RegisterNetEvent("MJ-ReSpwan:Client:ReviveAnim", function()
    -- ใช้ lp_progbar แทน MJ-Progressbar (revive โชว์แค่แถบ ท่าเล่นแยกผ่าน playAnimation เดิม)
    -- ตัด icon/name ออก (lp_progbar ไม่มี icon) พฤติกรรมอื่นคงเดิม
    pcall(function()
        exports.lp_progbar:Progress({
            duration = 7000,
            label = 'Revive',
            useWhileDead = false,
            canCancel = false
        })
    end)
    playAnimation("mech_revive@unapproved", "revive", 7000)
end)

RegisterNetEvent('MJ-ReSpwan:revive:DeadRedM')
AddEventHandler('MJ-ReSpwan:revive:DeadRedM', function(A)
    if IsPedDeadOrDying(PlayerPedId()) then
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        if not isDead then
            return
        end
        Citizen.CreateThread(function()
            local formattedCoords = {
                x = round(coords.x, 1),
                y = round(coords.y, 1),
                z = round(coords.z, 1)
            }
            DoScreenFadeOut(3000)
            Wait(3000)
            CloseUi()
            EndDeathCam()
            TriggerServerEvent("vorp_core:PlayerRespawnInternal", true)
            FreezeEntityPosition(PlayerPedId(), false)
            isDead = false
            sentDeathLog = false
        end)
    end
end)

RegisterNetEvent('MJ-ReSpwan:client:adminRevive', function()
    local pos = GetEntityCoords(PlayerPedId(), true)
    if not isDead then
        return
    end
    if not isAdmin() then
        return
    end

    DoScreenFadeOut(500)

    Wait(1000)

    NetworkResurrectLocalPlayer(pos.x, pos.y, pos.z, GetEntityHeading(PlayerPedId()), true, false)
    SetEntityInvincible(PlayerPedId(), false)
    ClearPedBloodDamage(PlayerPedId())
    SetAttributeCoreValue(PlayerPedId(), 0, 100) -- SetAttributeCoreValue
    SetAttributeCoreValue(PlayerPedId(), 1, 100) -- SetAttributeCoreValue
    Wait(1500)

    DoScreenFadeIn(1800)
    CloseUi()
    EndDeathCam()
    isDead = false
    sentDeathLog = false
    TriggerServerEvent("vorp:ImDead", false)
    LocalPlayer.state:set('isDead', false, true)
    TriggerServerEvent("mj:discordReviveLog", "ถูกแอดมินชุบชีวิต") -- เพิ่มบรรทัดนี้
end)

RegisterNetEvent("MJ-ReSpwan:Client:HealPlayer", function(health, stamina)
    if health and health > 0 then
        -- 2 รอบก่อนพัง (เดาสูตรเองผิดทั้งคู่) — รอบนี้ copy pattern จาก vorp_medic:Client:HealPlayer
        -- (client/main.lua:388-401) ตรงๆ แทน — ระบบหมอที่ proven ใช้งานได้จริงในโปรเจกต์นี้ และ
        -- MJ-Respwan ตั้งใจ derive มาจากมันตั้งแต่ต้น (โครงสร้าง/ชื่อตัวแปรเหมือนกันเป๊ะ)
        --
        -- จุดต่างจาก MJ-Respwan เดิม (บั๊กตั้งแต่แรกก่อนผมแตะ): vorp_medic บวก "+ 100" เข้ากับ
        -- GetPlayerHealth ก่อนใช้งาน (outer buffer เหนือ core ที่เต็มอยู่แล้วตอน inner>99) —
        -- MJ-Respwan เดิมขาดตัวนี้ไป ทำให้ outer ที่คำนวณผิด scale
        local inner = GetAttributeCoreValue(PlayerPedId(), 0)
        local outter = math.floor(GetPlayerHealth(PlayerId())) + 100

        if inner > 99 then
            local newHealth = outter + health
            SetEntityHealth(PlayerPedId(), newHealth, 0)
        else
            local newHealth = inner + health
            SetAttributeCoreValue(PlayerPedId(), 0, newHealth)
        end
    end

    if stamina and stamina > 0 then
        -- config.stamina = "เปอร์เซ็นต์ของหลอด" (100 = เต็ม, 50 = ครึ่งหลอด)
        --
        -- เดิมคำนวณ outer + stamina แล้วส่งเข้า ChangePedStamina ซึ่งรับ "delta" (เพิ่มเท่าไหร่)
        -- ไม่ใช่ค่าเป้าหมาย — บวก outer เข้าไปด้วยเลยปนหน่วย และค่าที่ส่งใหญ่เกินโดน
        -- scale/clamp ภายในจน stamina=100 คืนได้แค่ ~ครึ่งหลอด ต้องกินยา 2 ครั้งถึงเต็ม
        --
        -- RestorePlayerStamina รับ "percent 0.0-1.0" ตรงๆ ไม่ต้องอ่านค่าปัจจุบัน ไม่ปนหน่วย
        -- (native เดียวกับที่ MJ-Admin:1048 ใช้ RestorePlayerStamina(PlayerId(), 1.0) = เต็ม)
        RestorePlayerStamina(PlayerId(), math.min(stamina, 100) / 100.0)
    end
end)

function isAdmin(callback)
    TriggerServerEvent("mj:checkAdminPermission")
    RegisterNetEvent("mj:returnAdminPermission")
    AddEventHandler("mj:returnAdminPermission", function(isAdmin)
        callback(isAdmin)
    end)
end

function StartAutoRespawn()
    respawnReady = false -- reset ทุกครั้งที่เริ่มตายใหม่ (ปุ่ม RESPAWN เริ่มต้น disabled)
    SendButtonStates()   -- ส่งสถานะปุ่มเริ่มต้นให้ NUI

    local autoSpawnTimer = round(Config.SpawnTime / 1000)
    if checkHasVIPItem() then
        autoSpawnTimer = round(Config.VipSpawnTime / 1000)
    end

    Citizen.CreateThread(function()
        -- ส่งค่าเริ่มต้นก่อนนับถอยหลัง (JS จัดรูปเป็น MM:SS เอง)
        local minutes, secs = secondsToClock(autoSpawnTimer)
        SendNUIMessage({ type = 'respawn', minutes = minutes, seconds = secs })

        while autoSpawnTimer > 0 and isDead do
            Citizen.Wait(1000)
            autoSpawnTimer = autoSpawnTimer - 1
            local m, s = secondsToClock(math.max(autoSpawnTimer, 0))
            SendNUIMessage({ type = 'respawn', minutes = m, seconds = s })
        end

        -- countdown ถึง 0 -> เปิดปุ่ม RESPAWN AT HOSPITAL [E] (การกด E จัดการใน input thread ด้านบน)
        if isDead then
            SendNUIMessage({ type = 'respawn', minutes = 0, seconds = 0 })
            respawnReady = true
            SendButtonStates()
        end
    end)
end


-- DEATH HANDLER (sentDeathLog ประกาศไว้บนสุดของไฟล์แล้ว ดู scope note ตรง local isDead)

CreateThread(function()
    repeat Wait(1000) until LocalPlayer.state.IsInSession

    while true do
        local sleep = 500

        if IsPlayerDead(PlayerId()) then
            if not sentDeathLog then
                sentDeathLog = true

                NetworkSetInSpectatorMode(false, PlayerPedId())
                exports.spawnmanager.setAutoSpawn(false)
                TriggerServerEvent("vorp:ImDead", true)

                local getKillerPed = GetPedSourceOfDeath(PlayerPedId())
                local killerServerId = 0
                if IsPedAPlayer(getKillerPed) then
                    local killer = NetworkGetPlayerIndexFromPed(getKillerPed)
                    if killer then
                        killerServerId = GetPlayerServerId(killer)
                    end
                end

                local deathCause = GetPedCauseOfDeath(PlayerPedId())
                takeScreenshotAndSend(Config.DISCORD_WEBHOOK)
                print(('[MJ-Respwan] DEATH HANDLER fired: killerServerId=%s deathCause=%s -> firing vorp_core:Server:OnPlayerDeath'):format(tostring(killerServerId), tostring(deathCause)))
                TriggerServerEvent("vorp_core:Server:OnPlayerDeath", killerServerId, deathCause)
                TriggerEvent("vorp_core:Client:OnPlayerDeath", killerServerId, deathCause)
                TriggerEvent("vorp_inventory:CloseInv")
                DisplayRadar(false)

                if not isDead then
                    isDead = true
                    local my_id = GetPlayerServerId(PlayerId())
                    SendNUIMessage({ type = 'ui', status = true, id = my_id })
                    -- สถานะปุ่มจัดการใน StartAutoRespawn (respawnReady เริ่มต้น false)
                    CreateThread(StartDeathCam)
                    CreateThread(StartAutoRespawn)
                end
            end
        elseif isDead then
            isDead = false
            sentDeathLog = false
            CloseUi()
            CreateThread(EndDeathCam)
        end

        Wait(sleep)
    end
end)

function takeScreenshotAndSend(webhook)
    -- RenderScriptCams(false, false, 0, true, true)
    -- DestroyAllCams(true)
    -- ClearTimecycleModifier()
    -- SetTimecycleModifier("default")
    -- AnimpostfxStopAll()
    -- DisplayRadar(false)
    -- DisplayHud(false)
    -- SetNuiFocus(false, false)

    Wait(500) -- ให้ภาพ update

    -- screenshot-basic ไม่ได้ถูกติดตั้งในเซิร์ฟเวอร์นี้ (เช็คแล้วไม่มี resource นี้อยู่เลย)
    -- กัน SCRIPT ERROR "No such export" ทุกครั้งที่ตาย — ถ้าไม่มี resource ให้ส่ง log ไป Discord
    -- ต่อโดยไม่มีภาพแนบแทน ดีกว่าให้ทั้ง death log ใช้งานไม่ได้เลย
    if GetResourceState('screenshot-basic') ~= 'started' then
        local coords = GetEntityCoords(PlayerPedId())
        local deathCause = GetPedCauseOfDeath(PlayerPedId())
        local killerId = GetKillerServerId()
        TriggerServerEvent("mj:discordDeathLog", coords, deathCause, killerId, nil)
        return
    end

    -- ถ่ายภาพ
    exports['screenshot-basic']:requestScreenshotUpload(webhook, "files[]", function(data)
        local image = json.decode(data)
        if image and image.attachments and image.attachments[1] then
            local imageurl = image.attachments[1].url

            -- ส่งไป Discord หรือเซิร์ฟเวอร์
            local coords = GetEntityCoords(PlayerPedId())
            local deathCause = GetPedCauseOfDeath(PlayerPedId())
            local killerId = GetKillerServerId()
            TriggerServerEvent("mj:discordDeathLog", coords, deathCause, killerId, imageurl)
        else
            print("❌ Failed to upload screenshot")
        end
    end)

    Wait(1000)

    -- เปิด HUD กลับ
    -- DisplayRadar(true)
    -- DisplayHud(true)
end

function GetKillerServerId()
    local getKillerPed = GetPedSourceOfDeath(PlayerPedId())
    if IsPedAPlayer(getKillerPed) then
        local killer = NetworkGetPlayerIndexFromPed(getKillerPed)
        if killer then
            return GetPlayerServerId(killer)
        end
    end
    return 0
end

RegisterNetEvent("mj:deathScreenshot")
AddEventHandler("mj:deathScreenshot", function(webhook, reasonText)
    -- ปิดกล้อง/เอฟเฟกต์
    RenderScriptCams(false, false, 0, true, true)
    DestroyAllCams(true)
    ClearTimecycleModifier()
    SetTimecycleModifier("default")
    AnimpostfxStopAll()
    DisplayRadar(false)
    DisplayHud(false)
    TriggerEvent("nx_hud:client:hide")
    SetNuiFocus(false, false)

    Wait(500) -- ให้ภาพ update

    -- screenshot-basic ไม่ได้ติดตั้งในเซิร์ฟเวอร์นี้ — กัน SCRIPT ERROR แล้วคืนค่า HUD/กล้องกลับ
    -- ไม่ส่ง embed ภาพฟื้นคืนชีพ (ไม่มีภาพให้แนบอยู่ดี) แต่ยังคงคืนสถานะจอกลับให้ผู้เล่นตามปกติ
    if GetResourceState('screenshot-basic') ~= 'started' then
        DisplayRadar(true)
        DisplayHud(true)
        TriggerEvent("nx_hud:client:show")
        return
    end

    exports['screenshot-basic']:requestScreenshotUpload(webhook, "files[]", function(data)
        local image = json.decode(data)
        if image and image.attachments and image.attachments[1] then
            local imageurl = image.attachments[1].url

            -- ส่งข้อมูลกลับไปที่เซิร์ฟเวอร์เพื่อจัดการ embed
            TriggerServerEvent("mj:handleScreenshotWithReason", imageurl, reasonText)
        else
            print("❌ Screenshot failed")
        end
    end)

    Wait(1000)
    DisplayRadar(true)
    DisplayHud(true)
    TriggerEvent("nx_hud:client:show")
end)


function checkHasVIPItem()
    -- pcall + guard type กัน crash ทั้ง thread StartAutoRespawn กรณี inventory ยังไม่พร้อม/คืน nil
    local ok, inventory = pcall(function() return exports.vorp_inventory:getInventoryItems() end)
    if not ok or type(inventory) ~= 'table' then return false end
    for i = 1, #inventory do
        local item = inventory[i]
        for j = 1, #Config.VIP do
            if Config.VIP[j] == item.name and item.count > 0 then
                return true -- ถ้าพบไอเท็ม VIP และมีจำนวนมากกว่า 0
            end
        end
    end
    return false -- ถ้าไม่มีไอเท็ม VIP
end

function secondsToClock(seconds)
    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60
    return minutes, secs
end

CloseUi = function() -- ปิด Ui
    respawnReady = false
    SendNUIMessage({
        type = 'ui',
        status = false
    })
end

local function log(msg)
    if Config.Debug then
        print("[MJ-ReSpawn] " .. msg)
    end
end
