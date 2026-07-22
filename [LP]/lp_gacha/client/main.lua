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
