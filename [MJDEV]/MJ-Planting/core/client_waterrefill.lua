-- MJ-Planting — จุดเติมน้ำ (water refill points)
-- พิกัด/heading ของ prop แยกอิสระจากจุดปลูกแล้ว กำหนดได้ที่ MJDEV.WaterRefill.points ใน config.lua ต่อ zoneId
-- (zoneId ไหนไม่ได้ระบุไว้ fallback ไปใช้ zone.coords + heading 0.0)
-- กดค้าง E (แบบเดียวกับ MJ-Lumberjack/MJ-Mining) เพื่อเติม uses ให้ tool_bucket ในกระเป๋า

local HINT_REFILL = '[E] เพื่อเติมน้ำ'
local refillPoints = {} -- { {zoneId, zoneName, coords, heading, prop}, ... }

-- ── รวม zoneId ซ้ำออก (จุดปลูกจุดเดียวกันมีหลาย entry ต่อพืชหลายชนิด แต่เติมน้ำจุดเดียวพอ) ──
local function getUniqueRefillPoints()
    local seen   = {}
    local points = {}
    for _, zone in ipairs(MJDEV['Planting']) do
        if not seen[zone.zoneId] then
            seen[zone.zoneId] = true
            local override = MJDEV.WaterRefill.points and MJDEV.WaterRefill.points[zone.zoneId]
            local coords  = (override and override.coords) or zone.coords
            local heading = (override and override.heading) or 0.0
            table.insert(points, { zoneId = zone.zoneId, zoneName = zone.zoneName, coords = coords, heading = heading })
        end
    end
    return points
end

-- ── Spawn prop ทุกจุด (ครั้งเดียวตอน resource start) ──
Citizen.CreateThread(function()
    repeat Citizen.Wait(500) until LocalPlayer.state and LocalPlayer.state.IsInSession

    refillPoints = getUniqueRefillPoints()

    if LoadModel(MJDEV.WaterRefill.propModel) then
        local hash = GetHashKey(MJDEV.WaterRefill.propModel)
        for _, point in ipairs(refillPoints) do
            local obj = CreateObject(hash, point.coords.x, point.coords.y, point.coords.z - 1.0, false, false, false)
            -- ต้อง SetEntityAsMissionEntity ก่อน ไม่งั้น engine จะเก็บกวาด (garbage collect) prop ทิ้งไปเอง
            -- หลังสร้างไม่นาน เพราะไม่ใช่ mission entity (เทียบ pattern จาก MJ-Airdrop core/client.lua)
            SetEntityAsMissionEntity(obj, true, true)
            SetEntityHeading(obj, point.heading)
            PlaceObjectOnGroundProperly(obj)
            FreezeEntityPosition(obj, true)
            point.prop = obj
        end
    end
end)

-- ── เติมน้ำจริง (callback ของ TextUIHold) ──
local function refillWaterTank()
    VORPcore.RpcCall('MJ-Planting:RefillWaterTank:SV', function(result)
        if result and result.ok then
            exports.pNotify:SendNotification({
                type = 'success',
                text = ('เติมน้ำสำเร็จ! รดได้อีก %d ครั้ง'):format(MJDEV.WaterRefill.usesPerRefill),
                timeout = 3000,
            })
        elseif result and result.alreadyFull then
            exports.pNotify:SendNotification({
                type = 'info',
                text = 'ถังน้ำเต็มอยู่แล้ว',
                timeout = 3000,
            })
        else
            exports.pNotify:SendNotification({
                type = 'error',
                text = 'คุณไม่มีถังน้ำในกระเป๋า',
                timeout = 3000,
            })
        end
    end)
end

-- ── Hold hint (state machine แยกจากลูป spawn prop) ──
-- hysteresis กันสั่นตรงขอบระยะ (เข้า <= range, ออก > range + 0.3) แบบเดียวกับ MJ-Lumberjack/MJ-Mining
Citizen.CreateThread(function()
    repeat Citizen.Wait(500) until LocalPlayer.state and LocalPlayer.state.IsInSession
    local shown = false

    while true do
        Citizen.Wait(150)

        local inRange = false
        local pos = GetEntityCoords(PlayerPedId())
        for _, point in ipairs(refillPoints) do
            local dist = #(pos - point.coords)
            if dist <= (shown and (MJDEV.WaterRefill.range + 0.3) or MJDEV.WaterRefill.range) then
                inRange = true
                break
            end
        end

        if inRange and not shown then
            shown = true
            exports.lp_textui:TextUIHold(HINT_REFILL, MJDEV.WaterRefill.holdMs, function()
                shown = false
                refillWaterTank()
            end, MJDEV.Controls.EnterKey)
        elseif (not inRange) and shown then
            shown = false
            exports.lp_textui:CancelHold()
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    exports.lp_textui:CancelHold()
    for _, point in ipairs(refillPoints) do
        if point.prop and DoesEntityExist(point.prop) then
            DeleteEntity(point.prop)
        end
    end
end)
