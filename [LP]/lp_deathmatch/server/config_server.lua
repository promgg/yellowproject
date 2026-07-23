-- server-only config — ไม่ผ่าน shared_scripts จึงไม่ถูกส่งไปฝั่ง client เลย
-- (ตารางเวลา/รางวัล/ระยะตรวจสอบ ไม่มีเหตุผลที่ client ต้องรู้ล่วงหน้า)

-- ── เมืองที่เข้าร่วม — ต้องตรงกับ id ใน nx_cityselect ทุกตัวอักษร ──
Config.Cities = {
    { id = 'valentine', code = 'VLT', label = 'เมืองวาเลนไทน์' },
    { id = 'rhodes',    code = 'RHD', label = 'เมืองโรดส์' },
    { id = 'annesburg', code = 'ANB', label = 'เมืองแอนเนสบูร์ก' },
}

-- ── ตารางเวลา — ซ้ำทุกวัน เริ่มครั้งเดียวต่อวันเมื่อถึงเวลานี้ ──
Config.Schedule = {
    enabled = true,
    startHour = 20,
    startMinute = 0,
    durationMinutes = 20,
    -- ช่วงผ่อนผันหลังเวลาเริ่ม (นาที) — เซิร์ฟที่บูตอยู่จะจับได้ในรอบ poll ถัดไป (ทุก 30 วิ)
    -- ส่วนเซิร์ฟที่รีสตาร์ทหลังพ้นช่วงนี้ไปแล้วจะไม่จัดอีเว้นท์ย้อนหลัง
    graceMinutes = 10,
}

Config.Security = {
    maxRequestsPerMinute = 20,
    suspiciousRequestThreshold = 8,
    -- ระยะสูงสุดระหว่างผู้ฆ่า-เหยื่อที่ยอมรับได้ (กันรายงานเท็จข้ามแมพ) เผื่อ latency/กระสุนปืนระยะไกลไว้พอสมควร
    maxKillDistance = 80.0,
    -- คูลดาวน์ต่อคู่ผู้ฆ่า-เหยื่อ กันสองคนนัดกันผลัดกันตายฟาร์มแต้มไม่อั้น
    pairCooldownMinutes = 0,
    adminAce = 'lp_deathmatch.admin',
    adminGroups = { 'admin', 'superadmin' },
}

-- ── สาเหตุการตายที่ "ไม่" นับแต้ม ──
--
-- เดิมตรงนี้เช็คด้วย GetWeapontypeGroup() ซึ่งเป็น native ฝั่ง client เท่านั้น เรียกจาก server
-- ไม่ได้ (ตัวแปรเป็น nil -> pcall คืน false -> ทุกคิลตกด่าน weapon_not_allowed) อีก 3 ที่ใน
-- โปรเจกต์ที่เรียก native ตัวนี้อยู่ใน client/ ทั้งหมด — vorp_cleangun, vorp_inventory x2
--
-- เปลี่ยนมาเป็น denylist ด้วย hash ตรงๆ แทน: joaat ใช้ได้ทั้งสองฝั่ง ไม่พึ่ง native ของเกม
-- กลับด้านจาก allowlist เพราะ RDR3 มีอาวุธเยอะและเพิ่มเรื่อยๆ การไล่แบนสิ่งที่ "ไม่ใช่การต่อสู้"
-- สั้นและพลาดยากกว่าการไล่อนุญาตอาวุธทุกชิ้น
--
-- ปลอดภัยที่จะใส่ชื่อเผื่อไว้: ถ้าชื่อไหนไม่มีจริงใน RDR3 joaat จะได้ hash ที่ไม่ตรงกับอะไรเลย
-- = ไม่มีผลข้างเคียง ไม่ error
--
-- ด่านนี้ไม่ได้ทำงานลำพัง — ผู้ฆ่าต้องเป็นผู้เล่นที่ออนไลน์จริงและไม่ใช่ตัวเอง (ตายเองจาก
-- สิ่งแวดล้อมได้ killerServerId = 0 ตกตั้งแต่ด่านแรก) บวกระยะ ≤80m + คูลดาวน์คู่ + ต้องคนละเมือง
Config.DeniedDeathCauses = {
    'WEAPON_UNARMED',
    'WEAPON_FALL',
    'WEAPON_DROWNING',
    'WEAPON_DROWNING_IN_VEHICLE',
    'WEAPON_FIRE',
    'WEAPON_EXPLOSION',
    'WEAPON_RAMMED_BY_CAR',
    'WEAPON_RUN_OVER_BY_CAR',
    'WEAPON_ANIMAL',
}

-- ── รางวัลตามอันดับ — ตั๋วกาชาโปรโมทเซิร์ฟเท่านั้น (ไม่มีเงิน/ไอเทมอื่นแล้ว) ──
-- เสมอกัน = ได้เต็มจำนวนทุกเมืองที่เสมอ (ตั๋วแบ่งเป็นเศษไม่ได้ ต่างจากเงินที่หารได้)
Config.Rewards = {
    first = {
        money = { enabled = false, min = 0, max = 0, currency = 0 },
        items = {
            { name = 'gacha_promo', min = 10, max = 10 },
        },
    },
    second = {
        money = { enabled = false, min = 0, max = 0, currency = 0 },
        items = {
            { name = 'gacha_promo', min = 5, max = 5 },
        },
    },
    third = {
        money = { enabled = false, min = 0, max = 0, currency = 0 },
        items = {
            { name = 'gacha_promo', min = 3, max = 3 },
        },
    },
}

Config.Logging = {
    console = true,
    database = false,
}
