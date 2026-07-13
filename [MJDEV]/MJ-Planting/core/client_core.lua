local script_name = "!MJ-Planting"

Citizen.CreateThread(function()
    Wait(1500)
    TriggerServerEvent(script_name .. ":CL:GetEvent_Planting")
end)

RegisterNetEvent(script_name .. ":SV:GetEvent_Planting")
AddEventHandler(script_name .. ":SV:GetEvent_Planting", function()
    -- เดิมมีเช็ค GetCurrentResourceName() == script_name ("!MJ-Planting") ก่อนเรียกฟังก์ชันนี้
    -- แต่โฟลเดอร์จริงชื่อ "MJ-Planting" (ไม่มี "!") เงื่อนไขเลย false ตลอด ทำให้ MJDEV_GetEvent_Planting()
    -- ไม่เคยถูกเรียก -> ไม่มีการลงทะเบียน event "MJ-Planting:Start" และไม่มี blip โซนปลูกเลย (เงียบ ไม่ error)
    MJDEV_GetEvent_Planting()
end)

-- บล็อกจนกว่า RpcCall จะตอบกลับ แล้วคืนผลลัพธ์ (ให้เขียน ritual เป็นลำดับได้ ไม่ต้อง nest callback)
local function rpcAwait(name, ...)
    local done, res = false, nil
    VORPcore.RpcCall(name, function(r) res = r; done = true end, ...)
    local start = GetGameTimer()
    while not done do
        Citizen.Wait(0)
        if GetGameTimer() - start > 10000 then return nil end
    end
    return res
end

local function notifyErr(text) exports.pNotify:SendNotification({ type = 'error', text = text, timeout = 4000 }) end

-- เริ่มนับเวลาโต (เรียกหลัง "รดน้ำ" เสร็จ) — Hungry +1/วิ, สลับต้นโตกึ่งทาง, Give ที่ plantmax
local function startGrow(entry)
    Citizen.CreateThread(function()
        while entry.Planting and DoesEntityExist(entry.Planting) and not entry.Give do
            Citizen.Wait(1000)
            entry.Hungry = entry.Hungry + 1
            if entry.Hungry >= entry.Watering and not entry.Swapped then
                entry.Swapped = true
                local pos = GetEntityCoords(entry.Planting)
                local hdg = GetEntityHeading(entry.Planting)
                DeleteEntity(entry.Planting); DeleteObject(entry.Planting)
                if LoadModel(entry.Data.model2) then
                    local grown = CreateObject(entry.Data.model2, pos.x, pos.y, pos.z, true, true, false)
                    SetEntityAsMissionEntity(grown)
                    PlaceObjectOnGroundProperly(grown)
                    SetEntityHeading(grown, hdg)
                    FreezeEntityPosition(grown, true)
                    PlaySoundFrontend("CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", true, 1)
                    entry.Planting = grown
                end
            end
            if entry.Hungry >= entry.PlantMax then entry.Give = true; entry.Stage = 'ready' end
        end
    end)
end

local function restorePlant(data)
    local k = data.idx and MJDEV['Planting'][data.idx]
    if not k then return end

    local model = k.model
    local hungry, swapped, give = 0, false, false

    if data.Stage == 'grow' or data.Stage == 'ready' then
        local elapsedSec = data.waterAt and math.floor((GetGameTimer() - data.waterAt) / 1000) or 0
        hungry = math.max(0, math.min(elapsedSec, k.plantmax))
        swapped = hungry >= k.watering
        if swapped then model = k.model2 end
        give = data.Stage == 'ready'
    end

    if not LoadModel(model) then return end
    local obj = CreateObject(model, data.coords.x, data.coords.y, data.coords.z, true, true, false)
    SetEntityAsMissionEntity(obj)
    PlaceObjectOnGroundProperly(obj)
    SetEntityHeading(obj, data.heading)
    FreezeEntityPosition(obj, true)

    Count[k.zoneId] = (Count[k.zoneId] or 0) + 1
    local entry = {
        Planting = obj, Data = k, PlantId = data.plantId,
        PlantMax = k.plantmax, Watering = k.watering,
        Hungry = hungry, Give = give, Swapped = swapped,
        Stage = data.Stage,
    }
    table.insert(PLANT, entry)

    if data.Stage == 'grow' then
        startGrow(entry)
    end
end

Citizen.CreateThread(function()
    Citizen.Wait(3000)
    local mine = rpcAwait('MJ-Planting:GetMyPlants:SV')
    if not mine then return end
    for _, data in ipairs(mine) do
        restorePlant(data)
    end
end)

-- STEP 1-2: ใช้เมล็ด (เช็คแค่เมล็ด) -> ghost placement (freeze ผู้เล่น) -> ปลูกต้นกล้า สถานะ 'fertilize'
-- ปุ๋ย/น้ำ ไม่เช็ค/ไม่หักที่นี่ — แยกไปเป็น interaction กด E ที่ต้น (ดู doPlantAction/loop ด้านล่าง)
function StartPlantings(k)
    local zoneId = k.zoneId
    Count[zoneId] = Count[zoneId] or 0

    if Start[zoneId] then return end -- กำลังปลูกที่โซนนี้อยู่แล้ว (race guard)

    -- เช็คระยะห่างจากต้นอื่นในโซนเดียวกัน
    local minDis = k.Dis or 3.0
    for i = 1, #PLANT do
        if PLANT[i].Planting and DoesEntityExist(PLANT[i].Planting)
            and PLANT[i].Data.zoneId == zoneId
            and #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(PLANT[i].Planting)) < minDis then
            notifyErr('มีพืชปลูกอยู่ใกล้เกินไป กรุณาปลูกให้ห่างกว่านี้')
            return
        end
    end

    Start[zoneId] = true

    -- ── Ghost placement (เช็คแค่เมล็ด — มาถึงนี่ได้แปลว่ากำลังใช้เมล็ด) freeze ผู้เล่นใน GhostPlace ──
    local place = GhostPlace(k.model)
    if not place then Start[zoneId] = false; return end

    -- ── lp_progbar ท่าปลูกเมล็ด (ต่อจาก ghost confirm) — ยกเลิกกลางคัน = ยังไม่หักเมล็ด/ไม่ spawn ──
    if animPlant() then Start[zoneId] = false; return end

    -- server ยืนยัน + หักเมล็ดจริงตรงนี้ (ระยะ/โควตา/ระยะห่างจากต้นอื่น/มีเมล็ดจริงไหม ตรวจซ้ำฝั่ง
    -- server ทั้งหมด — ไม่เชื่อผลเช็คฝั่ง client อีกต่อไป) ได้ plantId กลับมาผูกกับ entry นี้
    local placed = rpcAwait('MJ-Planting:ConfirmPlace:SV', k.idx, place.coords, place.heading)
    if not (placed and placed.ok) then
        notifyErr('ปลูกไม่สำเร็จ (' .. tostring(placed and placed.reason or 'error') .. ')')
        Start[zoneId] = false
        return
    end

    if not LoadModel(k.model) then Start[zoneId] = false; return end
    local animal = CreateObject(k.model, place.coords.x, place.coords.y, place.coords.z, true, true, false)
    SetEntityAsMissionEntity(animal)
    PlaceObjectOnGroundProperly(animal)
    SetEntityHeading(animal, place.heading)
    FreezeEntityPosition(animal, true)
    PlaySoundFrontend("CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", true, 1)

    Count[zoneId] = Count[zoneId] + 1
    local entry = {
        Planting = animal, Data = k, PlantId = placed.plantId,
        PlantMax = k.plantmax, Watering = k.watering,
        Hungry = 0, Give = false, Swapped = false,
        Stage = 'fertilize', -- fertilize -> water -> grow -> ready
    }
    table.insert(PLANT, entry)
    Start[zoneId] = false
    exports.pNotify:SendNotification({ type = 'info', text = 'ปลูกเมล็ดแล้ว — กดค้าง E ที่ต้นเพื่อใส่ปุ๋ย', timeout = 4000 })

    -- ── กันต้นค้าง: หมด time_need แล้วยังไม่ถูกเก็บ = ลบทิ้ง คืนโควตา ──
    Citizen.CreateThread(function()
        local timer = k.time_need
        while timer > 0 do Citizen.Wait(1000); timer = timer - 1000 end
        for i, v in ipairs(PLANT) do
            if v == entry then
                if v.Planting and DoesEntityExist(v.Planting) then DeleteEntity(v.Planting) end
                table.remove(PLANT, i)
                Count[zoneId] = math.max(0, (Count[zoneId] or 1) - 1)
                break
            end
        end
    end)
end

-- (ลบ thread ปรับ sleep เดิมทิ้ง — มันปรับ local sleep ของลูปตัวเองที่ไม่มีผลกับ thread เก็บเกี่ยว
--  ซ้ำซ้อน + มี `return` ที่ฆ่า thread ถาวร + จะ error ถ้า Planting เป็น nil)

-- ── การกระทำต่อต้น (blocking): ใส่ปุ๋ย -> รดน้ำ -> เก็บเกี่ยว (แต่ละขั้นเช็คของของตัวเอง) ──
local function doPlantAction(entry, action)
    isPutfeed = true
    local ent = entry.Planting

    if action == 'fertilize' then
        if not rpcAwait('MJ-Planting:Getitem:SV', MJDEV.FertilizerItem) then
            notifyErr('คุณไม่มีปุ๋ย (compost)'); isPutfeed = false; return
        end
        if animFertilize() then isPutfeed = false; return end -- ยกเลิก: ยังไม่หัก
        -- server ตรวจ Stage/ระยะ/ของจริงอีกรอบ แล้วหักปุ๋ย + เลื่อน Stage ให้ที่นั่น (ไม่เชื่อ client อีกแล้ว)
        local res = rpcAwait('MJ-Planting:Fertilize:SV', entry.PlantId)
        if not (res and res.ok) then
            notifyErr('ใส่ปุ๋ยไม่สำเร็จ'); isPutfeed = false; return
        end
        entry.Stage = 'water'
        exports.pNotify:SendNotification({ type = 'success', text = 'ใส่ปุ๋ยแล้ว — กดค้าง E เพื่อรดน้ำต่อ', timeout = 3500 })

    elseif action == 'water' then
        local tank = rpcAwait('MJ-Planting:CheckWaterTank:SV')
        if not (tank and tank.hasTank and tank.uses and tank.uses > 0) then
            notifyErr(tank and tank.hasTank and 'ถังน้ำหมด กรุณาไปเติมน้ำก่อน' or 'คุณไม่มีถังน้ำ')
            isPutfeed = false; return
        end
        if animacion2() then isPutfeed = false; return end -- ยกเลิก: ยังไม่หัก
        -- server ตรวจ Stage/ระยะ/ถังน้ำอีกรอบ แล้วหัก uses + stamp waterAt (ตัดสิน "โตแล้วจริง" ตอนเก็บเกี่ยว) ที่นั่น
        local res = rpcAwait('MJ-Planting:Water:SV', entry.PlantId)
        if not (res and res.ok) then
            notifyErr('รดน้ำไม่สำเร็จ'); isPutfeed = false; return
        end
        local remaining = res.remaining or 0
        exports.pNotify:SendNotification({
            type = remaining > 0 and 'success' or 'info',
            text = remaining > 0 and ('รดน้ำสำเร็จ! ต้นเริ่มโตแล้ว (เหลือน้ำ %d ครั้ง)'):format(remaining)
                or 'รดน้ำสำเร็จ! ต้นเริ่มโตแล้ว (ถังน้ำหมด ไปเติมก่อนต้นถัดไป)',
            timeout = 3500,
        })
        entry.Stage = 'grow'
        startGrow(entry) -- เริ่มนับเวลาโตตรงนี้ (client-side, ใช้แค่โชว์ progress bar/model swap — ตัวตัดสินจริงอยู่ server)
        -- โจร: thread แยก ไม่งั้น BanditsStart (มี Wait(5000) วน spawn) จะ block doPlantAction
        -- ~10-15 วิ ทำให้ isPutfeed ค้าง = interact ต้นอื่นไม่ได้ระหว่างนั้น
        if math.random(1, 100) < (entry.Data.bandits or 0) then
            Citizen.CreateThread(function() BanditsStart() end)
        end

    elseif action == 'harvest' then
        if ent then FreezeEntityPosition(ent, true) end
        local cancelled = runProgress({
            duration = 8000, label = 'Harvesting...',
            controlDisables = { disableMovement = true },
            animation = { animDict = "mech_pickup@plant@berries", anim = "base" },
        })
        if not cancelled then
            -- server ตัดสินเองว่าโตครบเวลาจริงไหม (waterAt+plantmax) แล้วสุ่ม/ให้ item ที่นั่นทั้งหมด
            -- ไม่ใช่ client บอกแค่ชื่อเมล็ดแล้วเชื่อว่าพร้อมเก็บอีกต่อไป
            local res = rpcAwait('MJ-Planting:Harvest:SV', entry.PlantId)
            if res and res.ok then
                Count[entry.Data.zoneId] = math.max(0, (Count[entry.Data.zoneId] or 1) - 1)
                PlaySoundFrontend("CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", true, 1)
                if ent and DoesEntityExist(ent) then DeleteEntity(ent) end
                entry.Planting = nil
                for i, v in ipairs(PLANT) do if v == entry then table.remove(PLANT, i); break end end
            else
                if res and res.reason == 'fullinv' then
                    notifyErr('กระเป๋าเต็ม เก็บผักไม่ได้ — เคลียร์พื้นที่ก่อนแล้วลองใหม่')
                else
                    notifyErr('เก็บเกี่ยวไม่สำเร็จ — ต้นอาจจะยังไม่พร้อม')
                end
                if ent then FreezeEntityPosition(ent, false) end
            end
        elseif ent then
            FreezeEntityPosition(ent, false)
        end
    end

    isPutfeed = false
end

-- ── prompt ลอยเหนือต้น (world-anchored lp_textui:TextUIHold — แบบเดียวกับจุดเติมน้ำ) ──
-- ใส่ปุ๋ย / รดน้ำ / เก็บเกี่ยว ตามสถานะ ใช้ lp_textui จัดการ hold ring + DisableControlAction
-- + กันปุ่ม E โดน ambient scenario/context prompt อื่นแย่งเองทั้งหมด (เหตุที่กด E เองไม่ได้ก่อนหน้านี้)
local function findPlantTarget()
    local playerCoords = GetEntityCoords(PlayerPedId())
    for i = 1, #PLANT do
        local p = PLANT[i]
        local ent = p.Planting
        if ent and DoesEntityExist(ent) then
            local pos = GetEntityCoords(ent)
            if #(playerCoords - pos) < MJDEV.InteractRange then
                if p.Stage == 'fertilize' then return p, 'fertilize', '[E] ใส่ปุ๋ย', pos
                elseif p.Stage == 'water' then return p, 'water', '[E] รดน้ำ', pos
                elseif p.Stage == 'ready' then return p, 'harvest', '[E] เก็บเกี่ยว', pos end
            end
        end
    end
    return nil
end

Citizen.CreateThread(function()
    local activeEntry = nil

    while true do
        Citizen.Wait(activeEntry and 0 or 250)

        if isPutfeed then
            if activeEntry then
                exports.lp_textui:CancelHold()
                activeEntry = nil
            end
            goto continue
        end

        local target, action, label, pos = findPlantTarget()

        if activeEntry and target ~= activeEntry then
            exports.lp_textui:CancelHold()
            activeEntry = nil
        end

        if target and not activeEntry then
            activeEntry = target
            local thisEntry, thisAction = target, action
            exports.lp_textui:TextUIHold(label, MJDEV.InteractHoldMs, function()
                activeEntry = nil
                doPlantAction(thisEntry, thisAction)
            end, nil, { coords = pos, offset = vector3(0.0, 0.0, 0.3) })
        end

        ::continue::
    end
end)
