-- MJ-Afk-Zone-ui (client)
--
-- flow:
--   เดินเข้า saloon  -> lp_interior ย้ายมิติให้เอง (bucket ปกติของร้าน)
--   กด E ที่ NPC     -> lp_interior ย้ายไป afkBucket ของร้านเดียวกัน (กดซ้ำ = กลับเข้าร้าน)
--   ค้าง G           -> เริ่มนับเวลา AFK (ทำได้เฉพาะตอนอยู่ในมิติพักผ่อน)
--   เดินออกนอกร้าน   -> lp_interior ยิง onLeave -> ปิด UI + หยุดนับ อัตโนมัติ
--
-- ⚠️ resource นี้ "ไม่แตะ routing bucket เอง" เด็ดขาด — lp_interior เป็นเจ้าของคนเดียว
--    ถ้าสองรีซอร์สเรียก SetPlayerRoutingBucket ทั้งคู่ จะเขียนทับกันจนหลุดมิติมั่ว

local isAFKActive = false
local isAFKTransitioning = false
local afkProgress = {}
local currentZone = nil   -- ชื่อโซนใน Config.AFKZones ที่ยืนอยู่ (nil = ไม่ได้อยู่ใน saloon ที่รองรับ)
local blips = {}
local npcPeds = {}        -- [zoneName] = ped handle
local promptState = nil   -- ข้อความ prompt ที่โชว์อยู่ตอนนี้ (กันสั่งซ้ำทุกลูป)

-- ── สะพานไป lp_interior ──────────────────────────────────────────────────
-- ห่อไว้ทั้งหมด เผื่อ lp_interior ยังไม่ start (หรือถูกปิด) จะได้ไม่ error ทั้งไฟล์
local function interiorReady()
    return GetResourceState('lp_interior') == 'started'
end

local function currentInteriorZone()
    if not interiorReady() then return nil end
    local ok, zone = pcall(function() return exports.lp_interior:GetCurrentZone() end)
    return ok and zone or nil
end

local function inAfkDimension()
    if not interiorReady() then return false end
    local ok, res = pcall(function() return exports.lp_interior:IsInAfk() end)
    return ok and res == true
end

local function toggleAfkDimension()
    if not interiorReady() then return nil end
    local ok, res = pcall(function() return exports.lp_interior:ToggleAfk() end)
    return ok and res or nil
end

-- ── prompt ───────────────────────────────────────────────────────────────
local function clearPrompt()
    if not promptState then return end
    promptState = nil
    -- HideUI ครอบทั้ง prompt ธรรมดาและแบบกดค้าง — CancelHold เพียงอย่างเดียวไม่พอ
    -- (มัน early-return เมื่อไม่มี hold ค้างอยู่ ทำให้ข้อความธรรมดาไม่ถูกเก็บ)
    exports.lp_textui:HideUI()
end

local function showHold(key, message, holdMs, controlCode, callback)
    if promptState == key then return end
    clearPrompt()
    promptState = key
    exports.lp_textui:TextUIHold(message, holdMs, callback, controlCode)
end

-- ── NUI ──────────────────────────────────────────────────────────────────
local function sendAllZoneProgress()
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

    -- ส่ง currentZone ไปด้วย ให้ NUI รู้ว่ากำลังอยู่โซนไหนจริง (ก่อนหน้านี้ NUI เดาเอาจากโซน
    -- ที่มี time สะสมสูงสุด ทำให้เห็นเวลาโซนเก่าค้างไม่ขยับตอนเริ่ม AFK ที่โซนใหม่)
    SendNUIMessage({ action = "updateProgressAll", zones = progressData, currentZone = currentZone })
end

-- ── ออกจากโหมดพักผ่อน ────────────────────────────────────────────────────
-- instant = true -> ไม่เล่นแอนิเมชันลุก (ใช้ตอนโดนดึงออกเพราะเดินออกนอกร้าน/รีซอร์สหยุด)
local function exitAfk(instant)
    if not isAFKActive then return end

    -- หยุดนับเวลาทันที ไม่ใช่รอ callback ของ progbar เดิมตั้ง false ใน callback หลังแอนิเมชัน
    -- ยืนจบ (9 วิ) ทำให้ลูปนับเวลายังเห็น true แล้วบวกต่อไปอีก ~9 วิหลังกดออก
    isAFKActive = false
    ClearPedTasks(PlayerPedId())

    if instant then
        SendNUIMessage({ action = "hideAFK" })
        return
    end

    -- กันลูป prompt ไปโชว์ "[G] เริ่มพักผ่อน" ระหว่าง 9 วิที่ยังยืนไม่เสร็จ
    -- (isAFKActive เป็น false ไปแล้วตั้งแต่บรรทัดบน ลูปจึงคิดว่าพร้อมเริ่มใหม่)
    isAFKTransitioning = true
    clearPrompt()

    exports.lp_progbar:Progress({
        duration = 9 * 1000,
        label = 'กำลังลุกขึ้น...',
        canCancel = false,
        controlDisables = { disableMovement = true, disableCombat = true },
    }, function()
        isAFKTransitioning = false
        SendNUIMessage({ action = "hideAFK" })
    end)
end

-- ── เริ่มพักผ่อน ─────────────────────────────────────────────────────────
local function beginAfk()
    if isAFKActive or isAFKTransitioning then return end
    if not currentZone or not inAfkDimension() then return end

    isAFKTransitioning = true
    clearPrompt()

    TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_SLEEP_GROUND_ARM", 0, true)
    TriggerServerEvent("MJ-Afk-Zone-ui:startAFK", currentZone)

    exports.lp_progbar:Progress({
        duration = 9 * 1000,
        label = 'กำลังนอนลง...',
        canCancel = false,
        controlDisables = { disableMovement = true, disableCombat = true },
    }, function()
        isAFKTransitioning = false

        -- เผื่อเดินออกนอกร้าน/ถูกดึงออกมิติระหว่าง 9 วิที่ยังนอนไม่เสร็จ
        if not currentZone or not inAfkDimension() then
            SendNUIMessage({ action = "hideAFK" })
            return
        end

        isAFKActive = true
        SendNUIMessage({ action = "startAFKMode", afkIconPath = Config.UI.afkIcon })
    end)
end

-- ── NPC บาร์เทนเดอร์ ─────────────────────────────────────────────────────
local function spawnNpc(zoneName, data)
    if npcPeds[zoneName] and DoesEntityExist(npcPeds[zoneName]) then return end

    local hash = joaat(Config.NPC.model)
    RequestModel(hash)
    local timeout = GetGameTimer() + 3000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do Wait(0) end
    if not HasModelLoaded(hash) then
        print(('[MJ-Afk-Zone-ui] ^3เตือน:^7 โหลดโมเดล %s ไม่สำเร็จ — NPC ที่ %s จะไม่ขึ้น'):format(
            Config.NPC.model, zoneName))
        return
    end

    -- ลบ 1.0 เฉพาะตอนสร้าง: พิกัดใน config เก็บจากที่ผู้เล่น "ยืน" ซึ่งวัดที่กลางตัว
    -- ส่วน CreatePed วางเท้าที่ z ที่ให้ไป ไม่ลบจะได้ ped ลอยเหนือพื้นครึ่งตัว
    -- (pattern เดียวกับ lp_fasttravel/client/npc.lua) — การวัดระยะ prompt ยังใช้พิกัดเดิมที่ไม่ลบ
    local c = data.npc.coords
    local ped = CreatePed(hash, c.x, c.y, c.z - 1.0, data.npc.heading or 0.0, false, false, false, false)

    -- ⚠️ ขาดบรรทัดนี้ = ped โผล่มาล่องหน (โมเดลไม่มีชุดติดมา ต้องสุ่มให้เอง)
    Citizen.InvokeNative(0x283978A15512B2FE, ped, true) -- SetRandomOutfitVariation

    SetEntityCanBeDamaged(ped, false)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetModelAsNoLongerNeeded(hash)

    npcPeds[zoneName] = ped
end

local function removeNpc(zoneName)
    local ped = npcPeds[zoneName]
    npcPeds[zoneName] = nil
    if ped and DoesEntityExist(ped) then
        DeletePed(ped)
    end
end

Citizen.CreateThread(function()
    while true do
        local coords = GetEntityCoords(PlayerPedId())

        for zoneName, data in pairs(Config.AFKZones) do
            if data.npc then
                local dist = #(coords - data.npc.coords)
                if dist <= Config.NPC.spawnRange then
                    spawnNpc(zoneName, data)
                elseif dist > Config.NPC.despawnRange then
                    removeNpc(zoneName)
                end
            end
        end

        Citizen.Wait(1000)
    end
end)

-- ── ลูปหลัก: โซน + prompt ────────────────────────────────────────────────
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(250)

        local zone = currentInteriorZone()
        local zoneName = zone and Config.ZoneByInteriorKey[zone.key] or nil

        -- เปลี่ยนโซน (รวมกรณีออกนอกร้าน = nil) — เคลียร์ทุกอย่างของโซนเดิม
        if zoneName ~= currentZone then
            if isAFKActive then exitAfk(true) end
            clearPrompt()
            currentZone = zoneName
            if zoneName and not afkProgress[zoneName] then
                afkProgress[zoneName] = 0
            end
        end

        if currentZone and not isAFKTransitioning then
            local data = Config.AFKZones[currentZone]
            local ped = PlayerPedId()
            local nearNpc = data.npc and #(GetEntityCoords(ped) - data.npc.coords) <= Config.NPC.promptRange

            if isAFKActive then
                -- กำลังนอนอยู่ ปุ่มเดียวที่ควรเห็นคือปุ่มลุก
                showHold('exit', '[X] ออกจากการพักผ่อน', 800, Config.Keys.cancelAFK, function()
                    exitAfk(false)
                end)
            elseif nearNpc then
                -- ยืนที่ NPC — ข้อความเปลี่ยนตามว่าตอนนี้อยู่มิติไหน
                if inAfkDimension() then
                    showHold('npc_out', '[E] กลับเข้าร้าน', Config.NPC.holdMs, Config.Keys.npc, function()
                        toggleAfkDimension()
                        clearPrompt()
                    end)
                else
                    showHold('npc_in', '[E] เข้าห้องพักผ่อน', Config.NPC.holdMs, Config.Keys.npc, function()
                        toggleAfkDimension()
                        clearPrompt()
                    end)
                end
            elseif inAfkDimension() then
                showHold('start', '[G] เริ่มพักผ่อน', 800, Config.Keys.startAFK, beginAfk)
            else
                clearPrompt()
            end
        elseif not currentZone then
            clearPrompt()
        end

        sendAllZoneProgress()
    end
end)

-- ── ลูปนับเวลา (แยกออกมาให้เดินทีละ 1 วินาทีเป๊ะๆ) ──────────────────────
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)

        if isAFKActive and currentZone then
            local data = Config.AFKZones[currentZone]
            afkProgress[currentZone] = (afkProgress[currentZone] or 0) + 1

            if afkProgress[currentZone] >= data.duration then
                TriggerServerEvent("MJ-Afk-Zone-ui:claimReward", currentZone)
                afkProgress[currentZone] = 0
                -- ไม่ตั้ง isAFKActive = false — นอนต่อได้ รอบถัดไปนับใหม่เอง
                -- server เป็นคนตัดสินว่าจ่ายจริงไหม (เช็คเวลา + มิติ + ระยะซ้ำอีกที)
            end
        end
    end
end)

-- ── Sync เวลาไป server เป็นระยะ ──────────────────────────────────────────
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000)
        if currentZone and afkProgress[currentZone] then
            TriggerServerEvent("MJ-Afk-Zone-ui:updateTime", currentZone, afkProgress[currentZone])
        end
    end
end)

-- ── lp_interior แจ้งว่าออกจากอาคารแล้ว ───────────────────────────────────
-- ลูปหลักด้านบนจับได้อยู่แล้วภายใน 250ms แต่ตัวนี้ตัดทันทีไม่ต้องรอ
AddEventHandler('lp_interior:onLeave', function()
    if not currentZone then return end
    if isAFKActive then exitAfk(true) end
    clearPrompt()
    currentZone = nil
    SendNUIMessage({ action = "hideAFK" })
end)

-- ── Net callbacks ────────────────────────────────────────────────────────
RegisterNetEvent("MJ-Afk-Zone-ui:loadAFKTimes", function(times)
    afkProgress = times or {}
end)

RegisterNetEvent("MJ-Afk-Zone-ui:rewardGranted", function(label, text)
    exports.pNotify:SendNotification({ type = 'success', text = text, timeout = 5000 })
end)

RegisterNetEvent("vorp:SelectedCharacter", function()
    Wait(1000)
    TriggerServerEvent("MJ-Afk-Zone-ui:requestAFKTimes")
end)

-- ── Blip ─────────────────────────────────────────────────────────────────
Citizen.CreateThread(function()
    Wait(1000)
    for zoneName, data in pairs(Config.AFKZones) do
        if data.npc then
            local c = data.npc.coords
            local blip = N_0x554d9d53f696d002(1664425300, c.x, c.y, c.z)
            SetBlipSprite(blip, -211556852, 1)
            SetBlipScale(blip, 0.5)
            Citizen.InvokeNative(0x9CB1A1623062F402, blip, 'AFK Zone')
            blips[zoneName] = blip
        end
    end
end)

-- ── Cleanup ──────────────────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    clearPrompt()
    SendNUIMessage({ action = "hideAFK" })
    SetNuiFocus(false, false)

    for _, blip in pairs(blips) do
        RemoveBlip(blip)
    end
    for zoneName in pairs(npcPeds) do
        removeNpc(zoneName)
    end
end)
