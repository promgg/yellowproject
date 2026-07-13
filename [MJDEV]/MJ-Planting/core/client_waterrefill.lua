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

-- ── Spawn/ลบ prop ตามระยะผู้เล่น (เดิม spawn ทุกจุดค้างไว้ตลอดตั้งแต่ resource start —
-- เปลืองทั้ง 3 เมืองพร้อมกันทั้งที่อยู่ได้ทีละที่ — ตอนนี้ spawn เมื่อเข้าระยะ SPAWN_RANGE เท่านั้น
-- และลบเมื่อออกเกิน SPAWN_EXIT (hysteresis กันสั่นตรงขอบระยะ) ──
local SPAWN_RANGE = 20.0 -- m — เข้าระยะนี้ถึง spawn (เท่า range โซนปลูกใน config)
local SPAWN_EXIT  = 23.0 -- m — ออกเกินระยะนี้ถึงลบ (กันสั่นตรงขอบ 20m)

Citizen.CreateThread(function()
    repeat Citizen.Wait(500) until LocalPlayer.state and LocalPlayer.state.IsInSession

    refillPoints = getUniqueRefillPoints()

    -- ตอนเพิ่งเข้าเซิฟ engine กำลัง stream ของหนักมาก LoadModel (timeout 5s) พลาดจังหวะได้บ่อย —
    -- เดิม fail รอบเดียวแล้ว return ทิ้ง thread ถาวร ปั๊มน้ำเลยไม่ spawn ไปตลอด session จนกว่าจะ
    -- restart resource ต้อง retry ต่อจนกว่าจะโหลดสำเร็จแทน ไม่ยอมแพ้แค่รอบเดียว
    while not LoadModel(MJDEV.WaterRefill.propModel) do
        Citizen.Wait(2000)
    end
    local hash = GetHashKey(MJDEV.WaterRefill.propModel)

    while true do
        Citizen.Wait(250)
        local pos = GetEntityCoords(PlayerPedId())

        for _, point in ipairs(refillPoints) do
            local dist    = #(pos - point.coords)
            local spawned = point.prop and DoesEntityExist(point.prop)

            if not spawned and dist <= SPAWN_RANGE then
                local obj = CreateObject(hash, point.coords.x, point.coords.y, point.coords.z - 1.0, false, false, false)
                -- ต้อง SetEntityAsMissionEntity ก่อน ไม่งั้น engine จะเก็บกวาด (garbage collect) prop ทิ้งไปเอง
                -- หลังสร้างไม่นาน เพราะไม่ใช่ mission entity (เทียบ pattern จาก MJ-Airdrop core/client.lua)
                SetEntityAsMissionEntity(obj, true, true)
                SetEntityHeading(obj, point.heading)
                PlaceObjectOnGroundProperly(obj)
                FreezeEntityPosition(obj, true)
                point.prop = obj
            elseif spawned and dist > SPAWN_EXIT then
                DeleteEntity(point.prop)
                point.prop = nil
            end
        end
    end
end)

-- ── เติมน้ำจริง (callback ของ TextUIHold) — เล่น lp_progbar + anim ตักน้ำ ก่อนยิง RPC ──
-- isRefilling กันไม่ให้ Hold hint loop โชว์ "[E] เพื่อเติมน้ำ" ซ้อนขึ้นมาอีกรอบระหว่าง progbar กำลังเล่น
-- (เดิม hint callback set shown=false ทันทีที่กด E ครบ hold แล้ว loop ก็เห็น inRange ตั้ง shown=true คืน
-- ในติ๊กถัดไปเลย ทั้งที่ progbar ยังไม่จบ)
local isRefilling = false

local function refillWaterTank()
  Citizen.CreateThread(function()
    VORPcore.RpcCall('MJ-Planting:CheckWaterTank:SV', function(tank)
        if not (tank and tank.hasTank) then
            exports.pNotify:SendNotification({ type = 'error', text = 'คุณไม่มีถังน้ำในกระเป๋า', timeout = 3000 })
            return
        end
        if tank.uses and tank.uses >= MJDEV.WaterRefill.usesPerRefill then
            exports.pNotify:SendNotification({ type = 'info', text = 'ถังน้ำเต็มอยู่แล้ว', timeout = 3000 })
            return
        end

        isRefilling = true
        local cancelled = runProgress({
            duration = MJDEV.RefillAnim.duration,
            label = MJDEV.RefillAnim.label,
            controlDisables = { disableMovement = true },
            animation = { task = MJDEV.RefillAnim.task },
        })
        ClearPedTasksImmediately(PlayerPedId())
        if cancelled then isRefilling = false; return end

        VORPcore.RpcCall('MJ-Planting:RefillWaterTank:SV', function(result)
            if result and result.ok then
                exports.pNotify:SendNotification({
                    type = 'success',
                    text = ('เติมน้ำสำเร็จ! รดได้อีก %d ครั้ง'):format(MJDEV.WaterRefill.usesPerRefill),
                    timeout = 3000,
                })
            elseif result and result.alreadyFull then
                exports.pNotify:SendNotification({ type = 'info', text = 'ถังน้ำเต็มอยู่แล้ว', timeout = 3000 })
            else
                exports.pNotify:SendNotification({ type = 'error', text = 'คุณไม่มีถังน้ำในกระเป๋า', timeout = 3000 })
            end
            isRefilling = false
        end)
    end)
  end)
end

-- ── Hold hint (state machine แยกจากลูป spawn prop) ──
-- hysteresis กันสั่นตรงขอบระยะ (เข้า <= range, ออก > range + 0.3) แบบเดียวกับ MJ-Lumberjack/MJ-Mining
Citizen.CreateThread(function()
    repeat Citizen.Wait(500) until LocalPlayer.state and LocalPlayer.state.IsInSession
    local shown = false

    while true do
        Citizen.Wait(150)

        if isRefilling then
            if shown then
                shown = false
                exports.lp_textui:CancelHold()
            end
            goto continue
        end

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
        ::continue::
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
