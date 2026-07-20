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

-- marker จุดตกตอนเล็ง — หน้าตาของวงกลมที่วาดบนผิวน้ำ
Config.CastMarker = {
    Enabled = true,

    -- ช่วงระยะที่สกรอลล์ปรับได้
    MinDistance = 4.0,
    MaxDistance = 0.0,     -- 0 = ใช้ค่าจากเกม (f_1 ที่อ่านตอนเข้าโหมดเล็ง)
    FallbackMax = 30.0,    -- ใช้เมื่อเกมไม่คืนค่าระยะสูงสุด

    -- หน้าตา marker
    Type  = 0x07DCE236,    -- วงกลมแบนบนพื้น
    Scale = { x = 1.2, y = 1.2, z = 0.6 },

    OverWater = { r = 90,  g = 200, b = 255, a = 150 },  -- เล็งโดนน้ำ = เหวี่ยงได้
    NoWater   = { r = 210, g = 70,  b = 60,  a = 110 },  -- เล็งโดนพื้น = เหวี่ยงไม่ออก
    ShowNoWater = true,
}

-- ── โหมดเล็งเหวี่ยงเบ็ด ─────────────────────────────────────────────────────
-- คลิกขวา 1 ครั้ง = เข้า/ออกโหมดเล็ง | เมาส์ = ทิศ | สกรอลล์ = ระยะ | E = เหวี่ยง
--
-- วิธีทำงาน: ไม่ได้เทเลพอร์ตเบ็ด แต่เซ็ต f_1 (ระยะเหวี่ยงสูงสุด) ให้เท่ากับระยะถึง
-- marker แล้ว "ง้างแทนผู้เล่น" ด้วย SetControlValueNextFrame — พอง้างเต็มก็เท่ากับ
-- ลงตรง marker พอดี โดยที่ physics ของเกมยังทำงานปกติ
Config.AimMode = {
    Enabled = true,

    -- ชื่อ control ของ RDR2 — ถ้าปุ่มไหนไม่ทำงานตอนทดสอบ เปลี่ยนชื่อตรงนี้ได้เลย
    ToggleControl     = 'INPUT_AIM',                -- คลิกขวา: เข้า/ออกโหมด
    CastControl       = 'INPUT_CONTEXT',            -- E: เหวี่ยง
    CancelControl     = 'INPUT_FRONTEND_CANCEL',    -- ESC: ออกโหมด
    ScrollUpControl   = 'INPUT_CURSOR_SCROLL_UP',   -- สกรอลล์ขึ้น: ไกลขึ้น
    ScrollDownControl = 'INPUT_CURSOR_SCROLL_DOWN', -- สกรอลล์ลง: ใกล้ขึ้น

    ScrollStep = 1.5,   -- สกรอลล์ 1 คลิก = กี่เมตร

    -- หน่วงก่อนรับปุ่ม toggle อีกครั้ง กันเคสกดคลิกขวาค้างแล้วเด้งออกจากโหมดทันที
    ToggleCooldownMs = 250,

    -- ลำดับป้อน input ปลอมตอนเหวี่ยง
    -- ChargeFrames คือหัวใจ: ป้อน INPUT_AIM กี่เฟรมถึงจะง้างเต็ม
    -- ถ้าเบ็ดออกไปไม่สุด = เพิ่มค่านี้ / ถ้ารอนานเกินไป = ลดลง
    ChargeFrames  = 30,
    ReleaseFrames = 3,

    -- หลังปล่อยเบ็ด ยึด f_1 ไว้นานสุดกี่ ms ระหว่างที่ยังอยู่ state 2
    -- (เกมคำนวณ f_1 ใหม่ตอนเข้า state 2 ถ้าไม่เขียนซ้ำค่าเราจะโดนทับ)
    HoldMaxDistMs = 1500,

    -- เส้นโค้งบอกทางเหวี่ยง
    ShowArc     = true,
    ArcSegments = 14,
    ArcHeight   = 0.25,   -- ความสูงโค้งเทียบกับระยะ (0.25 = สูงสุด 1/4 ของระยะ)
    ArcColor    = { r = 235, g = 200, b = 120, a = 200 },

    ShowDistanceText = true,
    BlockedMsg = 'ต้องเล็งลงน้ำก่อนถึงจะเหวี่ยงได้',

    -- เปิด /fishdump และ /fishflag ไว้ไล่หาค่าตอนทดสอบ
    DebugCommands = true,
}

-- ปลากินเบ็ดแล้วได้ 100% — ปิดเงื่อนไข "เอ็นขาด" ตอนสู้กับปลา (state 7)
-- true  = สาวแรงเกินไปเอ็นก็ไม่ขาด ยังไงก็ได้ปลา (ยังกดยกเลิกเองได้อยู่)
-- false = ใช้กติกาเดิมของเกม เอ็นขาดถ้าแรงเกิน MaxFishForce
Config.GuaranteedCatch = true
Config.MaxFishForce    = 1.4   -- แรงที่ทำให้เอ็นขาด (มีผลเมื่อ GuaranteedCatch = false)
