-- server/sv_main.lua
-- Core server logic: callbacks, city selection, item use, security

local Core = exports.vorp_core:GetCore()
local Inv  = exports.vorp_inventory

-- Per-source cooldown table to prevent selection spam (ms timestamp)
local selectionCooldowns = {}
local SELECTION_COOLDOWN  = 5000  -- 5 seconds between attempts

local heritageCooldowns = {}
local HERITAGE_COOLDOWN  = 5000

-- Lightweight cooldown for the read-only lookup callbacks (no item/money at stake,
-- just stops a modified client hammering these DB-backed queries)
local readCooldowns = {}
local READ_COOLDOWN  = 1000

-- ─────────────────────────────────────────────────────────────
--  INTERNAL HELPERS
-- ─────────────────────────────────────────────────────────────

---Retrieve validated VORP user + character for a source
---@param source number
---@return table|nil user, table|nil character
local function GetUserAndChar(source)
    local user = Core.getUser(source)
    if not user then return nil, nil end
    local char = user.getUsedCharacter
    if not char then return nil, nil end
    return user, char
end

---Rate-limit helper: returns true if source is on cooldown
---@param source number
---@return boolean
local function IsOnCooldown(source)
    local last = selectionCooldowns[source]
    if last and (GetGameTimer() - last) < SELECTION_COOLDOWN then
        return true
    end
    return false
end

---Rate-limit helper for heritage selection: returns true if source is on cooldown
---@param source number
---@return boolean
local function IsOnHeritageCooldown(source)
    local last = heritageCooldowns[source]
    if last and (GetGameTimer() - last) < HERITAGE_COOLDOWN then
        return true
    end
    return false
end

---Rate-limit helper for read-only lookups: returns true if source is on cooldown
---@param source number
---@param tag string distinguishes the 4 read callbacks so one doesn't block another
---@return boolean
local function IsOnReadCooldown(source, tag)
    readCooldowns[source] = readCooldowns[source] or {}
    local last = readCooldowns[source][tag]
    if last and (GetGameTimer() - last) < READ_COOLDOWN then
        return true
    end
    readCooldowns[source][tag] = GetGameTimer()
    return false
end

-- ─────────────────────────────────────────────────────────────
--  CALLBACK: CheckPlayerCity
--  Client asks: does this character already have a city?
--  Response: { hasCity, cityId, cityData } or { hasCity = false }
-- ─────────────────────────────────────────────────────────────
Core.Callback.Register("nx_cityselect:CheckPlayerCity", function(source, cb)
    if IsOnReadCooldown(source, "checkCity") then cb(nil); return end

    local user, char = GetUserAndChar(source)
    if not user or not char then
        cb({ hasCity = false })
        return
    end

    local cityId = CityManager_GetPlayerCity(char.identifier, char.charIdentifier)
    if not cityId then
        cb({ hasCity = false })
        return
    end

    local cityData = GetCityById(cityId)
    if not cityData then
        cb({ hasCity = false })
        return
    end

    cb({
        hasCity  = true,
        cityId   = cityId,
        cityName = cityData.name,
        label    = cityData.label,
        spawn    = cityData.spawnPoint,
    })
end)

-- ─────────────────────────────────────────────────────────────
--  CALLBACK: GetCityData
--  Client requests city list with current slot counts
--  Response: array of city objects with availability
-- ─────────────────────────────────────────────────────────────
Core.Callback.Register("nx_cityselect:GetCityData", function(source, cb)
    if IsOnReadCooldown(source, "getCity") then cb(nil); return end

    local counts  = CityManager_GetCounts()
    local payload = {}

    for _, city in ipairs(Config.Cities) do
        local slotInfo = counts[city.id] or { count = 0, available = true }
        table.insert(payload, {
            id          = city.id,
            name        = city.name,
            label       = city.label,
            description = city.description,
            color       = city.color,
            count       = slotInfo.count,
            max         = Config.MaxPlayersPerCity,
            available   = slotInfo.available,
        })
    end

    cb(payload)
end)

-- ─────────────────────────────────────────────────────────────
--  CALLBACK: SelectCity
--  Player submits city selection from UI
--  Full server-side validation before committing
-- ─────────────────────────────────────────────────────────────
Core.Callback.Register("nx_cityselect:SelectCity", function(source, cb, cityId)
    -- 1. Sanitize input
    cityId = SanitizeCityId(cityId or "")
    if cityId == "" then
        cb({ success = false, reason = "invalid" })
        return
    end

    -- 2. Validate city exists in config
    local cityData = GetCityById(cityId)
    if not cityData then
        cb({ success = false, reason = "invalid" })
        return
    end

    -- 3. Rate limit
    if IsOnCooldown(source) then
        cb({ success = false, reason = "cooldown" })
        return
    end
    selectionCooldowns[source] = GetGameTimer()

    -- 4. Validate VORP user
    local user, char = GetUserAndChar(source)
    if not user or not char then
        cb({ success = false, reason = "nochar" })
        return
    end

    -- 5. Verify character doesn't already have a city
    local existing = CityManager_GetPlayerCity(char.identifier, char.charIdentifier)
    if existing then
        cb({ success = false, reason = "already_selected" })
        return
    end

    -- 6. Re-check availability at time of selection (not just at UI open)
    if not CityManager_IsCityAvailable(cityId) then
        cb({ success = false, reason = "full" })
        return
    end

    -- 7. Assign city in DB — atomic compare-and-set; a concurrent double-fire for
    -- the same character can only ever have one winner (step 5 above is just a fast-path,
    -- not the actual race guard)
    local assigned = CityManager_AssignCity(char.identifier, char.charIdentifier, cityId)
    if not assigned then
        cb({ success = false, reason = "already_selected" })
        return
    end

    -- 8. Increment slot count (and trigger cycle reset if all full)
    CityManager_IncrementCity(cityId)

    -- 9. Give badge item (server-authoritative)
    local addResult = Inv:addItem(source, cityData.badgeItem, 1)
    if Config.Debug and not addResult then
        print(("^3[nx_cityselect]^7 Warning: could not give badge item '%s' to source %d"):format(cityData.badgeItem, source))
    end

    -- 10. Log via VORP webhook if configured
    Core.AddWebhook(
        "nx_cityselect",
        "",  -- fill in your webhook URL in config if desired
        ("Player ^`%s^` selected city **%s**"):format(GetPlayerName(source), cityData.name),
        "3066993", "nx_cityselect", "", "", ""
    )

    cb({
        success    = true,
        cityId     = cityId,
        cityName   = cityData.name,
        label      = cityData.label,
        spawn      = cityData.spawnPoint,
        badgeItem  = cityData.badgeItem,
    })
end)

-- ─────────────────────────────────────────────────────────────
--  CALLBACK: CheckPlayerHeritage
--  Client asks: does this character already have a heritage?
-- ─────────────────────────────────────────────────────────────
Core.Callback.Register("nx_cityselect:CheckPlayerHeritage", function(source, cb)
    if IsOnReadCooldown(source, "checkHeritage") then cb(nil); return end

    local user, char = GetUserAndChar(source)
    if not user or not char then
        cb({ hasHeritage = false })
        return
    end

    local heritageId = HeritageManager_GetPlayerHeritage(char.identifier, char.charIdentifier)
    if not heritageId then
        cb({ hasHeritage = false })
        return
    end

    local heritageData = GetHeritageById(heritageId)
    if not heritageData then
        cb({ hasHeritage = false })
        return
    end

    cb({
        hasHeritage = true,
        heritageId  = heritageId,
        name        = heritageData.name,
        label       = heritageData.label,
    })
end)

-- ─────────────────────────────────────────────────────────────
--  CALLBACK: GetHeritageData
--  Client requests the list of selectable heritages
-- ─────────────────────────────────────────────────────────────
Core.Callback.Register("nx_cityselect:GetHeritageData", function(source, cb)
    if IsOnReadCooldown(source, "getHeritage") then cb(nil); return end

    local payload = {}
    for _, heritage in ipairs(Config.Heritages) do
        table.insert(payload, {
            id          = heritage.id,
            name        = heritage.name,
            label       = heritage.label,
            description = heritage.description,
        })
    end
    cb(payload)
end)

-- ─────────────────────────────────────────────────────────────
--  CALLBACK: SelectHeritage
--  Player submits heritage selection from UI
--  Full server-side validation before committing + sets character job
-- ─────────────────────────────────────────────────────────────
Core.Callback.Register("nx_cityselect:SelectHeritage", function(source, cb, heritageId)
    heritageId = SanitizeId(heritageId or "")
    if heritageId == "" then
        cb({ success = false, reason = "invalid" })
        return
    end

    local heritageData = GetHeritageById(heritageId)
    if not heritageData then
        cb({ success = false, reason = "invalid" })
        return
    end

    if IsOnHeritageCooldown(source) then
        cb({ success = false, reason = "cooldown" })
        return
    end
    heritageCooldowns[source] = GetGameTimer()

    local user, char = GetUserAndChar(source)
    if not user or not char then
        cb({ success = false, reason = "nochar" })
        return
    end

    local existing = HeritageManager_GetPlayerHeritage(char.identifier, char.charIdentifier)
    if existing then
        cb({ success = false, reason = "already_selected" })
        return
    end

    local assigned = HeritageManager_AssignHeritage(char.identifier, char.charIdentifier, heritageId)
    if not assigned then
        cb({ success = false, reason = "already_selected" })
        return
    end
    -- pcall: the DB assignment above already committed — an error from setJob (or from some other
    -- resource's vorp:playerJobChange listener) must not stop cb() from firing, or the client hangs frozen forever
    local jobOk, jobErr = pcall(function() char.setJob(heritageId, true) end)
    if not jobOk then
        print(("^1[nx_cityselect] ERROR: char.setJob(%s) failed for source %d: %s^0"):format(heritageId, source, tostring(jobErr)))
    end

    Core.AddWebhook(
        "nx_cityselect",
        "",
        ("Player ^`%s^` selected heritage **%s**"):format(GetPlayerName(source), heritageData.name),
        "3066993", "nx_cityselect", "", "", ""
    )

    cb({
        success    = true,
        heritageId = heritageId,
        name       = heritageData.name,
        label      = heritageData.label,
    })
end)

-- ─────────────────────────────────────────────────────────────
--  ITEM USE: Badge items → trigger outfit change on client
-- ─────────────────────────────────────────────────────────────
AddEventHandler("onResourceStart", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for _, city in ipairs(Config.Cities) do
        -- capture loop variable
        local citySnapshot = city
        Inv:registerUsableItem(citySnapshot.badgeItem, function(data)
            local source   = data.source
            -- DEBUG ไล่หาจุดที่หยุด — ลบออกเมื่อแก้เสร็จ
            print(('^3[nx_cityselect DBG]^7 ใช้บัตร %s src=%s'):format(citySnapshot.badgeItem, tostring(source)))
            local user, char = GetUserAndChar(source)
            if not user or not char then
                print('^1[nx_cityselect DBG]^7 หยุด: ไม่พบ user/char')
                return
            end

            -- Verify the user actually belongs to this city (prevent fake item use)
            local assignedCity = CityManager_GetPlayerCity(char.identifier, char.charIdentifier)
            print(('^3[nx_cityselect DBG]^7 assignedCity=%s ต้องเป็น=%s')
                :format(tostring(assignedCity), citySnapshot.id))
            if assignedCity ~= citySnapshot.id then
                TriggerClientEvent('pNotify:SendNotification', source, { type = 'error', text = 'บัตรนี้ไม่ใช่ของคุณ', timeout = 3000 })
                return
            end

            TriggerClientEvent("nx_cityselect:Client:ApplyOutfit", source, {
                cityId      = citySnapshot.id,
                outfitTag   = citySnapshot.outfitTag,
                outfitProps = citySnapshot.outfitProps,
                cityName    = citySnapshot.name,
                label       = citySnapshot.label,
            })
        end, "nx_cityselect")
    end
end)

-- ─────────────────────────────────────────────────────────────
--  Clean up cooldown table when player drops
-- ─────────────────────────────────────────────────────────────
AddEventHandler("playerDropped", function()
    local source = source
    selectionCooldowns[source] = nil
    heritageCooldowns[source] = nil
    readCooldowns[source] = nil
end)
