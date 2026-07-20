-- lp_interior — ตรวจจับว่าอยู่ในอาคารไหน แล้วย้ายมิติ (routing bucket) + เขตปลอดภัย + มิติ AFK
--
-- native ที่ใช้ (ยืนยันว่าใช้งานได้จริงในโปรเจกต์นี้แล้ว — vorp_core/client/miscellanea.lua,
-- vorp_zonenotify/client/zone.lua, vorp_lib/client/main/selector.lua):
--   GetInteriorFromEntity(entity) -> interior id ของที่ที่ entity อยู่ (0 = ข้างนอก)
--   GetInteriorAtCoords(x, y, z)  -> interior id ที่พิกัดนั้น
--   IsValidInterior(id)           -> เช็คว่า id เป็น interior จริง
--
-- อาคารใน RDR2 ไม่ได้เป็น interior ทุกหลัง — แมพเสริมที่ import เข้ามา (เช่น saloon Annesburg)
-- จะคืน id 0 ตลอด จุดพวกนั้นใช้ entry แบบ `poly` แทน ดูคำอธิบายใน config.lua

local RESOURCE = GetCurrentResourceName()

local currentInterior = 0    -- interior id ล่าสุดที่รู้ (0 = อยู่ข้างนอก) ใช้กับ debug log เท่านั้น
local currentZoneIndex = nil -- index ใน Config.Interiors ที่กำลังอยู่ (nil = ไม่ได้อยู่ในจุดที่แยกมิติ)
local resolvedIds = {}       -- [index] = interior id ที่ resolve ได้จากพิกัดใน config
local afkActive = false      -- อยู่ในมิติ AFK ของโซนปัจจุบันหรือไม่

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

-- ── โหมด polygon ─────────────────────────────────────────────────────────
-- ray casting แนวนอน: นับจำนวนครั้งที่เส้นตรงจากจุดนั้นไปทางขวาตัดขอบรูป
-- เลขคี่ = อยู่ข้างใน ใช้ได้กับรูปหลายเหลี่ยมกี่มุมก็ได้ ไม่สนทิศทางการไล่มุม
-- ขอแค่ขอบไม่ตัดกันเอง (ไล่มุมวนรอบรูป ไม่ใช่สลับข้าม)
local function insidePoly(entry, coords)
    if coords.z < (entry.minZ or -1000.0) or coords.z > (entry.maxZ or 1000.0) then
        return false
    end

    local poly = entry.poly
    local n = #poly
    local inside = false
    local j = n

    for i = 1, n do
        local a, b = poly[i], poly[j]
        -- ขอบนี้คร่อมแนว y ของจุดที่ตรวจหรือไม่ (เทียบด้านเดียวกัน กันนับซ้ำตอนโดนมุมพอดี)
        if (a.y > coords.y) ~= (b.y > coords.y) then
            local xAtY = a.x + (coords.y - a.y) / (b.y - a.y) * (b.x - a.x)
            if coords.x < xAtY then
                inside = not inside
            end
        end
        j = i
    end

    return inside
end

-- ── resolve interior id จากพิกัดใน config ────────────────────────────────
-- ทำครั้งเดียวตอนเริ่ม เพราะ id เป็นค่าที่อาจเปลี่ยนเมื่อเกมอัปเดต แต่พิกัดคงที่
-- (pattern เดียวกับ vorp_zonenotify ที่ resolve ถ้ำ Beaver Hollow จากพิกัด)
-- entry โหมด poly ข้ามไป มันไม่มี interior id ให้ resolve อยู่แล้ว
local function resolveConfiguredInteriors()
    for i = 1, #Config.Interiors do
        local entry = Config.Interiors[i]
        if not entry.poly then
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
        local entry = Config.Interiors[i]
        if not entry.poly and not resolvedIds[i] then
            local c = entry.coords
            local rid = GetInteriorAtCoords(c.x, c.y, c.z)
            if isValidInterior(rid) then
                resolvedIds[i] = rid
                if Config.DebugLog then
                    print(('[%s] resolve ย้อนหลัง "%s" -> interior id=%s'):format(RESOURCE, entry.key, tostring(rid)))
                end
                if rid == id then return i end
            end
        end
    end

    return nil
end

-- หาโซนปัจจุบัน — เช็คโหมด polygon ก่อนเสมอ
-- อาคารแมพเสริมบางหลังซ้อนอยู่บน interior ของเกมจริง ถ้าเช็ค interior ก่อนจะได้โซนผิด
local function findZone(ped, coords)
    for i = 1, #Config.Interiors do
        local entry = Config.Interiors[i]
        if entry.poly and insidePoly(entry, coords) then
            return i, 0
        end
    end

    local id = getInterior(ped)
    return findZoneIndexByInterior(id), id
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
    afkActive = false -- เข้าโซนใหม่เริ่มที่มิติปกติเสมอ

    if Config.DebugLog then
        print(('[%s] -> ขอเข้ามิติ "%s" (index=%d, bucket ที่คาดไว้=%s) ส่งให้ server แล้ว'):format(
            RESOURCE, entry.key, index, tostring(entry.bucket)))
    end

    TriggerServerEvent('lp_interior:enter', index)
    notify(Config.Text.Enter:format(entry.label))

    -- ให้ resource อื่นรู้ตัวได้ทันที ไม่ต้องคอย poll export เอา (MJ-Afk-Zone-ui ใช้ตัวนี้)
    TriggerEvent('lp_interior:onEnter', entry.key)
end

local function leaveZone()
    if not Config.Dimension.Enabled then return end
    if not currentZoneIndex then return end

    local entry = Config.Interiors[currentZoneIndex]
    currentZoneIndex = nil
    -- ไม่ต้องยิง setAfk ตามหลัง — server รีเซ็ตเป็น bucket 0 ให้อยู่แล้วตอนรับ leave
    afkActive = false

    if Config.DebugLog then
        print(('[%s] <- ขอออกจากมิติ "%s" กลับ bucket 0'):format(RESOURCE, entry.key))
    end

    TriggerServerEvent('lp_interior:leave')
    notify(Config.Text.Exit:format(entry.label))

    TriggerEvent('lp_interior:onLeave', entry.key)
end

-- ── มิติ AFK ─────────────────────────────────────────────────────────────
-- สลับระหว่าง bucket ปกติของโซน กับ afkBucket ของโซนเดียวกัน (อาคารเดิม คนละมิติ)
local function setAfk(on)
    if not Config.Afk.Enabled then return false end
    if not currentZoneIndex then return false end

    local entry = Config.Interiors[currentZoneIndex]
    if not entry.afkBucket then return false end
    if afkActive == on then return true end

    afkActive = on
    TriggerServerEvent('lp_interior:setAfk', currentZoneIndex, on)
    notify(on and Config.Text.AfkEnter or Config.Text.AfkExit:format(entry.label))

    return true
end

-- server ยืนยันกลับมาว่า bucket จริงเป็นเท่าไหร่ (client อ่าน routing bucket ของตัวเองไม่ได้ —
-- GetPlayerRoutingBucket เป็น server native) ใช้ยืนยันว่าย้ายสำเร็จจริงไม่ใช่แค่ส่ง event ไป
RegisterNetEvent('lp_interior:bucketReport', function(bucket, note)
    if not Config.DebugLog then return end
    print(('[%s] ^2[BUCKET]^7 ตอนนี้อยู่ bucket = %s  %s'):format(RESOURCE, tostring(bucket), note or ''))
end)

-- ── ลูปตรวจจับ ───────────────────────────────────────────────────────────
CreateThread(function()
    Wait(1000)
    resolveConfiguredInteriors()

    local missCount = 0

    while true do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local zoneIndex, rawId = findZone(ped, coords)

        -- กันอาการกระพริบ: GetInteriorFromEntity คืน 0 เป็นช่วงๆ ทั้งที่ยังยืนอยู่ข้างใน ถ้าเชื่อ
        -- ค่าเดียวตรงๆ ผู้เล่นจะโดนเด้งกลับ bucket 0 ทุกไม่กี่วินาที ต้องอ่าน 0 ติดกันหลายครั้ง
        -- + ออกไปไกลจริง ถึงจะนับว่าออก
        --
        -- ใช้เฉพาะโหมด interior — โหมด polygon คำนวณจากพิกัดล้วน ไม่มีอาการอ่านค่าหลุด
        -- ถ้าเอามาผ่อนผันด้วยจะกลายเป็นเดินออกจากร้านแล้วยังค้างในมิติไปอีกหลายวินาที
        if not zoneIndex and currentZoneIndex and not Config.Interiors[currentZoneIndex].poly then
            local entry = Config.Interiors[currentZoneIndex]
            local dist = #(coords - entry.coords)

            if dist <= (Config.Dimension.ExitGuardDistance or 30.0) then
                missCount = missCount + 1
                if missCount < (Config.Dimension.ExitConfirmTicks or 3) then
                    zoneIndex = currentZoneIndex -- ถือว่ายังอยู่ข้างในเหมือนเดิม
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

        -- log เฉพาะตอน interior id เปลี่ยนจริง (แยกจาก logic โซน เพื่อให้ยังเก็บพิกัดจุดใหม่ได้)
        if rawId ~= currentInterior then
            local heading = GetEntityHeading(ped)
            if rawId ~= 0 and currentInterior == 0 then
                report('>> เข้า interior ', rawId, coords, heading)
            elseif rawId == 0 and currentInterior ~= 0 then
                report('<< ออก interior ', currentInterior, coords, heading)
            else
                report(('>< ย้าย interior %s ->'):format(tostring(currentInterior)), rawId, coords, heading)
            end
            currentInterior = rawId
        end

        if zoneIndex ~= currentZoneIndex then
            -- ออกจากอันเก่าก่อนเสมอ กันค้างสองมิติตอนเดินทะลุจากอาคารหนึ่งไปอีกอันโดยไม่ผ่านข้างนอก
            leaveZone()
            if zoneIndex then
                enterZone(zoneIndex)
            end
        end

        Wait(Config.PollInterval or 500)
    end
end)

-- ── เขตปลอดภัย ───────────────────────────────────────────────────────────
-- ห้ามใช้ RemoveAllPedWeapons — vorp_inventory ผูกอาวุธกับ DB คนละชั้น ลบออกจาก ped ตรงๆ
-- เสี่ยงของหายจริง ที่นี่แค่ "บังคับสลับเป็นมือเปล่า" ตัวอาวุธยังอยู่ในกระเป๋าครบ
local UNARMED = joaat('WEAPON_UNARMED')

-- hash ยกมาจาก nx_util/client/cl_anti_combat.lua ที่ใช้งานจริงบนเซิร์ฟนี้แล้ว (ไม่ได้เดาเลขเอง)
local BLOCKED_CONTROLS = {
    0x07CE1E61, -- INPUT_ATTACK
    0x0283C582, -- INPUT_ATTACK2
    0xB2F377E8, -- INPUT_MELEE_ATTACK
    0x1E7D7275, -- INPUT_MELEE_MODIFIER
    0xB5EEEFB7, -- INPUT_MELEE_BLOCK
    0xD9C50532, -- INPUT_HOGTIE
    0x0522B243, -- INPUT_INTERACT_HIT_CARRIABLE
    0x2277FAE9, -- INPUT_MELEE_GRAPPLE
    0xADEAF48C, -- INPUT_MELEE_GRAPPLE_ATTACK
    0x018C47CF, -- INPUT_MELEE_GRAPPLE_CHOKE
}

local allowedWeapons = {}
for _, name in ipairs(Config.Safezone.Allowed or {}) do
    allowedWeapons[joaat(name)] = true
end

local function safezoneActive()
    if not Config.Safezone.Enabled then return false end
    if not currentZoneIndex then return false end
    return Config.Interiors[currentZoneIndex].safezone == true
end

CreateThread(function()
    local applied = false
    local lastWeaponNotify = 0

    while true do
        if safezoneActive() then
            local ped = PlayerPedId()

            if not applied then
                applied = true
                lastWeaponNotify = 0
                notify(Config.Text.SafezoneEnter)
            end

            if Config.Safezone.Invincible then
                -- ตั้งซ้ำทุกเฟรม ไม่ใช่ครั้งเดียวตอนเข้า — ped ถูกสร้างใหม่ตอนเกิด/สลับตัวละคร
                -- แล้วค่า invincible จะหายไปเงียบๆ โดยไม่มีอะไรแจ้ง
                SetEntityInvincible(ped, true)
            end

            -- native ตัวนี้รับ "player index" ไม่ใช่ ped (ในโปรเจกต์นี้มีที่ส่ง ped ผิดอยู่บ้าง)
            -- แต่ไม่พึ่งมันตัวเดียว การบังคับสลับเป็นมือเปล่าด้านล่างคือตัวกันจริง
            DisablePlayerFiring(PlayerId(), true)

            for i = 1, #BLOCKED_CONTROLS do
                DisableControlAction(0, BLOCKED_CONTROLS[i], true)
            end

            local ok, weapon = GetCurrentPedWeapon(ped, true)
            if ok and weapon and weapon ~= UNARMED and not allowedWeapons[weapon] then
                SetCurrentPedWeapon(ped, UNARMED, true)

                local now = GetGameTimer()
                if now - lastWeaponNotify >= (Config.Safezone.NotifyCooldown or 10000) then
                    lastWeaponNotify = now
                    notify(Config.Text.SafezoneWeapon)
                end
            end

            Wait(0)
        else
            if applied then
                applied = false
                if Config.Safezone.Invincible then
                    SetEntityInvincible(PlayerPedId(), false)
                end
            end
            Wait(500)
        end
    end
end)

-- ── คำสั่ง debug ─────────────────────────────────────────────────────────
if Config.DebugLog and Config.Command then
    RegisterCommand(Config.Command, function()
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        local zoneIndex, id = findZone(ped, coords)
        local where = zoneIndex and (' | โซน: ' .. Config.Interiors[zoneIndex].label) or ' | ไม่ได้อยู่ในโซนที่ตั้งไว้'
        local mode = zoneIndex and (Config.Interiors[zoneIndex].poly and 'polygon' or 'interior') or '-'

        print(('[%s] == %s  id=%s  โหมด=%s  safezone=%s  afk=%s%s'):format(
            RESOURCE,
            fmtCoords(coords, heading),
            tostring(id),
            mode,
            tostring(safezoneActive()),
            tostring(afkActive),
            where))
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
-- และต้องคืนค่า invincible ด้วย ไม่งั้นผู้เล่นอมตะค้างจนกว่าจะเกิดใหม่
AddEventHandler('onResourceStop', function(res)
    if res ~= RESOURCE then return end
    if currentZoneIndex then
        TriggerServerEvent('lp_interior:leave')
    end
    SetEntityInvincible(PlayerPedId(), false)
end)

-- ── exports ให้ resource อื่นใช้ต่อ ──────────────────────────────────────
exports('IsInside', function()
    return currentZoneIndex ~= nil
end)

exports('GetCurrentInterior', function()
    return currentInterior -- 0 = เกมไม่ถือว่าอยู่ใน interior (โซนโหมด polygon ก็คืน 0)
end)

exports('GetCurrentZone', function()
    if not currentZoneIndex then return nil end
    local entry = Config.Interiors[currentZoneIndex]
    return {
        key      = entry.key,
        label    = entry.label,
        bucket   = entry.bucket,
        safezone = entry.safezone == true,
        afk      = afkActive,
    }
end)

exports('IsInAfk', function()
    return afkActive
end)

-- สลับมิติ AFK ของโซนที่ยืนอยู่ตอนนี้ — คืนสถานะใหม่ หรือ nil ถ้าสลับไม่ได้
-- (ไม่ได้อยู่ในโซน / โซนนั้นไม่ได้ตั้ง afkBucket / ปิดระบบ AFK ไว้)
exports('ToggleAfk', function()
    if not currentZoneIndex then return nil end
    local entry = Config.Interiors[currentZoneIndex]
    if not entry.afkBucket or not Config.Afk.Enabled then return nil end

    setAfk(not afkActive)
    return afkActive
end)

exports('SetAfk', function(on)
    if not setAfk(on == true) then return nil end
    return afkActive
end)
