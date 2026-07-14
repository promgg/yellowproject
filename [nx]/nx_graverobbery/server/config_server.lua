-- server-only config — ไม่ผ่าน shared_scripts จึงไม่ถูกส่งไปฝั่ง client เลย
-- (webhook URL และ loot odds ไม่ควรหลุดไปอยู่ในไฟล์ที่ client โหลดได้)

Config.Logging = {
    console = true,
    database = false,
    webhook = false,
    webhookUrl = '',
}

Config.RewardPools = {
    -- ของงานดำ 7 ชิ้น น้ำหนักเท่ากันทุกชิ้น การันตี 1 ชิ้นต่อหลุมเสมอ (emptyChance=0, ไม่มีเงิน)
    -- ยืนยันชื่อ item + label ไทยตรงกับ DB จริงแล้ว (mjdevcore_18k.items) ผ่าน query ตรง 2026-07-14
    default_grave = {
        emptyChance = 0,
        money = { enabled = false, min = 0, max = 0, currency = 0 },
        items = {
            { name = 'loot_necklace',     min = 1, max = 1, weight = 1 }, -- สร้อยคอ
            { name = 'loot_ring',         min = 1, max = 1, weight = 1 }, -- แหวน
            { name = 'loot_watch',        min = 1, max = 1, weight = 1 }, -- นาฬิกา
            { name = 'loot_chinese_coin', min = 1, max = 1, weight = 1 }, -- เหรียญเงินจีน
            { name = 'loot_earring',      min = 1, max = 1, weight = 1 }, -- ต่างหู
            { name = 'loot_brooch',       min = 1, max = 1, weight = 1 }, -- เข็มกลัด
            { name = 'loot_silver_tooth', min = 1, max = 1, weight = 1 }, -- ฟันเงิน
        },
    },
}
