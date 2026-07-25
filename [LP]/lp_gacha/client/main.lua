-- ================================================================
--  lp_gacha client — สะพาน NUI <-> server เท่านั้น ไม่มี logic ตัดสินรางวัล
-- ================================================================

local isOpen = false

local function openUI(payload)
    exports.vorp_inventory:closeInventory() -- ปิด UI กระเป๋าก่อน กันซ้อนกับ NUI กาชา
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', data = payload })
end

local function closeUI()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

-- แจกม้าจากกาชา: spawn ม้าตาม model แล้วส่งเข้า kd_stable ผ่าน event ทางการ kd_stable:client:addHorse
-- (ตาม docs jumpon-studios) — kd_stable จะ register เป็นม้าของผู้เล่น + save DB + คำนวณ stat/สีตาม model
--
-- ⚠️ ต้องทำ "ทีละตัว" (queue): ถ้าออกม้าหลายตัวใน batch เดียว server จะยิง grantHorse หลาย event
--    พร้อมกันในเฟรมเดียว → spawn ped + addHorse รัว ๆ ที่จุดเดียวกัน → kd_stable ประมวลผลไม่ทัน
--    (race) ม้าจะเข้า DB ไม่ครบ (เช่นส่ง 10 เข้า 9) — เข้าคิวแล้วปล่อยทีละตัว เว้นระยะ กันตกหล่น
local horseQueue = {}
local horseProcessing = false

local function processHorseQueue()
    if horseProcessing then return end
    horseProcessing = true
    CreateThread(function()
        while #horseQueue > 0 do
            local data = table.remove(horseQueue, 1)
            local model = joaat(data.model)
            RequestModel(model)
            local t = GetGameTimer()
            while not HasModelLoaded(model) and (GetGameTimer() - t) < 8000 do Wait(20) end

            if HasModelLoaded(model) then
                local playerPed = PlayerPedId()
                local fwd = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 2.5, 0.0) -- วางหน้า player 2.5m
                local horse = CreatePed(model, fwd.x, fwd.y, fwd.z, GetEntityHeading(playerPed), true, false, false, false)
                SetModelAsNoLongerNeeded(model)
                if horse and horse ~= 0 and DoesEntityExist(horse) then
                    Citizen.InvokeNative(0x9587913B9E772D29, horse, 0) -- PlaceEntityOnGroundProperly
                    if data.gender == 'female' then
                        Citizen.InvokeNative(0x5653AB26C82938CF, horse, 41611, 1.0) -- SetCharExpression (เพศเมีย)
                        Citizen.InvokeNative(0xCC8CA3E88256E58F, horse, false, true, true, true, false) -- UpdatePedVariation
                    end
                    -- ส่งต่อให้ kd_stable จัดการ (register + save + จัดการ ped ม้าต่อเอง)
                    TriggerEvent('kd_stable:client:addHorse', horse, data.name or 'Paradise', data.age or 2, data.noDieByAge ~= false)
                    Wait(1500) -- ให้ kd_stable ประมวลผล addHorse + save เสร็จก่อนตัวต่อไป (กัน race)
                else
                    print('^1[lp_gacha]^7 สร้าง ped ม้าไม่สำเร็จ: ' .. tostring(data.model))
                    Wait(200)
                end
            else
                print('^1[lp_gacha]^7 โหลดโมเดลม้าไม่สำเร็จ: ' .. tostring(data.model))
                Wait(200)
            end
        end
        horseProcessing = false
    end)
end

RegisterNetEvent('lp_gacha:grantHorse', function(data)
    if type(data) ~= 'table' or not data.model then return end
    horseQueue[#horseQueue + 1] = data
    processHorseQueue()
end)

-- server สั่งเปิด (มาจากการใช้ตั๋ว, source ถูก validate ฝั่ง server แล้ว)
RegisterNetEvent('lp_gacha:open', function(payload)
    openUI(payload)
end)

-- ผลการสุ่มจาก server (โชว์อย่างเดียว)
RegisterNetEvent('lp_gacha:result', function(winners, remaining)
    SendNUIMessage({ action = 'result', winners = winners, remaining = remaining })
end)

RegisterNetEvent('lp_gacha:spinRejected', function(reason)
    SendNUIMessage({ action = 'rejected', reason = reason })
end)

-- ประกาศทั้งเซิร์ฟ (ยิงถึงทุกคน) — โชว์ banner ได้แม้ไม่ได้เปิดหน้ากาชาอยู่
-- SendNUIMessage ส่งเข้า NUI ได้เสมอเพราะ page โหลดค้างตลอด ไม่ต้องมี focus/เปิดหน้า
RegisterNetEvent('lp_gacha:broadcast', function(text)
    SendNUIMessage({ action = 'broadcast', text = text })
end)

-- ---------- NUI callbacks ----------
-- คำขอสปิน: relay ตรงไป server ไม่ตัดสินอะไรฝั่ง client
RegisterNUICallback('spin', function(data, cb)
    local pool = data and data.pool
    local qty  = tonumber(data and data.qty)
    if pool and qty then
        TriggerServerEvent('lp_gacha:spin', pool, qty)
    end
    cb('ok')
end)

-- NUI แจ้งว่าอนิเมชันเผยผลจบแล้ว → server แจกของตอนนี้ (ไม่ใช่ก่อนเผย)
RegisterNUICallback('revealDone', function(_, cb)
    TriggerServerEvent('lp_gacha:revealDone')
    cb('ok')
end)

RegisterNUICallback('close', function(_, cb)
    closeUI()
    cb('ok')
end)

-- ---------- cleanup ----------
AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and isOpen then
        SetNuiFocus(false, false)
    end
end)
