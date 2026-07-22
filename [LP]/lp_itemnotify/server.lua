-- vorp_inventory เรียก exports['lp_itemnotify']:notification(source, config) ตรงๆ
-- config = { position, image, title, description, type, time } — type: 'success' = ได้ของ, 'warning' = เสียของ
-- config.image เป็นชื่อภายใน (เช่น legendary_rockbass) เท่านั้น ไม่มี label ที่อ่านง่ายมาด้วย
-- เลยเรียก vorp_inventory:getItem เองที่นี่เพื่อดึง label จริงมาโชว์ (ไม่ต้องแก้ vorp_inventory เพิ่ม)
local function resolveItemLabel(source, itemName)
    if not itemName then return itemName end
    local ok, item = pcall(function() return exports.vorp_inventory:getItem(source, itemName) end)
    if ok and item and item.label then return item.label end
    return itemName
end

exports('notification', function(source, config)
    if not source or source == 0 or not config then return end

    TriggerClientEvent('lp_itemnotify:show', source, {
        image    = config.image,
        name     = resolveItemLabel(source, config.image),
        label    = config.type == 'success' and 'ADDED' or 'REMOVED',
        qtyText  = config.description,
        duration = config.time,
    })
end)

-- แจ้งเตือนเงินเข้า/ออก: ย้ายไปจับที่ client แล้ว (client/main.lua) ผ่าน vorp:updateUi + diff ยอด
-- เพราะ event เก่า vorp:addMoney/removeMoney เป็น old API เท่านั้น — ทางหลักสมัยใหม่
-- (Character.addCurrency/removeCurrency, /addmoney ของ vorp_core, สคริปต์อื่น) ไม่ยิง event นี้
-- เลยจับไม่ครบ. updateCharUi() ถูกเรียกทุกครั้งที่ยอดเปลี่ยน -> vorp:updateUi จับได้ทุก path

-- ทดสอบในเกม (พิมพ์ในแชท ไม่ใช่ console เซิร์ฟเวอร์): /lp_testnotify [add|remove] [ชื่อไอเทม] [จำนวน]
-- ตั้งชื่อไม่ให้ชนกับ /testitemnotify ของ MJ-Itemnotify เดิม (ยัง ensure ค้างอยู่ ไม่งั้นจะโดนทับกัน)
RegisterCommand('lp_testnotify', function(source, args)
    if not source or source == 0 then
        print('[lp_itemnotify] ต้องรันจากแชทในเกม ไม่ใช่ console เซิร์ฟเวอร์')
        return
    end

    -- Development-only command: never let ordinary players create arbitrary
    -- notification payloads in production.
    if not IsPlayerAceAllowed(source, 'lp_itemnotify.test') then
        return
    end

    local kind = args[1] or 'add'
    local item = args[2] or 'bread'
    local qty  = tonumber(args[3]) or 1

    exports['lp_itemnotify']:notification(source, {
        image       = item,
        title       = kind == 'remove' and 'คุณสูญเสีย Item' or 'คุณได้รับ Item',
        description = (kind == 'remove' and '- ' or '+ ') .. qty,
        type        = kind == 'remove' and 'warning' or 'success',
        time        = 4000,
    })
end, false)
