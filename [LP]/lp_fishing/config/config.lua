Config = {}

Config.Debug = false

Config.Lang = 'English'
-- If you use -1 for testing the fish is very easy to catch --
Config.Difficulty = 1250

Config.ReelSpeed = 0.0125

-- web hook link is in the server.lua file
Config.DiscordIntegration = false -- enable logs

Config.DiscordBotName = "Vorp Fishing"

Config.DiscordAvatar = ""

Config.DiscordFooterLogo = ""

-- ── ส่วนที่เพิ่มสำหรับ lp_fishing ──────────────────────────────────────────
-- อาวุธเบ็ด (ต้องถืออยู่ในมือถึงจะตกได้) — เปลี่ยนจากไอเทม job_fishing_rod เดิมมาเป็นอาวุธจริง
-- เพราะมินิเกมของเกมต้องการ WEAPON_FISHINGROD จริงๆ ไม่ใช่แค่มีไอเทมในกระเป๋า
Config.RodWeapon = 'WEAPON_FISHINGROD'

-- prompt lp_textui ตอนยืนใกล้น้ำแต่ยังไม่ได้หยิบเบ็ด
Config.StartPrompt = {
    Enabled   = true,
    Text      = '[E] เริ่มตกปลา',
    HoldMs    = 500,   -- กด E ค้างกี่ ms
    -- ระยะที่ยิง probe ลงไปหาน้ำรอบตัว (เมตร) — ไกลกว่านี้ prompt จะโผล่ทั้งที่ยังไม่ถึงน้ำ
    WaterRange = 12.0,
    -- ความถี่ในการสแกนหาน้ำตอนยังไม่ได้ตกปลา (ms) — ไม่ต้องถี่ ประหยัด CPU
    ScanMs     = 500,
}

-- lp_progbar ตอนกำลังดึงปลาขึ้นมา (state 12 = ปลาติดเบ็ดแล้ว กำลังเก็บ)
Config.LandingBar = {
    Enabled  = true,
    Duration = 1500,
    Label    = 'กำลังเก็บปลา...',
}

-- marker พรีวิวจุดตกตอนง้างเบ็ด (คลิกขวาค้าง) — โชว์ว่าเบ็ดจะไปลงตรงไหนก่อนปล่อย
-- หมายเหตุ: ตัวเกมเป็นคนคำนวณจุดตกจริง marker นี้ "ประมาณ" จากทิศกล้อง + เวลาที่ง้างค้าง
-- ถ้าทดสอบแล้วจุดตกจริงเพี้ยนจาก marker ให้ปรับ ChargeTimeMs / MaxDistance ให้ตรงกับที่เห็น
Config.CastMarker = {
    Enabled = true,

    -- ระยะที่ marker วิ่งออกไปตามแรงง้าง
    MinDistance  = 4.0,     -- ง้างแป๊บเดียว
    MaxDistance  = 0.0,     -- 0 = ใช้ค่าจากเกม (FISHING_GET_MAX_THROWING_DISTANCE) ถ้าเกมคืนค่ามา
    FallbackMax  = 30.0,    -- ใช้เมื่อเกมยังไม่คืนค่าระยะสูงสุด
    ChargeTimeMs = 1200,    -- ง้างค้างกี่ ms ถึงจะเต็มแรง

    -- หน้าตา marker
    Type  = 0x07DCE236,     -- วงกลมแบนบนพื้น
    Scale = { x = 1.2, y = 1.2, z = 0.6 },

    -- สีตอนจุดนั้นเป็นน้ำ (เหวี่ยงได้)
    OverWater = { r = 90, g = 200, b = 255, a = 150 },
    -- สีตอนจุดนั้นไม่ใช่น้ำ (เหวี่ยงไปก็ไม่ได้ปลา) — ตั้ง Enabled ของ ShowNoWater = false ถ้าไม่อยากให้โชว์เลย
    NoWater   = { r = 210, g = 70,  b = 60,  a = 110 },
    ShowNoWater = true,
}

-- ปลากินเบ็ดแล้วได้ 100% — ปิดเงื่อนไข "เอ็นขาด" ตอนสู้กับปลา (state 7)
-- true  = สาวแรงเกินไปเอ็นก็ไม่ขาด ยังไงก็ได้ปลา (ยังกดยกเลิกเองได้อยู่)
-- false = ใช้กติกาเดิมของเกม เอ็นขาดถ้าแรงเกิน MaxFishForce
Config.GuaranteedCatch = true
Config.MaxFishForce    = 1.4   -- แรงที่ทำให้เอ็นขาด (มีผลเมื่อ GuaranteedCatch = false)
