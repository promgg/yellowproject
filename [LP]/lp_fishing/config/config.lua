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
-- ปิดไว้ — ผู้เล่นหยิบ WEAPON_FISHINGROD จาก weapon wheel เองได้อยู่แล้ว
--
-- อย่าลบตารางนี้ทิ้ง: WaterRange ยังถูกใช้โดย isNearWater() ซึ่งโหมดง่ายเรียกอยู่
-- ปิดแค่ Enabled ก็พอ ตัว thread จะ return ออกไปเลยไม่กินอะไร
Config.StartPrompt = {
    Enabled   = false,
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

-- ── โหมดผสม (แนะนำ) ────────────────────────────────────────────────────────
-- ปล่อยให้ native task ของเกมทำงานเต็มทุกอย่าง — เส้นเอ็น ทุ่น ท่าเหวี่ยง ท่าดึง
-- ท่าถือปลา ครบของจริง ผู้เล่นเหวี่ยงเองตามปกติ (คลิกขวา แล้วคลิกซ้ายค้าง ปล่อย)
--
-- ตัดออกอย่างเดียวคือ "การสู้กับปลา" ของเกม (state 7) เปลี่ยนเป็น lp_minigame แทน
--   ผ่าน   -> flag 12 = ได้ปลา เกมเล่นท่าดึงขึ้นให้เอง แล้วเข้าเส้นทางแจกของเดิม
--   ไม่ผ่าน -> flag 11 = เอ็นขาด ปลาหลุด
-- (flag 11/12 เป็นค่าที่โค้ดเดิมของเกมใช้อยู่แล้ว ไม่ได้เดาเอง)
--
-- อย่าเปิดพร้อม Config.SimpleMode.Enabled — เลือกอย่างใดอย่างหนึ่ง
Config.HybridMinigame = {
    Enabled = true,

    -- ส่งต่อให้ exports.lp_minigame:Fishing() — ดู lp_minigame/config.lua
    Minigame = {
        duration = 12000,
        zoneSize = 15,
    },

    FailMsg = 'ปลาหลุด!',
}

-- ── โหมดง่าย (แยกจากมินิเกมของเกม) ──────────────────────────────────────────
-- Enabled = true  -> ปิดมินิเกมของเกมทั้งหมด ใช้ flow นี้แทน:
--                   ถือเบ็ด -> ใส่เหยื่อ -> กด E -> เบ็ดพุ่งไปหาปลาที่เหยื่อล่อได้
--                   -> รอปลากิน -> เล่น lp_minigame -> ผ่าน = ได้ปลา / ไม่ผ่าน = ปลาหลุด
-- Enabled = false -> ใช้มินิเกมของเกมตามเดิม (ค่าเริ่มต้น)
--
-- ปลาที่จับได้เป็น entity จริงในน้ำเหมือนโหมดปกติ ไม่ได้สุ่มจากตาราง
-- server ยังตรวจทุกอย่างเหมือนเดิม (playersFishing + entity มีจริง + canCarryItem)
Config.SimpleMode = {
    Enabled = false,

    Key        = 'INPUT_CONTEXT',       -- E
    PromptText = 'เหวี่ยงเบ็ด',
    HoldMs     = 200,

    -- รัศมีที่ค้นหาปลา — ต้องเป็นปลาที่เหยื่อชิ้นนี้ล่อได้เท่านั้น (BaitsPerFish)
    SearchRadius = 60.0,
    NoFishMsg    = 'แถวนี้ไม่มีปลาที่เหยื่อนี้ล่อได้',

    -- รอปลากินเหยื่อ (สุ่มระหว่างสองค่านี้)
    BiteDelayMin = 3000,
    BiteDelayMax = 8000,
    WaitLabel    = 'รอปลากินเหยื่อ...',

    -- ส่งต่อให้ exports.lp_minigame:Fishing() — ดู lp_minigame/config.lua
    Minigame = {
        duration = 12000,
        zoneSize = 15,
    },

    FailMsg = 'ปลาหลุด! เหยื่อหายไปด้วย',

    -- ลากตัวปลาจริงเข้ามาหาผู้เล่นตอนดึงขึ้น — native task ไม่ได้ทำงานในโหมดนี้
    -- เลยไม่มีใครลากปลาให้ ถ้าไม่ทำจะเห็นคนดึงเบ็ดบนอากาศเปล่าๆ
    ReelIn = {
        Enabled  = true,
        Distance = 1.2,   -- ปลาหยุดห่างจากตัวผู้เล่นกี่เมตร
        Height   = 0.6,   -- สูงจากเท้าเท่าไหร่ (ระดับอก)
    },

    -- ── อนิเมชัน ────────────────────────────────────────────────────────────
    -- โหมดปกติไม่ต้องตั้งค่าพวกนี้เพราะ native fishing task ของเกมเล่นท่าให้เอง
    -- (vorp_fishing ไม่มีโค้ดเล่น anim เลยสักบรรทัด) แต่โหมดง่ายไม่ได้สตาร์ท task
    -- เลยต้องเล่นเอง — ชื่อ dict/clip ด้านล่างมาจาก megadictanims ของ femga/rdr3_discoveries
    --
    -- clip อื่นที่มีให้เลือกใน dict เดียวกัน (เผื่ออยากเปลี่ยนมุม/ท่า):
    --   primed_sweep / cast_sweep : aim_med_0 | aim_med_l90 | aim_med_r90
    --                               release_med_0 | release_med_l90 | release_med_r90
    --   relaxed@idle              : idle_a_med_0 .. idle_f_med_0
    --   hooked_med@struggle       : struggle_a | struggle_pullup
    Anims = {
        Enabled = true,

        WindUp = { dict = 'mini_games@fishing@shore@primed_sweep',        clip = 'aim_med_0',       ms = 800 },
        Cast   = { dict = 'mini_games@fishing@shore@cast_sweep',          clip = 'release_med_0',   ms = 1000 },
        Wait   = { dict = 'mini_games@fishing@shore@relaxed@idle',        clip = 'idle_a_med_0',    loop = true },
        Fight  = { dict = 'mini_games@fishing@shore@hooked_med@struggle', clip = 'struggle_a',      loop = true },
        -- เกมไม่มี dict "ถือปลา" แยก — struggle_pullup คือท่าดึงปลาขึ้นมา ใกล้เคียงที่สุด
        Land   = { dict = 'mini_games@fishing@shore@hooked_med@struggle', clip = 'struggle_pullup', ms = 1500 },
    },
}

-- ปลากินเบ็ดแล้วได้ 100% — ปิดเงื่อนไข "เอ็นขาด" ตอนสู้กับปลา (state 7)
-- true  = สาวแรงเกินไปเอ็นก็ไม่ขาด ยังไงก็ได้ปลา (ยังกดยกเลิกเองได้อยู่)
-- false = ใช้กติกาเดิมของเกม เอ็นขาดถ้าแรงเกิน MaxFishForce
Config.GuaranteedCatch = true
Config.MaxFishForce    = 1.4   -- แรงที่ทำให้เอ็นขาด (มีผลเมื่อ GuaranteedCatch = false)

-- ── เขตห้ามตกปลา (โซนรอบไร่ปลูกผัก) ──────────────────────────────────────────
-- อยู่ในรัศมีของโซนพวกนี้ = prompt "เริ่มตกปลา" ไม่ขึ้น และเริ่มตกไม่ได้
-- radius หน่วยเมตร (วัดในระนาบ x/y ไม่สนความสูง) เพิ่ม/ลดจุดได้ตามต้องการ
Config.NoFishZones = {
    { label = 'ไร่ Rhodes',    coords = vector3(967.7547, -1938.8070, 46.7184), radius = 35.0 },
    { label = 'ไร่ (จุดที่ 2)', coords = vector3(859.0538, -1595.8829, 43.4967), radius = 35.0 },
}
