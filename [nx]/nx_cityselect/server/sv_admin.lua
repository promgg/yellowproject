-- server/sv_admin.lua
-- ฝั่ง logic ของการ "ย้ายเมือง / เปลี่ยนเชื้อสาย" โดยแอดมิน
--
-- ตัว UI ไม่ได้อยู่ที่นี่ — อยู่ใน MJ-Admin (แทบ "เมือง / เชื้อสาย" ในหน้าจัดการผู้เล่น)
-- ไฟล์นี้เปิดเป็น server export ให้ MJ-Admin เรียกหลังตรวจสิทธิ์ของตัวเองแล้ว
--
-- ทำไมเป็น export ไม่ใช่ net event:
--   export ข้าม resource เรียกได้จากฝั่ง server เท่านั้น — ผู้เล่นปลอม event มายิงตรงไม่ได้
--   ถ้าทำเป็น RegisterNetEvent ใครก็ยิงมาย้ายเมืองตัวเองได้ทันที
--   (สิทธิ์แอดมินจริงตรวจที่ MJ-Admin: Config.Perms[group].CanSetJob)
--
-- ⚠️ ทำได้เฉพาะผู้เล่นออนไลน์: หัก/แจกบัตรต้องใช้ source ผ่าน vorp_inventory
--    และ setJob ต้องใช้ character object — ทั้งคู่ไม่มีสำหรับคนออฟไลน์

local Core = exports.vorp_core:GetCore()
local Inv  = exports.vorp_inventory

-- กันเคส config เก่าที่ยังไม่มีบล็อก Config.Admin (อัปเดต resource แล้วลืม merge config)
Config.Admin = Config.Admin or {}

-- ─────────────────────────────────────────────────────────────
--  INTERNAL HELPERS
-- ─────────────────────────────────────────────────────────────

local function GetUserAndChar(source)
    local user = Core.getUser(source)
    if not user then return nil, nil end
    local char = user.getUsedCharacter
    if not char then return nil, nil end
    return user, char
end

local function CharName(char)
    local first = char.firstname or ""
    local last  = char.lastname or ""
    local full  = (first .. " " .. last):gsub("^%s+", ""):gsub("%s+$", "")
    if full ~= "" then return full end
    return "#" .. tostring(char.charIdentifier or "?")
end

local function Notify(source, text, kind)
    TriggerClientEvent('pNotify:SendNotification', source, {
        type = kind or 'info', text = text, timeout = 6000,
    })
end

-- ─────────────────────────────────────────────────────────────
--  INTERNAL: สลับบัตรประจำเมือง — ลบบัตรเมืองอื่นทุกใบ แล้วแจกบัตรเมืองใหม่
--
--  ลบ "ทุกเมืองที่ไม่ใช่เมืองใหม่" ไม่ใช่แค่เมืองเก่าใบเดียว เพื่อกวาดเคสข้อมูลเพี้ยน
--  (เคยถือบัตรหลายใบจากการแก้ DB ตรง ๆ หรือย้ายเมืองสมัยที่ยังไม่มีระบบนี้)
--
--  หมายเหตุเรื่อง can_remove: badge ตั้ง can_remove = 0 ใน DB — flag นั้นกันแค่
--  "ผู้เล่นทิ้ง/ส่งเอง" ผ่าน UI กระเป๋า ส่วน subItem ฝั่ง server ไม่เช็ค flag นี้เลย
--  (ตรวจ vorp_inventory/server/services/inventoryApiService.lua แล้ว) จึงลบได้จริง
--
--  คืน true = ผู้เล่นมีบัตรเมืองใหม่อยู่ในมือแล้ว, false = แจกไม่ได้ (กระเป๋าเต็ม)
-- ─────────────────────────────────────────────────────────────
local function SwapCityBadge(targetSrc, newCityId)
    local newCity = GetCityById(newCityId)

    -- 1) ลบบัตรของทุกเมืองที่ไม่ใช่เมืองใหม่
    for _, city in ipairs(Config.Cities) do
        if city.id ~= newCityId and city.badgeItem then
            local count = Inv:getItemCount(targetSrc, nil, city.badgeItem) or 0
            if count > 0 then
                Inv:subItem(targetSrc, city.badgeItem, count)
            end
        end
    end

    -- 2) แจกบัตรเมืองใหม่ (ถ้ายังไม่มี — limit ของ badge = 1 ไม่ต้องแจกซ้ำ)
    if not newCity or not newCity.badgeItem then return true end

    local have = Inv:getItemCount(targetSrc, nil, newCity.badgeItem) or 0
    if have > 0 then return true end

    if not Inv:canCarryItem(targetSrc, newCity.badgeItem, 1) then
        return false
    end

    Inv:addItem(targetSrc, newCity.badgeItem, 1)
    return true
end

-- ═════════════════════════════════════════════════════════════
--  EXPORT: GetAdminLists()
--  รายการเมือง/เชื้อสายทั้งหมด — ให้ MJ-Admin เอาไปเติมใน dropdown
-- ═════════════════════════════════════════════════════════════
exports('GetAdminLists', function()
    local cities = {}
    local counts = CityManager_GetCounts()
    for _, city in ipairs(Config.Cities) do
        local slot = counts[city.id] or { count = 0, available = true }
        cities[#cities + 1] = {
            id    = city.id,
            name  = city.name,
            label = city.label,
            count = slot.count,
            max   = Config.MaxPlayersPerCity,
        }
    end

    local heritages = {}
    for _, h in ipairs(Config.Heritages) do
        heritages[#heritages + 1] = { id = h.id, name = h.name, label = h.label }
    end

    return { cities = cities, heritages = heritages }
end)

-- ═════════════════════════════════════════════════════════════
--  EXPORT: GetPlayerCityHeritage(targetId)
--  เมือง/เชื้อสายปัจจุบันของผู้เล่นคนหนึ่ง — ให้ MJ-Admin โชว์ในหน้าข้อมูลผู้เล่น
--  คืน nil ถ้าผู้เล่นออฟไลน์/ไม่มีตัวละคร
-- ═════════════════════════════════════════════════════════════
exports('GetPlayerCityHeritage', function(targetId)
    targetId = tonumber(targetId)
    if not targetId then return nil end

    local _, char = GetUserAndChar(targetId)
    if not char then return nil end

    local cityId     = CityManager_GetPlayerCity(char.identifier, char.charIdentifier)
    local heritageId = HeritageManager_GetPlayerHeritage(char.identifier, char.charIdentifier)
    local cityData     = cityId and GetCityById(cityId) or nil
    local heritageData = heritageId and GetHeritageById(heritageId) or nil

    return {
        cityId        = cityId,
        cityLabel     = cityData and cityData.label or nil,
        heritageId    = heritageId,
        heritageName  = heritageData and heritageData.name or nil,
    }
end)

-- ═════════════════════════════════════════════════════════════
--  EXPORT: AdminSetPlayerCity(targetId, cityId)
--  ย้ายผู้เล่นไปเมืองใหม่ — ทำ 4 อย่างเป็นชุด:
--    1) อัปเดต DB (upsert ทับของเดิม)
--    2) ปรับตัวนับ slot ทั้งเมืองเก่าและใหม่
--    3) สลับบัตร (ลบใบเก่า / แจกใบใหม่)
--    4) แจ้ง client ให้ถอดชุดเมืองเก่า + อัปเดต cityId ที่ cache ไว้
--
--  คืน table: { ok, reason, targetName, cityLabel, badgeOk }
-- ═════════════════════════════════════════════════════════════
exports('AdminSetPlayerCity', function(targetId, cityId)
    cityId = SanitizeCityId(cityId or "")
    local cityData = cityId ~= "" and GetCityById(cityId) or nil
    if not cityData then
        return { ok = false, reason = "invalid" }
    end

    targetId = tonumber(targetId)
    if not targetId then
        return { ok = false, reason = "target_gone" }
    end

    local _, targetChar = GetUserAndChar(targetId)
    if not targetChar then
        return { ok = false, reason = "target_gone" }
    end

    local oldCityId = CityManager_GetPlayerCity(targetChar.identifier, targetChar.charIdentifier)
    if oldCityId == cityId then
        return { ok = false, reason = "same_city" }
    end

    -- โควตาเมือง: แอดมินข้ามได้ถ้า Config.Admin.bypassCityFull = true
    if not Config.Admin.bypassCityFull and not CityManager_IsCityAvailable(cityId) then
        return { ok = false, reason = "full" }
    end

    -- 1) DB — upsert (ทับของเดิมได้ ต่างจาก AssignCity ที่เป็น INSERT IGNORE สำหรับการเลือกครั้งแรก)
    CityManager_SetPlayerCity(targetChar.identifier, targetChar.charIdentifier, cityId)

    -- 2) ตัวนับ slot — คืนที่ให้เมืองเก่า แล้วจองที่เมืองใหม่
    --    (IncrementCity คง logic รอบเดิมไว้: ถ้าเต็มทุกเมืองจะรีเซ็ตทั้งกระดานเป็นรอบใหม่)
    if oldCityId then CityManager_DecrementCity(oldCityId) end
    CityManager_IncrementCity(cityId)

    -- 3) สลับบัตร
    local badgeOk = SwapCityBadge(targetId, cityId)

    -- 4) แจ้ง client เป้าหมาย
    TriggerClientEvent("nx_cityselect:Client:CityChanged", targetId, cityId)

    local targetName = CharName(targetChar)
    Notify(targetId,
        badgeOk and Lang.notify_moved_city:format(cityData.label)
                 or Lang.notify_moved_city_nobadge:format(cityData.label),
        badgeOk and 'success' or 'warning')

    print(("^3[nx_cityselect]^7 admin moved %s (src %d): %s -> %s (badge=%s)")
        :format(targetName, targetId, tostring(oldCityId or "-"), cityId, tostring(badgeOk)))

    Core.AddWebhook(
        "nx_cityselect", "",
        ("Admin moved ^`%s^` from **%s** to **%s** (badge given: %s)")
            :format(targetName, tostring(oldCityId or "-"), cityData.name, tostring(badgeOk)),
        "15105570", "nx_cityselect", "", "", ""
    )

    return {
        ok         = true,
        targetName = targetName,
        cityLabel  = cityData.label,
        oldCityId  = oldCityId,
        badgeOk    = badgeOk,
    }
end)

-- ═════════════════════════════════════════════════════════════
--  EXPORT: AdminSetPlayerHeritage(targetId, heritageId)
--  เปลี่ยนเชื้อสาย + เปลี่ยน job ของตัวละครตาม (nx_crafting gate สูตรด้วย job)
--  คืน table: { ok, reason, targetName, heritageName }
-- ═════════════════════════════════════════════════════════════
exports('AdminSetPlayerHeritage', function(targetId, heritageId)
    heritageId = SanitizeId(heritageId or "")
    local heritageData = heritageId ~= "" and GetHeritageById(heritageId) or nil
    if not heritageData then
        return { ok = false, reason = "invalid" }
    end

    targetId = tonumber(targetId)
    if not targetId then
        return { ok = false, reason = "target_gone" }
    end

    local _, targetChar = GetUserAndChar(targetId)
    if not targetChar then
        return { ok = false, reason = "target_gone" }
    end

    local oldHeritage = HeritageManager_GetPlayerHeritage(targetChar.identifier, targetChar.charIdentifier)
    if oldHeritage == heritageId then
        return { ok = false, reason = "same_heritage" }
    end

    HeritageManager_SetPlayerHeritage(targetChar.identifier, targetChar.charIdentifier, heritageId)

    -- pcall แบบเดียวกับตอนเลือกครั้งแรกใน sv_main.lua — DB commit ไปแล้ว
    -- ถ้า setJob (หรือ listener ของ resource อื่น) throw ต้องไม่ทำให้ผู้เรียกพัง
    local jobOk, jobErr = pcall(function() targetChar.setJob(heritageId, true) end)
    if not jobOk then
        print(("^1[nx_cityselect] ERROR: setJob(%s) failed for target %d: %s^0")
            :format(heritageId, targetId, tostring(jobErr)))
    end

    TriggerClientEvent("nx_cityselect:Client:HeritageChanged", targetId, heritageId)

    local targetName = CharName(targetChar)
    Notify(targetId, Lang.notify_changed_heritage:format(heritageData.name), 'success')

    print(("^3[nx_cityselect]^7 admin changed heritage of %s (src %d): %s -> %s")
        :format(targetName, targetId, tostring(oldHeritage or "-"), heritageId))

    Core.AddWebhook(
        "nx_cityselect", "",
        ("Admin changed ^`%s^` heritage from **%s** to **%s**")
            :format(targetName, tostring(oldHeritage or "-"), heritageData.name),
        "15105570", "nx_cityselect", "", "", ""
    )

    return {
        ok           = true,
        targetName   = targetName,
        heritageName = heritageData.name,
        jobApplied   = jobOk,
    }
end)
