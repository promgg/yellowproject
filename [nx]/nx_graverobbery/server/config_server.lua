-- server-only config — ไม่ผ่าน shared_scripts จึงไม่ถูกส่งไปฝั่ง client เลย
-- (webhook URL และ loot odds ไม่ควรหลุดไปอยู่ในไฟล์ที่ client โหลดได้)

Config.Logging = {
    console = true,
    database = false,
    webhook = false,
    webhookUrl = '',
}

Config.RewardPools = {
    default_grave = {
        emptyChance = 25,
        money = { enabled = true, min = 0, max = 10, currency = 0 },
        -- ไอเทมทั้งหมดยืนยันแล้วว่ามีจริงใน DB (mjdevcore_18k.items) — ตัวที่ไม่มีถูกแทนด้วย loot_ label ไทย
        items = {
            { name = 'loot_silver_coin', min = 1, max = 3, weight = 20 }, -- แทน coin_half_penny (ไม่มีใน DB) — เหรียญเงิน
            { name = 'cigar',            min = 1, max = 2, weight = 15 }, -- มีอยู่แล้วใน DB
            { name = 'loot_ring',        min = 1, max = 1, weight = 10 }, -- แทน silver_ring (ไม่มีใน DB) — แหวน
            { name = 'wedding_ring',     min = 1, max = 1, weight = 6  }, -- มีอยู่แล้วใน DB
            { name = 'loot_gold_tooth',  min = 1, max = 1, weight = 1  }, -- แทน gold_bar (ไม่มีใน DB) รางวัลหายาก — ฟันทอง
        },
    },
}
