-- Medium: local ทุกตัวแปร global เดิม
local VORPcore = exports.vorp_core:GetCore()
local isAFKActive = false
local isAFKTransitioning = false
local afkProgress = {}
local currentZone = nil
local blips = {}
local afkPromptShown = false

local function sendAllZoneProgress()
    -- Medium: skip ถ้าไม่อยู่ใน zone
    if not currentZone then return end
    local progressData = {}
    for zoneName, data in pairs(Config.AFKZones) do
        progressData[#progressData + 1] = {
            name     = zoneName,
            label    = data.label,
            time     = afkProgress[zoneName] or 0,
            required = data.duration
        }
    end
    SendNUIMessage({ action = "updateProgressAll", zones = progressData })
end

-- ── ลุกขึ้น: เล่นแอนิเมชั่นลุกแบบ blend ออก คุมด้วย prog bar ที่กดยกเลิกไม่ได้ กันขยับ/สั่งงานซ้อนระหว่างยืน ──
local function exitAfk()
    ClearPedTasks(PlayerPedId())
    exports.lp_progbar:Progress({
        duration = 9*1000,
        label = 'กำลังลุกขึ้น...',
        canCancel = false,
        controlDisables = { disableMovement = true, disableCombat = true },
    }, function()
        isAFKActive = false
        SendNUIMessage({ action = "hideAFK" })
        afkPromptShown = false
    end)
end

-- ── เริ่มพักผ่อน: ค้าง G แล้วเล่นแอนิเมชั่นนอนลงก่อน คุมด้วย prog bar เดียวกัน กันขยับ/UI AFK โผล่ก่อนนอนเสร็จ ──
local function beginAfk()
    isAFKTransitioning = true
    TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_SLEEP_GROUND_ARM", 0, true)
    -- High: แจ้ง server เพื่อ track start time
    TriggerServerEvent("MJ-Afk-Zone-ui:startAFK", currentZone)
    exports.lp_progbar:Progress({
        duration = 9*1000,
        label = 'กำลังนอนลง...',
        canCancel = false,
        controlDisables = { disableMovement = true, disableCombat = true },
    }, function()
        isAFKTransitioning = false
        isAFKActive = true
        SendNUIMessage({
            action      = "startAFKMode",
            afkIconPath = Config.UI.afkIcon
        })
        -- ค้าง X 1.5 วิเพื่อออกจากโหมดพักผ่อน
        exports.lp_textui:TextUIHold('[X] ออกจากการพักผ่อน', 800, exitAfk, Config.Keys.cancelAFK)
    end)
end

-- ── Thread 2: ตรวจจับกด X ระหว่าง transition (ตอน active ใช้ lp_textui:TextUIHold คุมเองแล้ว) ──
Citizen.CreateThread(function()
    while true do
        -- High: Wait(500) เมื่อไม่ transitioning
        if not isAFKTransitioning then
            Citizen.Wait(500)
        else
            Citizen.Wait(5)
            if IsControlJustPressed(0, Config.Keys.cancelAFK) then
                exports.pNotify:SendNotification({ type = 'info', text = 'Please wait...', timeout = 2000 })
            end
        end
    end
end)

-- ── Thread 3: ตรวจสอบการเข้าโซน (Wait(1000)) ──────────────────────────────
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local playerPed    = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local foundZone    = false

        for zoneName, data in pairs(Config.AFKZones) do
            if #(playerCoords - data.coords) <= data.radius then
                foundZone = true
                if currentZone ~= zoneName then
                    currentZone = zoneName
                    if not afkProgress[zoneName] then
                        afkProgress[zoneName] = 0
                    end
                    afkPromptShown = false
                end

                if not afkPromptShown and not isAFKActive then
                    exports.lp_textui:TextUIHold('[G] เริ่มพักผ่อน', 800, beginAfk, Config.Keys.startAFK)
                    afkPromptShown = true
                end

                if isAFKActive then
                    afkProgress[zoneName] = (afkProgress[zoneName] or 0) + 1
                end

                if afkProgress[zoneName] >= data.duration then
                    TriggerServerEvent("MJ-Afk-Zone-ui:claimReward", zoneName)
                    exports.pNotify:SendNotification({ type = 'success', text = data.label .. ' - Time complete! Reward claimed.', timeout = 5000 })
                    afkProgress[zoneName] = 0
                end
                break
            end
        end

        -- ยิง cleanup แค่ตอน "เพิ่งออกจากโซน" ครั้งเดียว (currentZone ยังไม่ nil) —
        -- เดิมเรียก CancelHold/HideUI ทุก 1 วิแบบไม่มี guard ทำให้ล้าง textui ของทุกรีซอร์ส (Lumberjack/Mining/ฯลฯ) ทิ้งตลอดเวลา
        if not foundZone and currentZone ~= nil then
            currentZone = nil
            afkPromptShown = false
            if isAFKActive then
                exitAfk()
            end
            -- เดินออกโซนกลางที่ค้าง G (ยังไม่ active) หรือค้าง X (active) อยู่ก็ตาม ยกเลิก hold prompt ทิ้งด้วย
            exports.lp_textui:CancelHold()
            exports.lp_textui:HideUI()
            SendNUIMessage({ action = "hideAFK" })
        end

        sendAllZoneProgress()
    end
end)

-- ── Thread 4: Sync เวลา ────────────────────────────────────────────────────
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000)
        if currentZone and afkProgress[currentZone] then
            TriggerServerEvent("MJ-Afk-Zone-ui:updateTime", currentZone, afkProgress[currentZone])
        end
    end
end)

-- ── NUI / Net callbacks ────────────────────────────────────────────────────
RegisterNUICallback('closeNUI', function(_, cb)
    SetNuiFocus(false, false)
    cb({})
end)

RegisterNetEvent("MJ-Afk-Zone-ui:loadAFKTimes")
AddEventHandler("MJ-Afk-Zone-ui:loadAFKTimes", function(times)
    afkProgress = times or {}
end)

RegisterNetEvent("vorp:SelectedCharacter")
AddEventHandler("vorp:SelectedCharacter", function()
    Wait(1000)
    TriggerServerEvent("MJ-Afk-Zone-ui:requestAFKTimes")
end)

-- ── Blip ───────────────────────────────────────────────────────────────────
Citizen.CreateThread(function()
    Wait(1000)
    for zoneName, data in pairs(Config.AFKZones) do
        local blip = N_0x554d9d53f696d002(1664425300, data.coords.x, data.coords.y, data.coords.z)
        SetBlipSprite(blip, -211556852, 1)
        SetBlipScale(blip, 0.5)
        Citizen.InvokeNative(0x9CB1A1623062F402, blip, 'AFK Zone')
        blips[zoneName] = blip
    end
end)

-- ── Cleanup ────────────────────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        exports.lp_textui:CancelHold()
        exports.lp_textui:HideUI()
        SendNUIMessage({ action = "hideAFK" })
        SetNuiFocus(false, false)
        for _, blip in pairs(blips) do
            RemoveBlip(blip)
        end
    end
end)
