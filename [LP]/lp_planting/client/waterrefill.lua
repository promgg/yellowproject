-- ═══════════════════════════════════════════════════════════════════════════
--  lp_planting — จุดเติมน้ำ
--
--  ต่างจาก MJ-Planting เดิมที่มีโซนละ 1 จุดตายตัว: ตรงนี้อ่านจาก
--  Config.Zones[*].waterPoints ซึ่งเป็นตาราง ใส่กี่จุดก็ได้ ไม่ต้องแก้โค้ด
--  (ผู้ว่าจ้างขอโซนละ 4 จุด — เพิ่มพิกัดใน config ได้เลย)
-- ═══════════════════════════════════════════════════════════════════════════

local VORPcore = {}
TriggerEvent('getCore', function(core) VORPcore = core end)

local props = {}   -- prop ปั๊มน้ำที่ spawn ไว้
local points = {}  -- { coords, heading, zoneLabel } รวมทุกโซน
local busy = false

local function rpc(name, ...)
    local done, result = false, nil
    VORPcore.RpcCall(name, function(r) result = r; done = true end, ...)
    local start = GetGameTimer()
    while not done do
        Wait(0)
        if GetGameTimer() - start > 10000 then return nil end
    end
    return result
end

-- รวมจุดเติมน้ำจากทุกโซนไว้ในลิสต์เดียว
CreateThread(function()
    for _, zone in pairs(Config.Zones) do
        for _, pt in ipairs(zone.waterPoints or {}) do
            points[#points + 1] = {
                coords = pt.coords,
                heading = pt.heading or 0.0,
                zoneLabel = zone.label,
            }
        end
    end

    if #points == 0 then
        print('^3[lp_planting]^7 ไม่มีจุดเติมน้ำใน config เลย — ผู้เล่นจะเติมน้ำไม่ได้')
        return
    end

    -- spawn prop ปั๊มน้ำ
    local model = GetHashKey(Config.WaterRefill.propModel)
    RequestModel(model)
    local start = GetGameTimer()
    while not HasModelLoaded(model) do
        Wait(50)
        if GetGameTimer() - start > 5000 then
            print(('^1[lp_planting]^7 โหลดโมเดลปั๊มน้ำไม่ได้: %s'):format(Config.WaterRefill.propModel))
            return
        end
    end

    for _, pt in ipairs(points) do
        local obj = CreateObject(model, pt.coords.x, pt.coords.y, pt.coords.z, false, false, false)
        SetEntityAsMissionEntity(obj)
        -- สแนปลงพื้นเอง — พิกัด z ใน config จึงไม่ต้องเป๊ะ ขอแค่ x/y ไม่ชนสิ่งกีดขวาง
        PlaceObjectOnGroundProperly(obj)
        SetEntityHeading(obj, pt.heading)
        FreezeEntityPosition(obj, true)
        props[#props + 1] = obj
    end
    SetModelAsNoLongerNeeded(model)
end)

-- ── เติมน้ำ ─────────────────────────────────────────────────────────────────
local function doRefill()
    busy = true

    local tank = rpc('lp_planting:checkBucket')
    if not (tank and tank.hasBucket) then
        exports.pNotify:SendNotification({ type = 'error', text = 'ไม่มีถังน้ำ', timeout = 4000 })
        busy = false; return
    end
    if (tank.uses or 0) >= Config.WaterRefill.usesPerRefill then
        exports.pNotify:SendNotification({ type = 'info', text = 'ถังน้ำเต็มอยู่แล้ว', timeout = 3500 })
        busy = false; return
    end

    local done, cancelled = false, false
    exports.lp_progbar:Progress({
        duration = 4000, label = 'กำลังเติมน้ำ...',
        controlDisables = { disableMovement = true },
        -- WORLD_HUMAN_BUCKET_FILL = ท่าตักน้ำใส่ถัง (คนละท่ากับ BUCKET_POUR_LOW ที่ใช้รดน้ำ)
        animation = { task = 'WORLD_HUMAN_BUCKET_FILL' },
    }, function(c) cancelled = c; done = true end)
    while not done do Wait(0) end

    if cancelled then busy = false; return end

    local res = rpc('lp_planting:refillBucket')
    if res and res.ok then
        exports.pNotify:SendNotification({
            type = 'success',
            text = ('เติมน้ำเต็มถังแล้ว (รดได้ %d ครั้ง)'):format(Config.WaterRefill.usesPerRefill),
            timeout = 3500 })
    else
        exports.pNotify:SendNotification({ type = 'error', text = 'เติมน้ำไม่สำเร็จ', timeout = 4000 })
    end
    busy = false
end

-- ── prompt ที่จุดเติมน้ำ ────────────────────────────────────────────────────
CreateThread(function()
    local active = nil

    while true do
        Wait(active and 0 or 500)

        if busy then
            if active then exports.lp_textui:CancelHold(); active = nil end
            goto continue
        end

        local pos = GetEntityCoords(PlayerPedId())
        local target = nil
        for _, pt in ipairs(points) do
            if #(pos - pt.coords) < Config.WaterRefill.range then target = pt; break end
        end

        if active and target ~= active then
            exports.lp_textui:CancelHold()
            active = nil
        end

        if target and not active then
            active = target
            exports.lp_textui:TextUIHold('[E] เติมน้ำใส่ถัง', Config.WaterRefill.holdMs, function()
                active = nil
                doRefill()
            end, nil, { coords = target.coords, offset = vector3(0.0, 0.0, 1.0) })
        end

        ::continue::
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, obj in ipairs(props) do
        if DoesEntityExist(obj) then
            SetEntityAsMissionEntity(obj, false, true)
            DeleteEntity(obj)
            DeleteObject(obj)
        end
    end
end)
