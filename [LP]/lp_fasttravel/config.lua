Config = {}

-- ─── ปุ่มเปิดเมนู (lp_textui:TextUIHold ที่แต่ละสถานี) ────────────────────
Config.Key           = 0x17BEC168 -- ปุ่ม E (ค่า default ของ lp_textui เอง)
Config.HoldTime      = 1200       -- มิลลิวินาที ต้องกดค้างเท่านี้ถึงจะเปิดเมนู
Config.TriggerRadius = 3.0        -- ระยะที่ต้องเข้าใกล้สถานีถึงจะขึ้น hint

-- ─── Cooldown ระหว่างการ fast travel แต่ละครั้ง (กันสแปม) ──────────────────
Config.Cooldown = 10 -- วินาที

-- ─── ราคาต่อกิโลเมตร (ระยะจริงจากพิกัดผู้เล่นถึงสถานี หาร 1000 = 1 กม.) ────
-- ปัดเศษเป็นจำนวนเต็ม ตั้งราคาคงที่เฉพาะสถานีได้ผ่าน priceOverride ด้านล่าง
Config.PricePerKm = 5

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
--
-- ⚠️ `coords` กับ `arrival` คนละหน้าที่กัน แยกกันโดยตั้งใจ:
--    coords  = จุดยืนของ NPC / ตำแหน่ง blip / รัศมีที่กด E เปิดเมนู / ระยะที่ใช้คิดราคา
--    arrival = จุดที่วาร์ปคนไปโผล่จริง
--    เดิมใช้ coords ทำทั้งสองอย่าง คนเลยวาร์ปไปโผล่ทับตัว NPC พอดี
--    arrival เป็นพิกัดที่เดินเก็บจากในเกมจริง ห่างจาก NPC 2.8-16.9 ม. (Annesburg ไกลสุด)
--    ทุกจุดยังอยู่ในรัศมี CurrentStationRadius (50 ม.) จึงยังนับเป็น "สถานีปัจจุบัน" หลังวาร์ปถึง
--
-- `airdropTeam` = id ทีมใน lp_airdropteam/config.lua -> Config.Team.teams
--    สถานีที่ใส่ค่านี้จะมีปุ่มเข้าร่วมแอร์ดรอปโผล่ในเมนู (เข้าได้เฉพาะทีมของสถานีนั้น)
--    เว้นเป็น nil = ไม่มีปุ่ม (Emerald / Riggs ไม่มีทีมของตัวเอง)
Config.Stations = {
    {
        id            = 'valentine',
        name          = 'Valentine',
        description   = 'เมืองปศุสัตว์คึกคักแห่งนิวแฮนโนเวอร์ ศูนย์กลางการค้าและปศุสัตว์',
        image         = 'https://i.postimg.cc/bwV6My61/vlt.webp', -- ใส่ path/URL รูปได้ทีหลัง เช่น 'img/valentine.png'
        color         = '#b0453d',
        coords        = vector3(-178.0618, 627.9431, 114.0896),
        heading       = 154.0,
        arrival       = vector3(-171.9251, 625.1652, 114.0820),
        arrivalHeading = 232.9141,
        airdropTeam   = 'A',
        priceOverride = nil, -- ใส่ตัวเลขถ้าอยากตั้งราคาคงที่แทนสูตรระยะทาง
        jobsEnabled   = false,
        jobs          = { -- ex. { name = 'conductor', grade = 0 }
        },
    },
    {
        id            = 'emerald',
        name          = 'Emerald Ranch',
        description   = 'ฟาร์มปศุสัตว์เล็กๆ ริมทะเลสาบ Owanjila',
        image         = 'https://i.postimg.cc/fRqHFzHj/emr.webp', -- ใส่ path/URL รูปได้ทีหลัง เช่น 'img/valentine.png'
        color         = '#4d7ab5',
        coords        = vector3(1523.6372, 442.5369, 90.6785),
        heading       = -89.1400,
        arrival       = vector3(1526.3903, 442.3490, 90.7299),
        arrivalHeading = 320.5089,
        priceOverride = nil,
        jobsEnabled   = false,
        jobs          = {},
    },
    {
        id            = 'rhodes',
        name          = 'Rhodes',
        description   = 'เมืองทางใต้แห่งเลมอยน์ ดินแดนของเกียรติยศและกฎหมาย',
        image         = 'https://i.postimg.cc/rwZhbVhG/RHD.webp', -- ใส่ path/URL รูปได้ทีหลัง เช่น 'img/valentine.png'
        color         = '#4d9e5c',
        coords        = vector3(1230.2825, -1298.4816, 76.9543),
        heading       = -135.1912,
        arrival       = vector3(1225.6819, -1303.8241, 76.9526),
        arrivalHeading = 152.1019,
        airdropTeam   = 'B',
        priceOverride = nil,
        jobsEnabled   = false,
        jobs          = {},
    },
    {
        id            = 'annesburg',
        name          = 'Annesburg',
        description   = 'เมืองเหมืองถ่านหินทางตะวันออกของนิวแฮนโนเวอร์ ริม Roanoke Ridge',
        image         = 'https://i.postimg.cc/J4MHwjgg/anb.webp', -- ใส่ path/URL รูปได้ทีหลัง เช่น 'img/valentine.png'
        color         = '#8a5ac2',
        coords        = vector3(2930.8950, 1274.2233, 44.7028),
        heading       = 5.9054,
        arrival       = vector3(2947.0688, 1278.9983, 44.6819),
        arrivalHeading = 236.9577,
        airdropTeam   = 'C',
        priceOverride = nil,
        jobsEnabled   = false,
        jobs          = {},
    },
    {
        id            = 'riggs',
        name          = 'Riggs Station',
        description   = 'ป้ายรถไฟกลางทะเลทรายเวสต์เอลิซาเบธ',
        image         = 'https://i.postimg.cc/SNkY0c5B/RIG.webp', -- ใส่ path/URL รูปได้ทีหลัง เช่น 'img/valentine.png'
        color         = '#030303',
        coords        = vector3(-1094.4144, -577.5806, 82.4100),
        heading       = 63.3,
        arrival       = vector3(-1097.5092, -579.7670, 82.4579),
        arrivalHeading = 141.2697,
        priceOverride = nil,
        jobsEnabled   = false,
        jobs          = {},
    },
}
