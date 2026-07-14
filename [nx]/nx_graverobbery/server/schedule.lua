NX_GR = NX_GR or {}
NX_GR.Schedule = {}

local function getVillageSchedule(villageId)
    local village = Config.Villages[villageId]
    if not village then return nil end
    local schedule = village.schedule
    if not schedule or schedule.enabled ~= true then return nil end
    return schedule
end

-- ไม่มี schedule = เปิดตลอด (เช่น แดนใต้ คุมด้วยคูลดาวน์รายหลุมแทน)
function NX_GR.Schedule.IsVillageOpenNow(villageId)
    local schedule = getVillageSchedule(villageId)
    if not schedule then return true end

    local now = os.date('*t')
    local nowMinutes = now.hour * 60 + now.min
    local openMinutes = (schedule.openHour or 0) * 60 + (schedule.openMinute or 0)

    return nowMinutes >= openMinutes
end

-- เรียกตอน commit เท่านั้น (แปลว่าตอนนี้ต้องเปิดอยู่แล้ว) — เลยคำนวณหารอบเปิดของ "พรุ่งนี้" เสมอ
function NX_GR.Schedule.SecondsUntilNextOpen(villageId)
    local schedule = getVillageSchedule(villageId)
    if not schedule then return 0 end

    local now = os.date('*t')
    local target = os.time({
        year = now.year,
        month = now.month,
        day = now.day + 1,
        hour = schedule.openHour or 0,
        min = schedule.openMinute or 0,
        sec = 0,
    })

    return math.max(60, target - os.time())
end
