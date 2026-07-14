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
}

Config.Security = {
    maxRequestsPerMinute = 20,
    suspiciousRequestThreshold = 8,
    -- ระยะสูงสุดระหว่างผู้ฆ่า-เหยื่อที่ยอมรับได้ (กันรายงานเท็จข้ามแมพ) เผื่อ latency/กระสุนปืนระยะไกลไว้พอสมควร
    maxKillDistance = 80.0,
    -- คูลดาวน์ต่อคู่ผู้ฆ่า-เหยื่อ กันสองคนนัดกันผลัดกันตายฟาร์มแต้มไม่อั้น
    pairCooldownMinutes = 10,
    adminAce = 'lp_deathmatch.admin',
    adminGroups = { 'admin', 'superadmin' },
}

-- ── อาวุธที่นับแต้มได้ — ปืน/มีด/ระเบิด เท่านั้น ไม่นับรถชน (รถชนไม่ได้อยู่ในกลุ่มไหนเลยด้านล่าง จึงตกไปเอง) ──
-- ตรวจผ่าน native GetWeapontypeGroup(weaponHash) แทนไล่ชื่ออาวุธทีละตัว (ครอบคลุมกว่า ไม่ต้องอัปเดตทุกครั้งที่เพิ่มอาวุธใหม่)
-- หมายเหตุ: ชื่อกลุ่ม/hash ด้านล่างอ้างอิงจากรูปแบบ WEAPONTYPE_GROUP_* ของ RDR3 — ยังไม่ได้ทดสอบกับ native จริงในเกม
-- ถ้าเจอกรณีนับแต้มผิด (เช่น มีดไม่นับ, หรือชกมือเปล่ากลับนับ) ให้ปรับ allowedGroups/deniedWeapons ตรงนี้
Config.Weapons = {
    allowedGroups = {
        `GROUP_MELEE`,
        `GROUP_PISTOL`,
        `GROUP_RIFLE`,
        `GROUP_SHOTGUN`,
        `GROUP_SNIPER`,
        `GROUP_THROWN`,
        `GROUP_HEAVY`,
    },
    -- อาวุธที่ห้ามนับแม้จะอยู่ใน allowedGroups ด้านบน (เช่น ชกมือเปล่ามักถูกจัดกลุ่มเดียวกับมีด/มีดสั้นใน GROUP_MELEE)
    deniedWeapons = {
        `WEAPON_UNARMED`,
    },
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
