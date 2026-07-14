-- lp_herbs / client/main.lua
-- แสดงผล + ส่งคำขอเท่านั้น — client ไม่ตัดสินรางวัลเอง. สถาปัตยกรรมยกมาจาก MJ-Mining:
-- สร้างตำแหน่ง prop ครั้งเดียว (ชนิดตายตัวตาม index), stream spawn/despawn ตามระยะ, hold-E
-- (lp_textui) -> progbar (lp_progbar) -> ยิง propKey ให้ server แจกของ. server derive ชนิด
-- จาก propKey + config เอง (ดู server/main.lua) — client โกงชนิด/จำนวนไม่ได้.

local isInZone     = false
local isGathering  = false
local herbDefs     = {}   -- [i] = { town, zoneIdx, herbIdx, x, y, z, key, model, item, label }
local spawned      = {}   -- [key] = objHandle เฉพาะต้นที่สตรีมเข้ามาใกล้ตอนนี้
local usedUntil    = {}   -- [key] = GetGameTimer() หมด cooldown (UX ฝั่ง client; server ตัดสินจริง)
local currentKey   = nil
local currentProg  = nil
local blips        = {}

local function dbg(fmt, ...) if Config.Debug then print(('[lp_herbs:cl] ' .. fmt):format(...)) end end

-- ── zone helpers ──────────────────────────────────────────────────────────────
local function getCurrentZone(coords)
    for zi, zone in ipairs(Config.Zones) do
        if #(coords - zone.center) <= zone.radius then return zone, zi end
    end
    return nil
end

local function buildRewardItems(zone)
    local items = {}
    for _, h in ipairs(zone.herbs) do
        items[#items + 1] = {
            img    = 'nui://vorp_inventory/html/img/items/' .. h.item .. '.png',
            chance = 100, -- prop ต้นนึงให้ชนิดเดียวตายตัว จึงเป็น 100% ต่อต้น
            item   = h.item,
        }
    end
    return items
end

-- ── blips ─────────────────────────────────────────────────────────────────────
local function createBlips()
    for _, zone in ipairs(Config.Zones) do
        local b = zone.blip
        local blip = BlipAddForCoords(joaat('BLIP_STYLE_CHALLENGE_OBJECTIVE'), zone.center.x, zone.center.y, zone.center.z)
        if b then
            SetBlipSprite(blip, b.sprite, true)
            if b.color then BlipAddModifier(blip, b.color) end
            SetBlipName(blip, b.name or zone.name)
        end
        blips[#blips + 1] = blip
    end
end

-- ── สร้างรายการตำแหน่ง prop ทั้งหมด "ครั้งเดียว" ──
-- พิกัดคำนวณไว้แล้วใน config.lua (shared_script, deterministic ต่อ zone+herb — client/server
-- ได้พิกัดเดียวกันเป๊ะโดยไม่ต้อง sync เครือข่าย ดู comment ใน config.lua) ตรงนี้แค่ flatten
-- Config.Zones ให้เป็น list เดียวไว้ให้ loop stream spawn/despawn ใช้งานง่าย
local function buildHerbDefs()
    for zi, zone in ipairs(Config.Zones) do
        for hi, herb in ipairs(zone.herbs) do
            herbDefs[#herbDefs + 1] = {
                town = zone.town, zoneIdx = zi, herbIdx = hi,
                x = herb.coords.x, y = herb.coords.y, z = herb.coords.z,
                key = herb.key,
                model = herb.model, item = herb.item, label = herb.label,
            }
        end
    end
end

-- ── stream spawn/despawn (สร้างตอนใกล้ -> collision โหลด -> ตกพื้นถูก ไม่ลอย) ──
local function streamSpawn(def)
    local hash = GetHashKey(def.model)
    RequestModel(hash)
    local guard = 0
    while not HasModelLoaded(hash) and guard < 60 do Wait(50); guard = guard + 1 end
    if not HasModelLoaded(hash) then return end
    RequestCollisionAtCoord(def.x, def.y, def.z)
    local obj = CreateObject(hash, def.x, def.y, def.z, false, false, false)
    for _ = 1, 15 do
        if PlaceObjectOnGroundProperly(obj) then break end
        Wait(50)
    end
    FreezeEntityPosition(obj, true)
    SetModelAsNoLongerNeeded(hash)
    spawned[def.key] = obj
end

local function streamDespawn(key)
    local obj = spawned[key]
    if obj and DoesEntityExist(obj) then DeleteObject(obj) end
    spawned[key] = nil
end

-- คืน key ต้นใกล้สุดที่ยังไม่ติด cooldown ในรัศมี
local function getNearbyHerb(coords, radius)
    local now = GetGameTimer()
    local bestKey, bestDist
    for key, obj in pairs(spawned) do
        if DoesEntityExist(obj) and (not usedUntil[key] or now >= usedUntil[key]) then
            local d = #(coords - GetEntityCoords(obj))
            if d <= radius and (not bestDist or d < bestDist) then
                bestKey, bestDist = key, d
            end
        end
    end
    return bestKey
end

-- ── gather flow ────────────────────────────────────────────────────────────────
local function resetGatherState()
    isGathering = false
    FreezeEntityPosition(PlayerPedId(), false)
end

local suppressCancelNotify = false

-- lp_progbar onFinish: ทั้งกด X ยกเลิก และจบสำเร็จ มาลงที่นี่
local function onGatherFinished(cancelled)
    currentProg = nil
    resetGatherState()

    if cancelled then
        if not suppressCancelNotify then
            exports.pNotify:SendNotification({ type = 'info', text = 'ยกเลิกการเก็บ', timeout = 3000 })
        end
        suppressCancelNotify = false
        return
    end

    -- ส่งแค่ propKey — server derive ชนิด/เมืองจาก config + พิกัดจริงเอง (ไม่เชื่อ client)
    if currentKey then
        TriggerServerEvent('lp_herbs:sv:gather', currentKey)
        usedUntil[currentKey] = GetGameTimer() + (Config.Cooldown * 1000) -- ซ่อน marker ฝั่ง client (UX)
    end
end

-- ใช้ตอนบังคับตัด (ออกโซน/resource stop) — reset sync ทันที ไม่รอ async
local function stopGather(silent)
    if currentProg then
        suppressCancelNotify = true
        exports.lp_progbar:CancelProgress(currentProg)
        currentProg = nil
    end
    resetGatherState()
    if not silent then
        exports.pNotify:SendNotification({ type = 'info', text = 'ยกเลิกการเก็บ', timeout = 3000 })
    end
end

local function startGatherFromHold()
    if isGathering then return end
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)

    local key = getNearbyHerb(pos, Config.GatherRange)
    if not key then
        exports.pNotify:SendNotification({ type = 'info', text = 'ไม่มีสมุนไพรใกล้ๆ', timeout = 2000 })
        return
    end

    currentKey  = key
    isGathering = true

    ClearPedTasksImmediately(ped)
    FreezeEntityPosition(ped, true)
    local obj = spawned[key]
    if obj and DoesEntityExist(obj) then TaskTurnPedToFaceEntity(ped, obj, 500) end
    Wait(500)
    exports.lp_textui:HideUI()

    currentProg = exports.lp_progbar:Progress({
        duration = Config.GatherDuration * 1000,
        label = 'กำลังเก็บสมุนไพร...',
        controlDisables = { disableMovement = true },
        animation = Config.GatherAnim,
    }, onGatherFinished)
end

-- ── server responses ────────────────────────────────────────────────────────────
RegisterNetEvent('lp_herbs:cl:awarded', function(item)
    exports.lp_rewardpanel:Highlight(item)
end)

RegisterNetEvent('lp_herbs:cl:notify', function(kind, text, timeout)
    exports.pNotify:SendNotification({ type = kind or 'info', text = text or '', timeout = timeout or 3000 })
end)

-- ── streaming loop ───────────────────────────────────────────────────────────────
CreateThread(function()
    repeat Wait(1000) until LocalPlayer.state.IsInSession
    buildHerbDefs()

    local rIn2  = (Config.StreamRadius or 80.0) ^ 2
    local rOut2 = ((Config.StreamRadius or 80.0) + 15.0) ^ 2
    while true do
        local pos = GetEntityCoords(PlayerPedId())
        for _, def in ipairs(herbDefs) do
            local dx, dy = def.x - pos.x, def.y - pos.y
            local d2 = dx * dx + dy * dy
            if not spawned[def.key] then
                if d2 <= rIn2 then streamSpawn(def) end
            elseif d2 > rOut2 then
                streamDespawn(def.key)
            end
        end
        Wait(750)
    end
end)

-- ── marker draw (เฉพาะต้นใกล้ที่ยังเก็บได้) ──
CreateThread(function()
    repeat Wait(5000) until LocalPlayer.state.IsInSession
    while true do
        if isInZone and not isGathering then
            local pos = GetEntityCoords(PlayerPedId())
            local now = GetGameTimer()
            local drew = false
            for key, obj in pairs(spawned) do
                if DoesEntityExist(obj) and (not usedUntil[key] or now >= usedUntil[key]) then
                    local oc = GetEntityCoords(obj)
                    if #(pos - oc) <= 5.0 then
                        drew = true
                        Citizen.InvokeNative(0x2A32FAA57B937173, 0x94FDAE17,
                            oc.x, oc.y, oc.z, 0, 0, 0, 0, 0, 0,
                            1.0, 1.0, 1.0, 80, 200, 80, 150, 0, 0, 0, 2, 0, 0, 0, 0)
                    end
                end
            end
            Wait(drew and 0 or 500)
        else
            Wait(500)
        end
    end
end)

-- ── hold hint (กดค้าง E) ──
CreateThread(function()
    repeat Wait(5000) until LocalPlayer.state.IsInSession
    local shown = false
    while true do
        Wait(150)
        local inRange = false
        if isInZone and not isGathering then
            local pos = GetEntityCoords(PlayerPedId())
            inRange = getNearbyHerb(pos, shown and (Config.GatherRange + 0.3) or Config.GatherRange) ~= nil
        end
        if inRange and not shown then
            shown = true
            exports.lp_textui:TextUIHold('[E] เก็บสมุนไพร', Config.HoldMs, function()
                shown = false
                startGatherFromHold()
            end, Config.KEY_E)
        elseif (not inRange) and shown then
            shown = false
            exports.lp_textui:CancelHold()
        end
    end
end)

-- ── main loop: enter/exit zone -> reward panel ──
CreateThread(function()
    repeat Wait(5000) until LocalPlayer.state.IsInSession
    createBlips()
    while true do
        Wait(500)
        local pos    = GetEntityCoords(PlayerPedId())
        local zone   = getCurrentZone(pos)
        local inZone = zone ~= nil

        if inZone then
            if not isInZone then
                isInZone = true
                exports.lp_rewardpanel:Show(buildRewardItems(zone), 'สมุนไพรในโซนนี้', 'Herb Gathering')
            end
        else
            if isInZone then
                isInZone = false
                if isGathering then stopGather(true) end
                exports.lp_rewardpanel:Hide()
                exports.lp_textui:CancelHold()
                exports.lp_textui:HideUI()
            end
            Wait(1000)
        end
    end
end)

-- ── cleanup ──
AddEventHandler('onResourceStop', function(name)
    if GetCurrentResourceName() ~= name then return end
    if isGathering then stopGather(true) end
    exports.lp_rewardpanel:Hide()
    exports.lp_textui:CancelHold()
    exports.lp_textui:HideUI()
    for key, obj in pairs(spawned) do
        if DoesEntityExist(obj) then DeleteObject(obj) end
        spawned[key] = nil
    end
    for _, blip in ipairs(blips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
end)
