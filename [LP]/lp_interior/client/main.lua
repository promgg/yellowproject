-- lp_interior — ตรวจจับ interior แล้วย้ายมิติ (routing bucket) + log/แจ้งเตือน
--
-- native ที่ใช้ (ยืนยันว่าใช้งานได้จริงในโปรเจกต์นี้แล้ว — vorp_core/client/miscellanea.lua,
-- vorp_zonenotify/client/zone.lua, vorp_lib/client/main/selector.lua):
--   GetInteriorFromEntity(entity) -> interior id ของที่ที่ entity อยู่ (0 = ข้างนอก)
--   GetInteriorAtCoords(x, y, z)  -> interior id ที่พิกัดนั้น
--   IsValidInterior(id)           -> เช็คว่า id เป็น interior จริง
--
-- ⚠️ อาคารใน RDR2 ไม่ได้เป็น interior ทุกหลัง — บ้าน/เพิงเล็กบางหลังเป็นตึกทึบไม่มี interior แยก
--    จุดพวกนั้นจะไม่ถูกตรวจจับ ถ้าต้องการครอบคลุมต้องเสริมด้วย PolyZone หรือเช็คระยะเอา

local RESOURCE = GetCurrentResourceName()

local currentInterior = 0    -- interior id ล่าสุดที่รู้ (0 = อยู่ข้างนอก)
local currentZoneIndex = nil -- index ใน Config.Interiors ที่กำลังอยู่ (nil = ไม่ได้อยู่ในจุดที่แยกมิติ)
local resolvedIds = {}       -- [index] = interior id ที่ resolve ได้จากพิกัดใน config

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

local function notify(msg)
    if not Config.Notify then return end
    if GetResourceState('pNotify') ~= 'started' then return end
    exports.pNotify:SendNotification({ type = 'success', text = msg, timeout = 4000 })
end

-- ── debug log ────────────────────────────────────────────────────────────
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
    if not Config.DebugLog then return end
    -- print จาก client ไปโผล่ที่ console F8
    print(('[%s] %s  id=%s  %s'):format(RESOURCE, tag, tostring(id), fmtCoords(coords, heading)))
end

-- ── resolve interior id จากพิกัดใน config ────────────────────────────────
-- ทำครั้งเดียวตอนเริ่ม เพราะ id เป็นค่าที่อาจเปลี่ยนเมื่อเกมอัปเดต แต่พิกัดคงที่
-- (pattern เดียวกับ vorp_zonenotify ที่ resolve ถ้ำ Beaver Hollow จากพิกัด)
local function resolveConfiguredInteriors()
    for i = 1, #Config.Interiors do
        local entry = Config.Interiors[i]
        local c = entry.coords
        local id = GetInteriorAtCoords(c.x, c.y, c.z)

        if isValidInterior(id) then
            resolvedIds[i] = id
            if Config.DebugLog then
                print(('[%s] resolve "%s" -> interior id=%s'):format(RESOURCE, entry.key, tostring(id)))
            end
        else
            -- ไม่ล้มทั้งระบบ แค่ข้ามจุดนี้ไป จุดอื่นยังทำงานปกติ
            print(('[%s] ^3เตือน:^7 พิกัดของ "%s" ไม่ใช่ interior (id=%s) — ข้ามจุดนี้ ตรวจพิกัดใน config'):format(
                RESOURCE, entry.key, tostring(id)))
        end
    end
end

local function findZoneIndexByInterior(id)
    if id == 0 then return nil end
    for i = 1, #Config.Interiors do
        if resolvedIds[i] == id then return i end
    end
    return nil
end

-- ── ย้ายมิติ ─────────────────────────────────────────────────────────────
-- client ส่งแค่ "index ใน config" ไม่ได้ส่งเลข bucket — server เป็นคนเปิด config เอง
-- แล้วตรวจระยะซ้ำก่อนย้าย (ไม่เชื่อ client) กันคนยิง event เองเพื่อย้ายมิติตามใจ
local function enterZone(index)
    if not Config.Dimension.Enabled then return end
    if currentZoneIndex == index then return end

    currentZoneIndex = index
    TriggerServerEvent('lp_interior:enter', index)
    notify(Config.Text.Enter:format(Config.Interiors[index].label))
end

local function leaveZone()
    if not Config.Dimension.Enabled then return end
    if not currentZoneIndex then return end

    local label = Config.Interiors[currentZoneIndex].label
    currentZoneIndex = nil
    TriggerServerEvent('lp_interior:leave')
    notify(Config.Text.Exit:format(label))
end

-- ── ลูปตรวจจับ ───────────────────────────────────────────────────────────
CreateThread(function()
    Wait(1000)
    resolveConfiguredInteriors()

    -- ตั้งค่าเริ่มต้นตามที่ผู้เล่นอยู่ตอน resource เริ่ม โดยไม่พิมพ์ log (กัน log เด้งตอน restart)
    -- แต่ถ้าอยู่ในจุดที่ต้องแยกมิติอยู่แล้ว ต้องย้ายให้ด้วย ไม่งั้นค้างอยู่มิติหลักทั้งที่อยู่ข้างใน
    currentInterior = getInterior(PlayerPedId())
    local startIndex = findZoneIndexByInterior(currentInterior)
    if startIndex then
        enterZone(startIndex)
    end

    while true do
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

            -- อัปเดตมิติตาม interior ใหม่ — ออกจากอันเก่าก่อนเสมอ กันค้างสองมิติ
            local zoneIndex = findZoneIndexByInterior(id)
            if zoneIndex then
                if currentZoneIndex and currentZoneIndex ~= zoneIndex then
                    leaveZone()
                end
                enterZone(zoneIndex)
            else
                leaveZone()
            end
        end

        Wait(Config.PollInterval or 500)
    end
end)

-- ── คำสั่ง debug ─────────────────────────────────────────────────────────
if Config.DebugLog and Config.Command then
    RegisterCommand(Config.Command, function()
        local ped = PlayerPedId()
        local id = getInterior(ped)
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        local zoneIndex = findZoneIndexByInterior(id)
        local where = zoneIndex and (' | โซน: ' .. Config.Interiors[zoneIndex].label) or ''

        if id ~= 0 then
            print(('[%s] == อยู่ใน interior  id=%s  %s%s'):format(RESOURCE, tostring(id), fmtCoords(coords, heading), where))
        else
            print(('[%s] == อยู่ข้างนอก     id=0  %s'):format(RESOURCE, fmtCoords(coords, heading)))
        end
    end, false)
end

-- ── cleanup ──────────────────────────────────────────────────────────────
-- ถ้า resource ถูกหยุดขณะผู้เล่นอยู่ในมิติแยก ต้องดึงกลับมิติหลัก ไม่งั้นค้างอยู่มิติเปล่า
AddEventHandler('onResourceStop', function(res)
    if res ~= RESOURCE then return end
    if currentZoneIndex then
        TriggerServerEvent('lp_interior:leave')
    end
end)

-- ── exports ให้ resource อื่นใช้ต่อ ──────────────────────────────────────
exports('IsInside', function()
    return currentInterior ~= 0
end)

exports('GetCurrentInterior', function()
    return currentInterior -- 0 = อยู่ข้างนอก
end)

exports('GetCurrentZone', function()
    if not currentZoneIndex then return nil end
    local entry = Config.Interiors[currentZoneIndex]
    return { key = entry.key, label = entry.label, bucket = entry.bucket }
end)
