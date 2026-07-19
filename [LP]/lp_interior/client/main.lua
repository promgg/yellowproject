-- lp_interior — เครื่องมือ debug: พิมพ์ลง F8 ตอนผู้เล่นเข้า/ออก interior พร้อมพิกัด
--
-- native ที่ใช้ (ยืนยันว่าใช้งานได้จริงในโปรเจกต์นี้แล้ว — vorp_core/client/miscellanea.lua,
-- vorp_zonenotify/client/zone.lua, vorp_lib/client/main/selector.lua):
--   GetInteriorFromEntity(entity) -> interior id (0 = ไม่ได้อยู่ใน interior)
--   IsValidInterior(id)           -> เช็คว่า id เป็น interior จริง
--
-- ⚠️ อาคารใน RDR2 ไม่ได้เป็น interior ทุกหลัง — บ้าน/เพิงเล็กบางหลังเป็นตึกทึบไม่มี interior แยก
--    จุดพวกนั้นจะไม่ถูกตรวจจับ ถ้าต้องการครอบคลุมต้องเสริมด้วย PolyZone หรือเช็คระยะเอา

local RESOURCE = GetCurrentResourceName()

local currentInterior = 0 -- interior id ล่าสุดที่รู้ (0 = อยู่ข้างนอก)

-- IsValidInterior คืนค่าไม่เหมือนกันในแต่ละที่ของโปรเจกต์ (บางไฟล์เทียบ == 1 บางไฟล์ใช้เป็น boolean)
-- เลยรับทั้งสองแบบ กันพลาดเวลาเกมอัปเดต
local function isValidInterior(id)
    if not id or id == 0 then return false end
    local ok = IsValidInterior(id)
    return ok == true or ok == 1
end

local function getInterior(ped)
    local id = GetInteriorFromEntity(ped)
    if not isValidInterior(id) then return 0 end
    return id
end

local function fmtCoords(coords, heading)
    local d = Config.CoordDecimals or 4
    local fmt = ('vector3(%%.%df, %%.%df, %%.%df)'):format(d, d, d)
    local line = fmt:format(coords.x, coords.y, coords.z)
    if heading then
        line = line .. (' | heading %.4f'):format(heading)
    end
    return line
end

local function report(tag, id, coords, heading)
    -- print จาก client ไปโผล่ที่ console F8
    print(('[%s] %s  id=%s  %s'):format(RESOURCE, tag, tostring(id), fmtCoords(coords, heading)))
end

CreateThread(function()
    if not Config.Enabled then return end

    -- ตั้งค่าเริ่มต้นตามที่ผู้เล่นอยู่ตอน resource เริ่ม โดยไม่พิมพ์ (กัน log เด้งตอน restart)
    Wait(1000)
    currentInterior = getInterior(PlayerPedId())

    while Config.Enabled do
        local ped = PlayerPedId()
        local id = getInterior(ped)

        if id ~= currentInterior then
            local coords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)

            if id ~= 0 and currentInterior == 0 then
                report('>> เข้า interior ', id, coords, heading)
            elseif id == 0 and currentInterior ~= 0 then
                report('<< ออก interior ', currentInterior, coords, heading)
            else
                -- เดินจาก interior หนึ่งไปอีกอันโดยไม่ผ่านข้างนอก (ตึกที่เชื่อมกัน)
                report(('>< ย้าย interior %s ->'):format(tostring(currentInterior)), id, coords, heading)
            end

            currentInterior = id
        end

        Wait(Config.PollInterval or 500)
    end
end)

-- พิมพ์สถานะปัจจุบันตามต้องการ ไม่ต้องรอเดินเข้าออก
-- (ผูกกับ Config.Enabled ด้วย ไม่งั้นปิด resource แล้วคำสั่งยังค้างอยู่)
if Config.Enabled and Config.Command then
    RegisterCommand(Config.Command, function()
        local ped = PlayerPedId()
        local id = getInterior(ped)
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)

        if id ~= 0 then
            report('== อยู่ใน interior', id, coords, heading)
        else
            report('== อยู่ข้างนอก   ', 0, coords, heading)
        end
    end, false)
end

-- ให้ resource อื่นเรียกใช้ต่อได้เลยโดยไม่ต้องเขียน logic ซ้ำ
exports('IsInside', function()
    return currentInterior ~= 0
end)

exports('GetCurrentInterior', function()
    return currentInterior -- 0 = อยู่ข้างนอก
end)
