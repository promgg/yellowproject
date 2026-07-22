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
local helpRequested = false
-- วนตรวจจับการกดปุ่ม
local CoolDown = 60
local helpCooldown = 20 -- วินาที
local lastHelpRequest = 0

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

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isDead then
            if IsControlJustReleased(0, 0x760A9C6F) then -- กด G
                local currentTime = GetGameTimer() / 1000 -- เปลี่ยนเป็นวินาที
                if currentTime - lastHelpRequest >= helpCooldown then
                    SendNUIMessage({
                        type = 'addclass2',
                        status = true
                    })
                    helpRequested = true
                    lastHelpRequest = currentTime
                    TriggerEvent("!MJ-Alert-Doctor:alertNet", "dead")
                else
                    local remaining = math.ceil(helpCooldown - (currentTime - lastHelpRequest))
                    TriggerEvent('vorp:TipBottom',
                        'กรุณารอสักครู่ (' .. remaining .. ' วินาที)', 3000)
                end
            end

            -- ปิดแสดง UI ช่วยเหลือหลัง cooldown
            if helpRequested then
                local currentTime = GetGameTimer() / 1000
                if currentTime - lastHelpRequest >= helpCooldown then
                    SendNUIMessage({
                        type = 'addclass2',
                        status = false
                    })
                    helpRequested = false -- reset ให้กดซ้ำได้รอบหน้า
                end
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        if isDead then
            -- DisableAllControlActions(0)
            EnableControlAction(0, Keys['N'], true)
            EnableControlAction(0, Keys['E'], true)
            EnableControlAction(0, Keys['K'], true)
            EnableControlAction(0, Keys['T'], true)
            EnableControlAction(0, Keys['H'], true)
            EnableControlAction(0, Keys['Z'], true)
            EnableControlAction(0, Keys['F6'], true)
            EnableControlAction(0, Keys['X'], true)
            EnableControlAction(0, Keys['ENTER'], true)
            EnableControlAction(0, Keys['DELETE'], true)
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

RegisterNetEvent("MJ-ReSpwan:Client:ReviveAnim", function()
    -- ใช้ lp_progbar แทน MJ-Progressbar (revive โชว์แค่แถบ ท่าเล่นแยกผ่าน playAnimation เดิม)
    -- ตัด icon/name ออก (lp_progbar ไม่มี icon) พฤติกรรมอื่นคงเดิม
    exports.lp_progbar:Progress({
        duration = 7000,
        label = 'Revive',
        useWhileDead = false,
        canCancel = false
    })
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
        local inner = GetAttributeCoreValue(PlayerPedId(), 0)
        local outter = GetPlayerHealth(PlayerId())

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
    local autoSpawnTimer = round(Config.SpawnTime / 1000)
    local MaxRespawnTimer = round(Config.SpawnTime / 1000)

    if checkHasVIPItem() then
        autoSpawnTimer = round(Config.VipSpawnTime / 1000)
        MaxRespawnTimer = round(Config.VipSpawnTime / 1000)
    end

    Citizen.CreateThread(function()
        while autoSpawnTimer > 0 and isDead do
            Citizen.Wait(1000)
            autoSpawnTimer = autoSpawnTimer - 1
            local minutes, secs = secondsToClock(autoSpawnTimer)
            local nText = string.format('%02d:%02d', minutes, secs)
            SendNUIMessage({
                type = 'respawn',
                text = string.format("จะเกิดใหม่ใน %s", nText)
            })
        end
    end)

    Citizen.CreateThread(function()
        while isDead do
            Citizen.Wait(0)
            if autoSpawnTimer <= 0 then
                SendNUIMessage({
                    type = 'addclass',
                    status = false
                })

                if IsControlJustPressed(0, Keys["E"]) then
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
                    break
                else
                    SendNUIMessage({
                        type = 'addclass',
                        status = true
                    })
                end
            end
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
                    SendNUIMessage({ type = 'addclass', status = true })
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
    local inventory = exports.vorp_inventory:getInventoryItems()
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
    helpRequested = false
    SendNUIMessage({
        type = 'ui',
        status = false
    })
    SendNUIMessage({
        type = 'addclass2',
        status = false
    })
end

local function log(msg)
    if Config.Debug then
        print("[MJ-ReSpawn] " .. msg)
    end
end
