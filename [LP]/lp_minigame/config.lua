Config = {}

-- เรียกทุกเฟรมระหว่างเล่น minigame เพื่อบล็อกคอนโทรลเกม (กันตัวละครขยับ/ยิงปืนมั่ว)
Config.DisableControls = function()
    DisableAllControlActions(0)
end

--   successNeeded = ต้องสำเร็จกี่รอบถึงจะ return true
--   failLimit     = ผิดครบเท่านี้รอบ return false ทันที; ตั้ง 0 = ผิดกี่รอบก็ได้ไม่ตัดสิทธิ์

-- แบบกด Spacebar ให้ตรงโซนบนแถบที่วิ่ง
Config.Spacebar = {
    successNeeded = 3,
    failLimit = 1,
    duration = 2000,    -- ms ต่อรอบ (แถบวิ่งจน 100%)
    difficulty = 5,     -- ความยาก 1-10 (1 = โซนกว้าง 35px/ง่าย, 10 = โซนแคบ 15px/ยาก)
}

-- แบบกด W A S D ตามลำดับที่สุ่มมา ภายในเวลาที่กำหนด
Config.Sequence = {
    successNeeded = 3,
    failLimit = 1,
    keys = 6,           -- จำนวนปุ่มต่อรอบ
    timePerSet = 3000,  -- ms ต่อรอบ
    pool = { 'W', 'A', 'S', 'D' },
}

-- แบบวงแหวน (skill-check วงกลม): เข็มหมุนรอบวง กดปุ่มที่ขึ้นให้ตรงตอนเข็มเข้าโซนทอง
-- difficulty ยิ่งสูง โซนยิ่งแคบ + เข็มยิ่งหมุนเร็ว (จะระบุ arcDeg/rotateMs เองก็ได้ทับ difficulty)
Config.Circle = {
    successNeeded = 3,
    failLimit = 1,
    difficulty = 5,     -- 1-10 (1 = โซนกว้าง 70°/เข็มช้า, 10 = โซนแคบ 28°/เข็มเร็ว)
    duration = 4000,    -- ms ต่อรอบ ก่อน auto-fail ถ้ายังไม่กด
    pool = { 'E' },     -- ปุ่มที่ต้องกด (สุ่มต่อรอบ) — ใส่ { 'W','A','S','D' } ได้ (รองรับ W A S D E SPACE)
    -- arcDeg  = 45,    -- (ออปชั่น) กำหนดขนาดโซนเป็นองศาเองแทน difficulty
    -- rotateMs = 1200, -- (ออปชั่น) กำหนดเวลาเข็มหมุนครบรอบเองแทน difficulty
}

-- แบบตกปลา (ย้ายมาจาก MJ-AfkFishing): กด SPACEBAR ให้ตรงจังหวะ ตอนแท่ง indicator เด้งขึ้นลงเข้าโซนจับ
-- ต้นฉบับไม่มี timeout เลย (รอได้ไม่จำกัด) แต่ lp_minigame บล็อก NUI focus/control ทั้งจอไว้ระหว่างเล่น
-- เลยเพิ่ม duration ให้ auto-miss กันโดนปล่อยค้าง — successNeeded/failLimit=1 = ยิงครั้งเดียวจบ (รอบ/คูลดาวน์ เดิมให้ผู้เรียกจัดการเอง)
Config.Fishing = {
    successNeeded = 1,
    failLimit = 1,
    duration = 15000,   -- ms ที่มีให้กดก่อนหมดเวลา (auto-miss) — เดิม 8000 วิ่งเต็มราง (0->95%) ได้แค่~1 เที่ยว/~4.75วิ ต่อเที่ยว เพิ่มเป็น 15วิ ให้ได้ไป-กลับ~3 เที่ยวก่อนเฟล
    speedMin = 1.5,     -- ความเร็ว indicator ต่ำสุด (% ต่อ 100ms)
    speedMax = 2.5,     -- ความเร็ว indicator สูงสุด
    zoneSize = 15,      -- ขนาดโซนจับ (% ของแท่ง)
}

-- แบบสะเดาะกุญแจ (lockpick — port จาก guf1ck/lockpick-system, วาดใหม่เป็น SVG/CSS)
-- เลื่อนเมาส์เล็ง "เหล็กงัด" ไปยังจุดปลดล็อกที่ซ่อนอยู่ แล้วกด W/A/S/D ค้างเพื่อหมุนกระบอก
-- ถ้าเล็งตรงโซน → กระบอกหมุนจนสุด = สำเร็จ; ถ้าเพี้ยน → เหล็กงัดเสียหาย พังจน pin หมด = ล้มเหลว
-- difficulty ยิ่งสูง โซนปลดยิ่งแคบ + เหล็กเสียหายไวขึ้น. lockpick ต้องใช้เมาส์ → cursor = true
Config.Lockpick = {
    successNeeded = 1,   -- lockpick จบในรอบเดียว (pin ภายในจัดการเอง)
    failLimit = 1,
    cursor = true,       -- ต้องมี mouse cursor (NUI focus แบบมีเมาส์)
    pins = 5,            -- จำนวนเหล็กงัด (พลาดจนหมด = ล้มเหลว)
    difficulty = 5,      -- 1-10 (1 = โซนกว้าง 8° เสียหายน้อย, 10 = โซนแคบ 2° เสียหายเยอะ)
    -- solvePadding = 4, -- (ออปชั่น) ครึ่งความกว้างโซนปลดเป็นองศา ทับ difficulty
    -- pinDamage   = 20, -- (ออปชั่น) ดาเมจต่อการดันผิด 1 ครั้ง (health เหล็ก = 100)
}

--[[
    local ok = exports.lp_minigame:Spacebar()
    local ok = exports.lp_minigame:Sequence()

    local ok = exports.lp_minigame:Spacebar({
        successNeeded = 4,
        failLimit = 0,      -- ผิดกี่ครั้งก็ได้
        duration = 1500,
        difficulty = 8,     -- 1-10
    })

    local ok = exports.lp_minigame:Sequence({
        successNeeded = 3,
        failLimit = 2,
        keys = 6,
        timePerSet = 3500,
        pool = { 'W', 'A', 'S', 'D' },
    })

    local ok = exports.lp_minigame:Fishing()
    local ok = exports.lp_minigame:Fishing({ duration = 6000, zoneSize = 12 })  -- ยากขึ้น: เวลาน้อยลง โซนแคบลง

    local ok = exports.lp_minigame:Circle()
    local ok = exports.lp_minigame:Circle({ successNeeded = 2, difficulty = 8, pool = { 'W','A','S','D' } })

    local ok = exports.lp_minigame:Lockpick()
    local ok = exports.lp_minigame:Lockpick({ pins = 3, difficulty = 8 })  -- ยากขึ้น: เหล็กน้อยลง โซนแคบลง

    if exports.lp_minigame:Spacebar() then
        print('ผ่าน')
    else
        print('ไม่ผ่าน')
    end

    -- ยกเลิกระหว่างเล่น ตัวที่ค้างอยู่จะคืน false
    exports.lp_minigame:Cancel()
]]
