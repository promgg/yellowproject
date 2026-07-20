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
-- วิธีทำงาน: native เป็นคนเหวี่ยงเองตอนผู้เล่นคลิกซ้าย (prompt "Cast Fishing Rod"
-- ของเกมเอง) เราแค่เซ็ต f_1 (ระยะเหวี่ยงสูงสุด) = ระยะถึง marker ก่อนคลิก แล้วยึด
-- ค่านั้นไว้ระหว่างที่เบ็ดลอยออกไป — ไม่ปลอม input ไม่แตะ physics
Config.AimMode = {
    Enabled = true,

    -- ชื่อ control ของ RDR2 — ถ้าปุ่มไหนไม่ทำงานตอนทดสอบ เปลี่ยนชื่อตรงนี้ได้เลย
    ToggleControl     = 'INPUT_AIM',                  -- คลิกขวา: เข้า/ออกโหมด
    -- คลิกซ้าย: เหวี่ยง — ตรงกับ prompt "Cast Fishing Rod" ของเกมเอง
    -- (native เป็นคนเหวี่ยงจริง เราแค่ตั้งระยะให้ก่อน ไม่ได้ปลอม input)
    CastControl       = 'INPUT_ATTACK',
    CancelControl     = 'INPUT_FRONTEND_CANCEL',      -- ESC: ออกโหมด
    -- สกรอลล์เมาส์ใน RedM = ปุ่มสลับอาวุธ ไม่ใช่ INPUT_CURSOR_SCROLL_*
    -- (อ้างอิง jo_libs/modules/camera/client.lua ที่ระบุ mapping นี้ไว้)
    ScrollUpControl   = 'INPUT_SELECT_PREV_WEAPON',   -- สกรอลล์ขึ้น: ไกลขึ้น
    ScrollDownControl = 'INPUT_SELECT_NEXT_WEAPON',   -- สกรอลล์ลง: ใกล้ขึ้น

    ScrollStep = 1.5,   -- สกรอลล์ 1 คลิก = กี่เมตร

    -- ปุ่มที่ต้องปิดตลอดช่วงตกปลา — เพราะสกรอลล์/weapon wheel ทำให้เกมเก็บเบ็ดเอง
    -- แล้วเหยื่อที่หักไปแล้วหายฟรี (ไม่ปิด INPUT_TOGGLE_HOLSTER เพราะเป็นปุ่มเลิกตกปลาโดยตั้งใจ)
    BlockControls = {
        'INPUT_OPEN_WHEEL_MENU',
        'INPUT_SELECT_NEXT_WEAPON',
        'INPUT_SELECT_PREV_WEAPON',
    },
    -- state ที่ถือว่า "กำลังตกปลาอยู่" และต้องปิดปุ่มข้างบน (13 = ช่วงเบ็ดกำลังออก)
    BlockDuringStates = { 1, 2, 6, 7, 12, 13 },

    -- หน่วงก่อนรับปุ่ม toggle อีกครั้ง กันเคสกดคลิกขวาค้างแล้วเด้งออกจากโหมดทันที
    ToggleCooldownMs = 250,

    -- state ที่ถือว่า "เบ็ดกำลังลอยออกไป" — ต้องเขียน f_1 ซ้ำทุกเฟรมกันเกมคำนวณทับ
    -- /fishwatch พบว่าเกมใช้ 13 ไม่ใช่ 2 (เก็บ 2 ไว้เผื่อบางเคส)
    HoldDuringStates = { 2, 13 },
    HoldMaxDistMs    = 1500,   -- ยึดนานสุดกี่ ms

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
