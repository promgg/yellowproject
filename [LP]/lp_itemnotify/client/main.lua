RegisterNetEvent('lp_itemnotify:show')
AddEventHandler('lp_itemnotify:show', function(data)
    SendNUIMessage({
        action   = 'lp_itemnotify:show',
        image    = data.image,
        name     = data.name,
        label    = data.label,
        qtyText  = data.qtyText,
        duration = data.duration,
    })
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    SendNUIMessage({ action = 'lp_itemnotify:init', imgPath = 'nui://vorp_inventory/html/img/items/' })
end)

-- ===== แจ้งเตือนเงินเข้า/ออก "ทุกทาง" =====
-- addCurrency/removeCurrency (ทางหลักสมัยใหม่) ไม่ยิง vorp:addMoney/removeMoney แต่เรียก
-- updateCharUi() -> vorp:updateUi พร้อมยอดจริงเสมอ เลยดักที่นี่แล้ว diff เอา (จับได้ทั้ง old + modern)
local CURRENCY = {
    { key = 'money', img = 'money',   name = 'เงินสด' },
    { key = 'gold',  img = 'goldbar', name = 'ทอง' },
    { key = 'rol',   img = 'money',   name = 'ROL' },
}

-- baseline = ยอดเดิมที่จำไว้ (nil = ยังไม่ตั้ง -> ครั้งแรกแค่จำ ไม่เด้ง เช่น ตอน login/โหลดยอด)
local lastMoney = nil

local function moneyToast(cur, delta)
    local gained = delta > 0
    SendNUIMessage({
        action   = 'lp_itemnotify:show',
        image    = cur.img,
        name     = cur.name,
        label    = gained and 'ADDED' or 'REMOVED',
        qtyText  = (gained and '+ ' or '- ') .. tostring(math.abs(delta)),
        duration = 4000,
    })
end

RegisterNetEvent('vorp:updateUi', function(stringJson)
    local ok, data = pcall(json.decode, stringJson)
    if not ok or type(data) ~= 'table' then return end

    local now = {
        money = tonumber(data.moneyquanty) or 0,
        gold  = tonumber(data.goldquanty) or 0,
        rol   = tonumber(data.rolquanty) or 0,
    }

    -- ครั้งแรก (login/โหลดยอด) หรือหลังสลับร่าง = ตั้ง baseline เฉยๆ ไม่เด้ง
    if lastMoney == nil then
        lastMoney = now
        return
    end

    for i = 1, #CURRENCY do
        local cur = CURRENCY[i]
        local delta = now[cur.key] - lastMoney[cur.key]
        if delta ~= 0 then
            moneyToast(cur, delta)
        end
    end

    lastMoney = now
end)

-- สลับตัวละคร: ล้าง baseline -> ยอดของร่างใหม่เป็นตั้งต้นใหม่ (กันเด้ง delta ก้อนใหญ่ตอนเปลี่ยนร่าง)
RegisterNetEvent('vorp:SelectedCharacter', function()
    lastMoney = nil
end)
