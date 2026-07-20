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

-- ── กันเหยื่อหายฟรีระหว่างตกปลา ──────────────────────────────────────────────
-- สกรอลล์เมาส์ใน RedM คือปุ่มสลับอาวุธ (อ้างอิง jo_libs/modules/camera/client.lua)
-- ไม่ใช่ปุ่มเคอร์เซอร์ — เผลอสกรอลล์ระหว่างตกปลาจะเปิด weapon wheel แล้วเกมเก็บ
-- เบ็ดให้เอง จบการตกปลาโดยที่เหยื่อถูกหักไปแล้ว
Config.FishingGuard = {
    Enabled = true,

    -- ไม่ปิด INPUT_TOGGLE_HOLSTER เพราะเป็นปุ่มเลิกตกปลาโดยตั้งใจ
    BlockControls = {
        'INPUT_OPEN_WHEEL_MENU',
        'INPUT_SELECT_NEXT_WEAPON',
        'INPUT_SELECT_PREV_WEAPON',
    },
    -- state ที่ถือว่า "กำลังตกปลาอยู่" (3 = ท่าง้าง, 13 = ตอนหยิบเบ็ด)
    BlockDuringStates = { 1, 2, 3, 6, 7, 12, 13 },
}

-- /fishdump (ดูค่า struct) และ /fishwatch (ตามดู state) ไว้ debug ตอนทดสอบ
Config.DebugCommands = true

-- ปลากินเบ็ดแล้วได้ 100% — ปิดเงื่อนไข "เอ็นขาด" ตอนสู้กับปลา (state 7)
-- true  = สาวแรงเกินไปเอ็นก็ไม่ขาด ยังไงก็ได้ปลา (ยังกดยกเลิกเองได้อยู่)
-- false = ใช้กติกาเดิมของเกม เอ็นขาดถ้าแรงเกิน MaxFishForce
Config.GuaranteedCatch = true
Config.MaxFishForce    = 1.4   -- แรงที่ทำให้เอ็นขาด (มีผลเมื่อ GuaranteedCatch = false)
