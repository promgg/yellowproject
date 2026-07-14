LP_DM = LP_DM or {}
LP_DM.Schedule = {}

-- วันที่ (YYYY-MM-DD) ล่าสุดที่อีเว้นท์เริ่มไปแล้วอัตโนมัติ กันเริ่มซ้ำหลายรอบในวันเดียวกัน
local lastTriggeredDate = nil

local function todayKey()
    local now = os.date('*t')
    return ('%04d-%02d-%02d'):format(now.year, now.month, now.day)
end

-- เรียก poll เป็นระยะ (ไม่ใช่ event-driven เพราะไม่มี event ธรรมชาติให้ฟัง แค่เทียบเวลาปัจจุบัน)
function LP_DM.Schedule.ShouldStartNow()
    if not Config.Schedule.enabled then return false end

    local key = todayKey()
    if lastTriggeredDate == key then return false end

    local now = os.date('*t')
    local nowMinutes = now.hour * 60 + now.min
    local startMinutes = (Config.Schedule.startHour or 0) * 60 + (Config.Schedule.startMinute or 0)

    if nowMinutes >= startMinutes then
        lastTriggeredDate = key
        return true
    end

    return false
end

-- เผื่อแอดมินสั่ง forcestart เอง — ต้องกันไม่ให้ auto-trigger ซ้ำในวันเดียวกันด้วย
function LP_DM.Schedule.MarkTriggeredToday()
    lastTriggeredDate = todayKey()
end
