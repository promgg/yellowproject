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

    -- ยังไม่เจอ — ลอง resolve ตัวที่ยังค้างอีกรอบ
    -- ตอน resource เริ่ม ผู้เล่นอาจอยู่ไกลจนเกมยังไม่โหลด interior นั้น GetInteriorAtCoords เลยคืน 0
    -- และ resolvedIds ว่างตลอดไป = ไม่มีอะไร match เลย (สาเหตุที่มิติไม่ทำงาน)
    -- พอเดินมาถึงจริงแล้วค่อย resolve ได้ เลยลองซ้ำตรงนี้
    for i = 1, #Config.Interiors do
        if not resolvedIds[i] then
            local c = Config.Interiors[i].coords
            local rid = GetInteriorAtCoords(c.x, c.y, c.z)
            if isValidInterior(rid) then
                resolvedIds[i] = rid
                if Config.DebugLog then
                    print(('[%s] resolve ย้อนหลัง "%s" -> interior id=%s'):format(
                        RESOURCE, Config.Interiors[i].key, tostring(rid)))
                end
                if rid == id then return i end
            end
        end
    end

    return nil
end

-- ── ย้ายมิติ ─────────────────────────────────────────────────────────────
-- client ส่งแค่ "index ใน config" ไม่ได้ส่งเลข bucket — server เป็นคนเปิด config เอง
-- แล้วตรวจระยะซ้ำก่อนย้าย (ไม่เชื่อ client) กันคนยิง event เองเพื่อย้ายมิติตามใจ
local function enterZone(index)
    if not Config.Dimension.Enabled then
        if Config.DebugLog then
            print(('[%s] ^3ข้าม enterZone:^7 Config.Dimension.Enabled = false'):format(RESOURCE))
        end
        return
    end
    if currentZoneIndex == index then return end

    local entry = Config.Interiors[index]
    currentZoneIndex = index

    if Config.DebugLog then
        print(('[%s] -> ขอเข้ามิติ "%s" (index=%d, bucket ที่คาดไว้=%s) ส่งให้ server แล้ว'):format(
            RESOURCE, entry.key, index, tostring(entry.bucket)))
    end

    TriggerServerEvent('lp_interior:enter', index)
    notify(Config.Text.Enter:format(entry.label))
end

local function leaveZone()
    if not Config.Dimension.Enabled then return end
    if not currentZoneIndex then return end

    local entry = Config.Interiors[currentZoneIndex]
    currentZoneIndex = nil

    if Config.DebugLog then
        print(('[%s] <- ขอออกจากมิติ "%s" กลับ bucket 0'):format(RESOURCE, entry.key))
    end

    TriggerServerEvent('lp_interior:leave')
    notify(Config.Text.Exit:format(entry.label))
end

-- server ยืนยันกลับมาว่า bucket จริงเป็นเท่าไหร่ (client อ่าน routing bucket ของตัวเองไม่ได้ —
-- GetPlayerRoutingBucket เป็น server native) ใช้ยืนยันว่าย้ายสำเร็จจริงไม่ใช่แค่ส่ง event ไป
RegisterNetEvent('lp_interior:bucketReport', function(bucket, note)
    print(('[%s] ^2[BUCKET]^7 ตอนนี้อยู่ bucket = %s  %s'):format(RESOURCE, tostring(bucket), note or ''))
end)

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

    local missCount = 0

    while true do
        local ped = PlayerPedId()
        local rawId = getInterior(ped)
        local id = rawId

        -- กันอาการกระพริบ: native คืน 0 เป็นช่วงๆ ทั้งที่ยังยืนอยู่ข้างใน ถ้าเชื่อค่าเดียวตรงๆ
        -- ผู้เล่นจะโดนเด้งกลับ bucket 0 ทุกไม่กี่วินาที ต้องอ่าน 0 ติดกันหลายครั้ง + ออกไปไกลจริง
        -- ถึงจะนับว่าออก
        if rawId == 0 and currentZoneIndex then
            local entry = Config.Interiors[currentZoneIndex]
            local dist = #(GetEntityCoords(ped) - entry.coords)

            if dist <= (Config.Dimension.ExitGuardDistance or 30.0) then
                missCount = missCount + 1
                if missCount < (Config.Dimension.ExitConfirmTicks or 3) then
                    id = currentInterior -- ถือว่ายังอยู่ข้างในเหมือนเดิม
                    if Config.DebugLog then
                        print(('[%s] ~ กรองการกระพริบ (อ่านได้ 0 ครั้งที่ %d/%d, ห่างโซน %.1fm)'):format(
                            RESOURCE, missCount, Config.Dimension.ExitConfirmTicks or 3, dist))
                    end
                else
                    missCount = 0
                end
            else
                missCount = 0 -- ออกไปไกลแล้ว = ออกจริง
            end
        else
            missCount = 0
        end

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

-- ── ทดสอบว่า client คุยกับ server ใน resource นี้ได้จริงไหม ────────────────
-- แยกออกมาจาก logic interior ทั้งหมด ไม่พึ่ง config/พิกัด/native อะไรเลย
-- /interiorping  -> ถ้า server ตอบกลับ แปลว่าเส้นทาง event ปกติ ปัญหาอยู่ที่ logic
--                   ถ้าไม่ตอบ แปลว่า server script ไม่ได้โหลด (คนละเรื่องกับ native)
RegisterCommand('interiorping', function()
    print(('[%s] ping -> ส่งไป server...'):format(RESOURCE))
    TriggerServerEvent('lp_interior:ping')
end, false)

RegisterNetEvent('lp_interior:pong', function(msg)
    print(('[%s] ^2pong <- server ตอบกลับแล้ว:^7 %s'):format(RESOURCE, tostring(msg)))
end)

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
