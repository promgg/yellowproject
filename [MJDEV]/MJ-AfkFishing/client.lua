local VORPcore = exports.vorp_core:GetCore()

local isInFishingZone = false
local fishingActive   = false
local rod             = nil

local isAfk       = false
local miniPhase   = "idle"
local sessionId   = 0
local currentBarId = nil

local function getBaitCount()
    local item = exports["vorp_inventory"]:getInventoryItem(Config.BaitItem)
    if item and item.count then return item.count end
    return 0
end

-- เช็คว่ามีเบ็ดตกปลาติดตัวไหม (เหมือน Config.Axe ของ MJ-Lumberjack — เช็คว่ามี ไม่หัก ไม่ถูกหักออกตอนตกปลา)
local function hasFishingRod()
    local item = exports["vorp_inventory"]:getInventoryItem(Config.RodItem)
    return item ~= nil and item ~= false
end

local function showIdleHint()
    if not hasFishingRod() then
        exports.lp_textui:TextUI('ต้องมีเบ็ดตกปลาถึงจะตกปลาได้')
        return
    end
    exports.lp_textui:TextUI(('[E] เริ่มตกปลา | เหยื่อ: %d'):format(getBaitCount()))
end

-- แทน vorp:TipBottom (native tip เกม ไม่รองรับฟอนต์ไทย ขึ้นเป็นกล่องสี่เหลี่ยม) ด้วย pNotify (NUI จริง โชว์ไทยได้ปกติ)
local function notify(kind, text, duration)
    exports.pNotify:SendNotification({ type = kind, text = text, timeout = duration or 3000 })
end

local function isInAnyWaterZone(coords)
    for _, zoneType in pairs(Config.ZoneType) do
        local hash = Citizen.InvokeNative(0x43AD8FC02B429D33, coords.x, coords.y, coords.z, zoneType)
        if hash and hash ~= 0 then
            return true
        end
    end
    return false
end

-- _GET_MAP_ZONE_AT_COORDS ใช้ได้แค่ฝั่ง client เท่านั้น ต้องส่งผลลัพธ์นี้แนบไปกับ event ให้ server ใช้แทน
local function getZoneHashes(coords)
    local hashes = {}
    for _, zoneType in pairs(Config.ZoneType) do
        hashes[zoneType] = Citizen.InvokeNative(0x43AD8FC02B429D33, coords.x, coords.y, coords.z, zoneType)
    end
    return hashes
end

local function getAvailableRewards(coords)
    local zoneHashCache = {}
    local function zoneHashFor(zoneType)
        if zoneHashCache[zoneType] == nil then
            zoneHashCache[zoneType] = Citizen.InvokeNative(0x43AD8FC02B429D33, coords.x, coords.y, coords.z, zoneType)
        end
        return zoneHashCache[zoneType]
    end

    local function isRewardAvailable(reward)
        if not reward.zones then return true end
        for _, z in ipairs(reward.zones) do
            if zoneHashFor(z.type) == GetHashKey(z.name) then return true end
        end
        return false
    end

    local available = {}
    for _, r in ipairs(Config.FishingRewards) do
        if isRewardAvailable(r) then table.insert(available, r) end
    end
    return available
end

local function refreshAvailableItems()
    local coords = GetEntityCoords(PlayerPedId())
    local rewards = getAvailableRewards(coords)
    local items = {}
    for _, r in ipairs(rewards) do
        table.insert(items, { img = 'nui://vorp_inventory/html/img/items/' .. (r.icon or r.item) .. '.png', chance = r.chance, item = r.item })
    end
    exports.lp_rewardpanel:Show(items, 'โอกาสดร็อปปลาในโซน', 'Fish Drop Info')
    return items
end

local function startAnimation()
    local model = 'p_fishingpole02x'
    local hash  = GetHashKey(model)
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) do
        RequestModel(hash)
        Citizen.Wait(5)
        timeout = timeout + 1
        if timeout > 300 then break end
    end
    RequestAnimDict("amb_work@world_human_stand_fishing@male_b@idle_a")
    while not HasAnimDictLoaded("amb_work@world_human_stand_fishing@male_b@idle_a") do
        Citizen.Wait(500)
    end
    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local obj    = CreateObject(hash, coords.x, coords.y, coords.z, true, true, false)
    AttachEntityToEntity(obj, ped, GetEntityBoneIndexByName(ped, 'SKEL_R_Finger01'),
        0.066693169058965, 0.029717232570079, 0.031797010430637,
        54.339909924554, 59.471737653412, 177.65716989488,
        true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(model)
    rod = obj
    TaskPlayAnim(ped, "amb_work@world_human_stand_fishing@male_b@idle_a", "idle_b", 8.0, 1.0, -1, 11, 0, 0, 0, 0)
    FreezeEntityPosition(ped, true)
end

local function stopAll(silent)
    sessionId     = sessionId + 1
    local wasActive = fishingActive
    isAfk         = false
    miniPhase     = "idle"
    fishingActive = false
    if wasActive then
        local ped = PlayerPedId()
        ClearPedTasksImmediately(ped)
        FreezeEntityPosition(ped, false)
        if rod then DeleteObject(rod); rod = nil end
    end
    if currentBarId then
        exports.lp_progbar:CancelProgress(currentBarId)
        currentBarId = nil
    end
    pcall(function() exports.lp_minigame:Cancel() end)
    exports.lp_textui:HideUI()
    if not silent then notify('info', 'หยุดตกปลาแล้ว', 3000) end
end

local runFishingRound

-- เรียกได้ก็ต่อเมื่อผ่านมินิเกมสำเร็จเท่านั้น (runFishingRound คัดพลาดออกไปแล้วก่อนหน้านี้)
-- เลยส่ง isHit=true ให้ giveRewardMini เสมอ (เดิมส่งได้ทั้ง true/false — พลาดก็ยังได้รางวัลปกติ
-- ตอนนี้พลาด = ไม่ได้อะไรเลย ไม่มาถึงจุดนี้)
local function startCooldown(mySession)
    miniPhase = "cooldown"
    local advanced = false

    local function advance(cancelled)
        if advanced then return end
        advanced = true
        currentBarId = nil
        if sessionId ~= mySession then return end
        if cancelled or miniPhase ~= "cooldown" then return end

        local zoneHashes = getZoneHashes(GetEntityCoords(PlayerPedId()))
        TriggerServerEvent('fishing:giveRewardMini', true, zoneHashes)

        Citizen.Wait(500) -- กันแถบ progbar ที่กำลังเฟดหายไปชนกับ minigame รอบถัดไปที่โผล่ทันที
        if sessionId ~= mySession then return end
        runFishingRound(mySession)
    end

    currentBarId = exports.lp_progbar:Progress({
        duration = Config.MiniGameTime * 1000,
        label    = 'กำลังดึงปลาขึ้นฝั่ง...',
    }, function(cancelled)
        advance(cancelled)
    end)

    Citizen.CreateThread(function()
        Citizen.Wait(Config.MiniGameTime * 1000 + 500)
        if not advanced then advance(false) end
    end)

    Citizen.CreateThread(function()
        while miniPhase == "cooldown" and sessionId == mySession do
            Citizen.Wait(1000)
            if miniPhase ~= "cooldown" or sessionId ~= mySession then break end
            if getBaitCount() <= 0 then
                notify('warning', 'เหยื่อหมดแล้ว — หยุดตกปลา', 3000)
                stopAll(true)
                if isInFishingZone then showIdleHint() end
                break
            end
        end
    end)
end

runFishingRound = function(mySession)
    if sessionId ~= mySession then return end
    if getBaitCount() <= 0 then
        notify('warning', 'เหยื่อหมดแล้ว — หยุดตกปลา', 3000)
        stopAll(true)
        if isInFishingZone then showIdleHint() end
        return
    end
    miniPhase = "idle"
    Citizen.CreateThread(function()
        local ok, isHit = pcall(function() return exports.lp_minigame:Fishing() end)
        if sessionId ~= mySession then return end
        if not ok then
            stopAll(true)
            notify('error', 'ระบบมินิเกมตกปลาขัดข้อง กรุณาลองใหม่อีกครั้ง', 4000)
            if isInFishingZone then showIdleHint() end
            return
        end
        if not isHit then
            -- พลาดมินิเกม (หมดเวลา/กดไม่ตรงจังหวะ) — ปลาหลุด ออกจากรอบตกปลาทันที
            -- ไม่เข้า progress bar ดึงปลาขึ้นฝั่ง และไม่ได้รางวัล (ต่างจากเดิมที่ยังให้รางวัลปกติแม้พลาด)
            stopAll(true)
            notify('warning', 'พลาด! ปลาหลุดไปแล้ว', 3000)
            if isInFishingZone then showIdleHint() end
            return
        end
        startCooldown(mySession)
    end)
end

-- เช็คกับ server ก่อนเริ่ม: ถ้ามีปลาบางชนิดในโซนนี้เต็ม limit แล้ว บล็อกทันที (ไม่ต้องเริ่ม/รอจบรอบ)
local function canStartFishing()
    local zoneHashes = getZoneHashes(GetEntityCoords(PlayerPedId()))
    local ok = VORPcore.Callback.TriggerAwait('MJ-AfkFishing:canStart', zoneHashes)
    if not ok then
        notify('warning', 'กระเป๋าเต็ม — มีปลาบางชนิดเต็มแล้ว ตกต่อไม่ได้', 4000)
        return false
    end
    return true
end

local function startMini()
    if fishingActive then return end
    if not hasFishingRod() then notify('warning', 'ต้องมีเบ็ดตกปลาถึงจะตกปลาได้!', 3000); return end
    if getBaitCount() <= 0 then notify('warning', 'ไม่มีเหยื่อ!', 3000); return end
    if not canStartFishing() then return end
    fishingActive = true
    refreshAvailableItems()
    startAnimation()
    exports.lp_textui:HideUI()
    runFishingRound(sessionId)
end

local function startAfk()
    if fishingActive then return end
    if not hasFishingRod() then notify('warning', 'ต้องมีเบ็ดตกปลาถึงจะตกปลาได้!', 3000); return end
    if getBaitCount() <= 0 then notify('warning', 'ไม่มีเหยื่อ!', 3000); return end
    if not canStartFishing() then return end
    fishingActive = true
    isAfk         = true
    refreshAvailableItems()
    startAnimation()
    exports.lp_textui:HideUI()

    local mySession = sessionId

    local function afkCycle()
        if not isAfk or sessionId ~= mySession then return end
        currentBarId = exports.lp_progbar:Progress({
            duration = Config.FishingTime * 1000,
            label    = 'กำลังตกปลาแบบ AFK...',
        }, function(cancelled)
            if sessionId ~= mySession then return end
            currentBarId = nil
            if not cancelled and isAfk then
                local zoneHashes = getZoneHashes(GetEntityCoords(PlayerPedId()))
                TriggerServerEvent('fishing:giveReward', zoneHashes)
                afkCycle()
            end
        end)
    end
    afkCycle()

    Citizen.CreateThread(function()
        while isAfk do
            Citizen.Wait(1000)
            if not isAfk or sessionId ~= mySession then break end
            if getBaitCount() <= 0 then
                notify('warning', 'เหยื่อหมดแล้ว — หยุดตกปลา', 3000)
                stopAll(true)
                if isInFishingZone then showIdleHint() end
                break
            end
        end
    end)
end

RegisterNetEvent('fishing:rewardGiven')
AddEventHandler('fishing:rewardGiven', function(item)
    exports.lp_rewardpanel:Highlight(item)
end)

RegisterNetEvent('fishing:inventoryFull')
AddEventHandler('fishing:inventoryFull', function()
    notify('error', 'กระเป๋าเต็มแล้ว — หยุดตกปลา', 4000)
    stopAll(true)
    if isInFishingZone then showIdleHint() end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        if not fishingActive then
            local ped           = PlayerPedId()
            local pos           = GetEntityCoords(ped)
            local touchingWater = Citizen.InvokeNative(0xDDE5C125AC446723, ped)
            local inZone        = touchingWater and isInAnyWaterZone(pos)

            if inZone and not isInFishingZone then
                isInFishingZone = true
                refreshAvailableItems()
                showIdleHint()
            elseif not inZone and isInFishingZone then
                isInFishingZone = false
                stopAll(true)
                exports.lp_rewardpanel:Hide()
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        if isInFishingZone then
            Citizen.Wait(5)

            if IsControlJustPressed(0, Config.KEY_E) and not fishingActive then
                startMini()
            end

            if Config.EnableAFK and IsControlJustPressed(0, Config.KEY_G) and not fishingActive then
                startAfk()
            end

            if IsControlJustPressed(0, Config.KEY_X) and fishingActive then
                stopAll()
                showIdleHint()
            end
        else
            Citizen.Wait(500)
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    stopAll(true)
end)
