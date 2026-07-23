NX_GR = NX_GR or {}
NX_GR.EventNotify = {}

-- แสดงเฉพาะแดนบน (มี schedule) เป็น badge ลอย "[code] GRAVE [เหลือ/ทั้งหมด]" มุมขวาบนผ่าน lp_eventnotify
-- ปิด/เปิดเองตามช่วงเวลาเปิดของแต่ละเมือง ไม่ต้องยุ่งกับแดนใต้ (ไม่มี schedule เลย)
local TOWN_CODES = {
    valentine = 'VLT',
    rhodes = 'RHD',
    annesburg = 'ANB',
}

local wasOpen = {}

local function eventId(villageId)
    return 'nx_grave_' .. villageId
end

local function countHoles(villageId)
    local total, remaining = 0, 0
    for _, grave in ipairs(Config.Graves) do
        if grave.villageId == villageId then
            total = total + 1
            if NX_GR.Cooldowns.IsAvailable(grave.id) then
                remaining = remaining + 1
            end
        end
    end
    return remaining, total
end

function NX_GR.EventNotify.Refresh(villageId)
    if not TOWN_CODES[villageId] then return end
    if GetResourceState('lp_eventnotify') ~= 'started' then return end

    local id = eventId(villageId)
    local isOpen = NX_GR.Schedule.IsVillageOpenNow(villageId)
    local remaining, total = countHoles(villageId)
    local shouldShow = isOpen and remaining > 0 -- ขุดครบ 10/10 แล้วให้หายเลย ไม่ต้องรอถึงเวลาปิด

    if shouldShow then
        if exports.lp_eventnotify:IsEventActive(id) then
            exports.lp_eventnotify:UpdateProgress(id, remaining)
        else
            -- ชื่อเต็มจาก Config.Villages[id].label (เช่น "Valentine") แทนโค้ดย่อ (VLT) — fallback
            -- เป็นโค้ดย่อกันพังถ้า Config.Villages ไม่มี entry นี้ (ไม่ควรเกิด แต่กันไว้)
            local villageLabel = (Config.Villages[villageId] or {}).label or TOWN_CODES[villageId]
            local label = villageLabel .. ' Grave'
            exports.lp_eventnotify:StartProgressEvent(id, label, 'hot-time', remaining, total)
        end
        wasOpen[villageId] = true
    elseif wasOpen[villageId] then
        exports.lp_eventnotify:StopEvent(id)
        wasOpen[villageId] = false
    end
end

function NX_GR.EventNotify.RefreshAll()
    for villageId in pairs(TOWN_CODES) do
        NX_GR.EventNotify.Refresh(villageId)
    end
end

CreateThread(function()
    Wait(2000) -- รอ Cooldowns.Init + lp_eventnotify เริ่มก่อน
    while true do
        NX_GR.EventNotify.RefreshAll()
        Wait(30000) -- จับจังหวะเปิด/ปิดตามตารางเวลาโดยไม่ต้องมี thread แยกทุกวินาที
    end
end)
