-- server/sv_main.lua
-- nx_event — Timed Treasure Hunt Event
-- State management | Scheduler | Callbacks | Rewards | Exports

local Core = exports.vorp_core:GetCore()
local Inv  = exports.nx_inventory

-- ─── City cache ─────────────────────────────────────────────────────────────
local cities = {}

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    Wait(800) -- ensure nx_cityselect is fully started
    cities = exports['nx_cityselect']:GetAllCities()
    print(string.format("[nx_event] Loaded %d cities from nx_cityselect", #cities))
    ResetEvent()
end)

-- ─── Event state ────────────────────────────────────────────────────────────
local Event = {
    active    = false,
    endAt     = 0,      -- GetGameTimer() ms when event ends
    boxes     = {},     -- [idx] = { pos={x,y,z}, collected=false }
    parts     = {},     -- [source] = { cityId, boxes=0, isDead=false }
    cityCount = {},     -- [cityId] = number of participants
    cityBoxes = {},     -- [cityId] = boxes collected by city
}

function ResetEvent()
    Event.active    = false
    Event.endAt     = 0
    Event.boxes     = {}
    Event.parts     = {}
    Event.cityCount = {}
    Event.cityBoxes = {}
    for _, c in ipairs(cities) do
        Event.cityCount[c.id] = 0
        Event.cityBoxes[c.id] = 0
    end
end

-- ─── Build snapshot for HUD ─────────────────────────────────────────────────
local function BuildSnapshot()
    local snap = {}
    for _, c in ipairs(cities) do
        snap[#snap + 1] = {
            id       = c.id,
            label    = c.label,
            color    = c.color,
            count    = Event.cityCount[c.id]  or 0,
            boxes    = Event.cityBoxes[c.id]  or 0,
            maxCount = Config.MaxPlayersPerCity,
        }
    end
    return snap
end

-- ─── Fisher-Yates shuffle + pick box positions ──────────────────────────────
local function PickBoxPositions()
    local pool = {}
    for _, p in ipairs(Config.BoxPositions) do
        pool[#pool + 1] = { x = p.x, y = p.y, z = p.z }
    end
    for i = #pool, 2, -1 do
        local j = math.random(1, i)
        pool[i], pool[j] = pool[j], pool[i]
    end
    local result = {}
    for i = 1, math.min(Config.TotalBoxes, #pool) do
        result[i] = { pos = pool[i], collected = false }
    end
    return result
end

-- ─── Check if all boxes are collected ───────────────────────────────────────
local function AllBoxesCollected()
    for _, b in ipairs(Event.boxes) do
        if not b.collected then return false end
    end
    return true
end

-- ─── End event ──────────────────────────────────────────────────────────────
local function EndEvent(reason)
    if not Event.active then return end
    Event.active = false

    print(string.format("[nx_event] Ending event. Reason: %s", reason or "unknown"))

    -- ─── Distribute rewards ──────────────────────────────────────────────
    for _, c in ipairs(cities) do
        local boxes = Event.cityBoxes[c.id] or 0
        if boxes > 0 then
            for src, data in pairs(Event.parts) do
                if data.cityId == c.id then
                    for _, reward in ipairs(Config.RewardItems) do
                        local total = reward.amount * boxes
                        pcall(function()
                            Inv:addItem(src, reward.item, total)
                        end)
                        print(string.format(
                            "[nx_event] Rewarded player %d: %dx%s (city=%s, boxes=%d)",
                            src, total, reward.item, c.id, boxes
                        ))
                    end
                end
            end
        end
    end

    -- Build result payload
    local result = {}
    for _, c in ipairs(cities) do
        result[#result + 1] = {
            id    = c.id,
            label = c.label,
            color = c.color,
            boxes = Event.cityBoxes[c.id] or 0,
        }
    end

    TriggerClientEvent('nx_event:Client:EventEnd', -1, result)
    ResetEvent()
end

-- ─── Start event ────────────────────────────────────────────────────────────
local function StartEvent()
    if Event.active then return end

    -- Refresh city list if empty (edge case on first start)
    if #cities == 0 then
        cities = exports['nx_cityselect']:GetAllCities()
    end

    ResetEvent()
    Event.active = true
    Event.endAt  = GetGameTimer() + (Config.EventDuration * 1000)
    Event.boxes  = PickBoxPositions()

    -- Build box list for clients
    local boxData = {}
    for i, b in ipairs(Event.boxes) do
        boxData[i] = { idx = i, x = b.pos.x, y = b.pos.y, z = b.pos.z }
    end

    local zonePayload = {
        x = Config.EventZone.center.x,
        y = Config.EventZone.center.y,
        z = Config.EventZone.center.z,
        r = Config.EventZone.radius,
    }

    TriggerClientEvent('nx_event:Client:EventStart', -1, {
        duration = Config.EventDuration,
        boxes    = boxData,
        zone     = zonePayload,
        snapshot = BuildSnapshot(),
        total    = Config.TotalBoxes,
    })

    -- Global announcement via VORP tip
    TriggerClientEvent('vorp:TipRight', -1, Config.EventAnnouncement, 8000)

    print(string.format("[nx_event] Event started at %s. Boxes: %d", os.date("%H:%M:%S"), #Event.boxes))

    -- Auto-end fallback timer
    SetTimeout(Config.EventDuration * 1000, function()
        if Event.active then EndEvent("timeout") end
    end)
end

-- ─── Time scheduler ─────────────────────────────────────────────────────────
-- Aligns to the next full minute, then checks every 60 seconds
CreateThread(function()
    local sec = tonumber(os.date("%S"))
    if sec and sec > 0 then
        Wait((60 - sec) * 1000 + 500)
    end
    while true do
        if not Event.active then
            local t = os.date("%H:%M")
            for _, et in ipairs(Config.EventTimes) do
                if t == et then
                    StartEvent()
                    break
                end
            end
        end
        Wait(60000)
    end
end)

-- ─── VORP Callbacks ─────────────────────────────────────────────────────────

-- Player entered zone → try to join
Core.Callback.Register('nx_event:JoinEvent', function(source, cb)
    if not Event.active then
        cb({ ok = false, reason = 'no_event' })
        return
    end

    -- Already joined
    if Event.parts[source] then
        cb({ ok = true, alreadyJoined = true, snapshot = BuildSnapshot() })
        return
    end

    local cityId = exports['nx_cityselect']:GetPlayerCityId(source)
    if not cityId then
        cb({ ok = false, reason = 'no_city' })
        TriggerClientEvent('vorp:TipRight', source, "คุณยังไม่ได้เลือกเมือง ไม่สามารถเข้าร่วมกิจกรรมได้", 4000)
        return
    end

    local count = Event.cityCount[cityId] or 0
    if count >= Config.MaxPlayersPerCity then
        cb({ ok = false, reason = 'city_full' })
        TriggerClientEvent('vorp:TipRight', source, "เมืองของคุณมีผู้เข้าร่วมเต็มแล้ว (" .. Config.MaxPlayersPerCity .. "/" .. Config.MaxPlayersPerCity .. ")", 4000)
        return
    end

    Event.parts[source]     = { cityId = cityId, boxes = 0, isDead = false }
    Event.cityCount[cityId] = count + 1

    -- Broadcast updated HUD to all
    TriggerClientEvent('nx_event:Client:UpdateHUD', -1, BuildSnapshot())

    cb({ ok = true, cityId = cityId, snapshot = BuildSnapshot() })
    print(string.format("[nx_event] Player %d joined (city=%s, slot=%d/%d)", source, cityId, count + 1, Config.MaxPlayersPerCity))
end)

-- Player collects a box
Core.Callback.Register('nx_event:CollectBox', function(source, cb, boxIdx)
    if not Event.active then cb(false) return end

    local box  = Event.boxes[boxIdx]
    local data = Event.parts[source]

    if not box or box.collected  then cb(false) return end
    if not data or data.isDead   then cb(false) return end

    box.collected                       = true
    data.boxes                          = data.boxes + 1
    Event.cityBoxes[data.cityId]        = (Event.cityBoxes[data.cityId] or 0) + 1

    local snap = BuildSnapshot()
    TriggerClientEvent('nx_event:Client:BoxCollected', -1, {
        boxIdx   = boxIdx,
        snapshot = snap,
    })

    cb(true)
    print(string.format("[nx_event] Box %d collected by player %d (city=%s)", boxIdx, source, data.cityId))

    -- Check end condition
    if AllBoxesCollected() then
        SetTimeout(1500, function()
            if Event.active then EndEvent("all_collected") end
        end)
    end
end)

-- Player died inside event zone
Core.Callback.Register('nx_event:PlayerDied', function(source, cb)
    if Event.parts[source] then
        Event.parts[source].isDead = true
        cb(true)
    else
        cb(false)
    end
end)

-- Player was revived inside event zone
Core.Callback.Register('nx_event:PlayerRevived', function(source, cb)
    if Event.parts[source] then
        Event.parts[source].isDead = false
        cb(true)
    else
        cb(false)
    end
end)

-- Get current event state (for clients that connect/respawn mid-event)
Core.Callback.Register('nx_event:GetState', function(source, cb)
    if not Event.active then
        cb({ active = false })
        return
    end
    local remaining = math.max(0, math.floor((Event.endAt - GetGameTimer()) / 1000))
    local boxes     = {}
    for i, b in ipairs(Event.boxes) do
        if not b.collected then
            boxes[#boxes + 1] = { idx = i, x = b.pos.x, y = b.pos.y, z = b.pos.z }
        end
    end
    cb({
        active    = true,
        remaining = remaining,
        boxes     = boxes,
        total     = Config.TotalBoxes,
        zone      = {
            x = Config.EventZone.center.x,
            y = Config.EventZone.center.y,
            z = Config.EventZone.center.z,
            r = Config.EventZone.radius,
        },
        snapshot  = BuildSnapshot(),
    })
end)

-- ─── Player drop cleanup ─────────────────────────────────────────────────────
AddEventHandler('playerDropped', function()
    local src = source
    if Event.parts[src] then
        local cid = Event.parts[src].cityId
        Event.cityCount[cid] = math.max(0, (Event.cityCount[cid] or 1) - 1)
        Event.parts[src]     = nil
        TriggerClientEvent('nx_event:Client:UpdateHUD', -1, BuildSnapshot())
    end
end)

-- ─── Server exports ─────────────────────────────────────────────────────────
-- ใช้ใน MJ-Medic:
--   if exports['nx_event']:IsPlayerInEvent(source) then
--       -- ไม่เริ่ม death countdown
--   end

exports('IsPlayerInEvent', function(src)
    return Event.active and Event.parts[src] ~= nil
end)

exports('IsEventActive', function()
    return Event.active
end)

exports('GetEventSnapshot', function()
    if not Event.active then return nil end
    return BuildSnapshot()
end)

-- ─── Helper: ตรวจสอบว่า source มีสิทธิ์ admin ────────────────────────────────
local function IsAdmin(source)
    -- console always allowed
    if source == 0 then return true end
    local user = Core.getUser(source)
    if not user then return false end
    local char = user.getUsedCharacter
    if not char then return false end
    local group = char.group or "user"
    for _, g in ipairs(Config.AdminGroups) do
        if group == g then return true end
    end
    return false
end

local function AdminNotify(source, msg)
    if source == 0 then
        print("[nx_event] " .. msg)
    else
        TriggerClientEvent('vorp:TipRight', source, "[Event] " .. msg, 4000)
    end
end

-- ─── /eventstart — เริ่มกิจกรรมทันที ────────────────────────────────────────
RegisterCommand('eventstart', function(source)
    if not IsAdmin(source) then
        AdminNotify(source, "คุณไม่มีสิทธิ์ใช้คำสั่งนี้")
        return
    end
    if Event.active then
        AdminNotify(source, "มีกิจกรรมกำลังดำเนินอยู่แล้ว")
        return
    end
    StartEvent()
    AdminNotify(source, "เริ่มกิจกรรมแล้ว")
end, false)

-- ─── /eventstop — หยุดกิจกรรมก่อนเวลา ──────────────────────────────────────
RegisterCommand('eventstop', function(source)
    if not IsAdmin(source) then
        AdminNotify(source, "คุณไม่มีสิทธิ์ใช้คำสั่งนี้")
        return
    end
    if not Event.active then
        AdminNotify(source, "ไม่มีกิจกรรมที่กำลังดำเนินอยู่")
        return
    end
    EndEvent("admin_forced")
    AdminNotify(source, "หยุดกิจกรรมแล้ว")
end, false)

-- ─── /eventstatus — ดูสถานะกิจกรรม ──────────────────────────────────────────
RegisterCommand('eventstatus', function(source)
    if not IsAdmin(source) then
        AdminNotify(source, "คุณไม่มีสิทธิ์ใช้คำสั่งนี้")
        return
    end
    if not Event.active then
        AdminNotify(source, "ไม่มีกิจกรรมที่กำลังดำเนินอยู่")
        return
    end
    local rem   = math.max(0, math.floor((Event.endAt - GetGameTimer()) / 1000))
    local left  = 0
    for _, b in ipairs(Event.boxes) do if not b.collected then left = left + 1 end end
    local pCount = 0
    for _ in pairs(Event.parts) do pCount = pCount + 1 end
    local m = string.format("ACTIVE | เวลา: %d:%02d | ผู้เล่น: %d | กล่องเหลือ: %d/%d",
        math.floor(rem/60), rem%60, pCount, left, Config.TotalBoxes)
    AdminNotify(source, m)
end, false)
