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

    if exports.lp_minigame:Spacebar() then
        print('ผ่าน')
    else
        print('ไม่ผ่าน')
    end

    -- ยกเลิกระหว่างเล่น ตัวที่ค้างอยู่จะคืน false
    exports.lp_minigame:Cancel()
]]
