Config = {}

-- ─── ปุ่มเปิดเมนู (lp_textui:TextUIHold ที่แต่ละสถานี) ────────────────────
Config.Key           = 0x17BEC168 -- ปุ่ม E (ค่า default ของ lp_textui เอง)
Config.HoldTime      = 1200       -- มิลลิวินาที ต้องกดค้างเท่านี้ถึงจะเปิดเมนู
Config.TriggerRadius = 3.0        -- ระยะที่ต้องเข้าใกล้สถานีถึงจะขึ้น hint

-- ─── Cooldown ระหว่างการ fast travel แต่ละครั้ง (กันสแปม) ──────────────────
Config.Cooldown = 10 -- วินาที

-- ─── ราคาต่อกิโลเมตร (ระยะจริงจากพิกัดผู้เล่นถึงสถานี หาร 1000 = 1 กม.) ────
-- ปัดเศษเป็นจำนวนเต็ม ตั้งราคาคงที่เฉพาะสถานีได้ผ่าน priceOverride ด้านล่าง
Config.PricePerKm = 2

-- ─── ระยะที่ถือว่าผู้เล่น "อยู่สถานีนี้แล้ว" (ขึ้น "สถานีปัจจุบัน" แทนปุ่ม Confirm) ──
Config.CurrentStationRadius = 50.0

-- ─── หลอดโหลดก่อน/หลังวาร์ป (lp_progbar) กันตกแมพ ระหว่างรอ collision โหลด ──
Config.ProgressBar = {
    before = { duration = 800,  label = "กำลังเตรียมตัวเดินทาง..." },
    after  = { duration = 2500, label = "กำลังเดินทาง..." },
}

-- ─── NPC ผู้ช่วยเดินทาง (standalone: spawn เอง ไม่พึ่ง NPC ของ bcc-train) ──────
-- pattern เดียวกับ bcc-train/client/blips_npc.lua (AddNPC/RemoveNPC) แค่แยกเป็น resource ของตัวเอง
Config.NPC = {
    model         = 's_m_m_sdticketseller_01',
    spawnDistance = 100.0, -- spawn เฉพาะตอนผู้เล่นเข้ามาในระยะนี้ (perf)
}

-- ─── Blip บนแผนที่ต่อสถานี (แยกจาก blip ของ bcc-train เอง) ───────────────────
Config.Blip = {
    sprite = -250506368, -- hash ที่ยืนยันแล้วว่าโชว์ได้จริงใน RDR3 (ใช้ซ้ำทั้งโปรเจกต์)
    color  = 'BRIGHT_BLUE',
}

-- คัดลอกมาจาก bcc-train/configs/config.lua เพื่อใช้ BlipAddModifier (native เดียวกัน)
Config.BlipColors = {
    LIGHT_BLUE    = 'BLIP_MODIFIER_MP_COLOR_1',
    DARK_RED      = 'BLIP_MODIFIER_MP_COLOR_2',
    PURPLE        = 'BLIP_MODIFIER_MP_COLOR_3',
    ORANGE        = 'BLIP_MODIFIER_MP_COLOR_4',
    TEAL          = 'BLIP_MODIFIER_MP_COLOR_5',
    LIGHT_YELLOW  = 'BLIP_MODIFIER_MP_COLOR_6',
    PINK          = 'BLIP_MODIFIER_MP_COLOR_7',
    GREEN         = 'BLIP_MODIFIER_MP_COLOR_8',
    DARK_TEAL     = 'BLIP_MODIFIER_MP_COLOR_9',
    RED           = 'BLIP_MODIFIER_MP_COLOR_10',
    LIGHT_GREEN   = 'BLIP_MODIFIER_MP_COLOR_11',
    TEAL2         = 'BLIP_MODIFIER_MP_COLOR_12',
    BLUE          = 'BLIP_MODIFIER_MP_COLOR_13',
    DARK_PUPLE    = 'BLIP_MODIFIER_MP_COLOR_14',
    DARK_PINK     = 'BLIP_MODIFIER_MP_COLOR_15',
    DARK_DARK_RED = 'BLIP_MODIFIER_MP_COLOR_16',
    GRAY          = 'BLIP_MODIFIER_MP_COLOR_17',
    PINKISH       = 'BLIP_MODIFIER_MP_COLOR_18',
    YELLOW_GREEN  = 'BLIP_MODIFIER_MP_COLOR_19',
    DARK_GREEN    = 'BLIP_MODIFIER_MP_COLOR_20',
    BRIGHT_BLUE   = 'BLIP_MODIFIER_MP_COLOR_21',
    BRIGHT_PURPLE = 'BLIP_MODIFIER_MP_COLOR_22',
    YELLOW_ORANGE = 'BLIP_MODIFIER_MP_COLOR_23',
    BLUE2         = 'BLIP_MODIFIER_MP_COLOR_24',
    TEAL3         = 'BLIP_MODIFIER_MP_COLOR_25',
    TAN           = 'BLIP_MODIFIER_MP_COLOR_26',
    OFF_WHITE     = 'BLIP_MODIFIER_MP_COLOR_27',
    LIGHT_YELLOW2 = 'BLIP_MODIFIER_MP_COLOR_28',
    LIGHT_PINK    = 'BLIP_MODIFIER_MP_COLOR_29',
    LIGHT_RED     = 'BLIP_MODIFIER_MP_COLOR_30',
    LIGHT_YELLOW3 = 'BLIP_MODIFIER_MP_COLOR_31',
    WHITE         = 'BLIP_MODIFIER_MP_COLOR_32',
}

-- ─── สถานี ─────────────────────────────────────────────────────────────────
-- พิกัดอ้างอิงจาก [BCC]/bcc-train/configs/stations.lua -> npc.coords (จุดขายตั๋ว)
-- ใช้พิกัด NPC แทน train.coords เพราะพิกัดรถไฟอยู่บนราง ไม่ปลอดภัยที่จะวาร์ปคนไปยืน
Config.Stations = {
    {
        id            = 'valentine',
        name          = 'Valentine',
        description   = 'เมืองปศุสัตว์คึกคักแห่งนิวแฮนโนเวอร์ ศูนย์กลางการค้าและปศุสัตว์',
        image         = '', -- ใส่ path/URL รูปได้ทีหลัง เช่น 'img/valentine.png'
        color         = '#b0453d',
        coords        = vector3(-172.9, 629.79, 114.03),
        heading       = 228.81,
        priceOverride = nil, -- ใส่ตัวเลขถ้าอยากตั้งราคาคงที่แทนสูตรระยะทาง
        jobsEnabled   = false,
        jobs          = { -- ex. { name = 'conductor', grade = 0 }
        },
    },
    {
        id            = 'emerald',
        name          = 'Emerald Ranch',
        description   = 'ฟาร์มปศุสัตว์เล็กๆ ริมทะเลสาบ Owanjila',
        image         = '',
        color         = '#4d7ab5',
        coords        = vector3(1525.18, 442.51, 90.68),
        heading       = 270.86,
        priceOverride = nil,
        jobsEnabled   = false,
        jobs          = {},
    },
    {
        id            = 'rhodes',
        name          = 'Rhodes',
        description   = 'เมืองทางใต้แห่งเลมอยน์ ดินแดนของเกียรติยศและกฎหมาย',
        image         = '',
        color         = '#4d9e5c',
        coords        = vector3(1227.89, -1300.21, 76.91),
        heading       = 135.87,
        priceOverride = nil,
        jobsEnabled   = false,
        jobs          = {},
    },
    {
        id            = 'annesburg',
        name          = 'Annesburg',
        description   = 'เมืองเหมืองถ่านหินทางตะวันออกของนิวแฮนโนเวอร์ ริม Roanoke Ridge',
        image         = '',
        color         = '#8a5ac2',
        coords        = vector3(2941.52, 1286.11, 44.64),
        heading       = 242.69,
        priceOverride = nil,
        jobsEnabled   = false,
        jobs          = {},
    },
    {
        id            = 'riggs',
        name          = 'Riggs Station',
        description   = 'ป้ายรถไฟกลางทะเลทรายเวสต์เอลิซาเบธ',
        image         = '',
        color         = '#c2953c',
        coords        = vector3(-1098.82, -575.78, 82.39),
        heading       = 168.87,
        priceOverride = nil,
        jobsEnabled   = false,
        jobs          = {},
    },
}
