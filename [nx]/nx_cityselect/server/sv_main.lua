-- server/sv_main.lua
-- Core server logic: callbacks, city selection, item use, security

local Core = exports.vorp_core:GetCore()
local Inv  = exports.vorp_inventory

-- Per-source cooldown table to prevent selection spam (ms timestamp)
local selectionCooldowns = {}
local SELECTION_COOLDOWN  = 5000  -- 5 seconds between attempts

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

-- ─────────────────────────────────────────────────────────────
--  CALLBACK: CheckPlayerCity
--  Client asks: does this character already have a city?
--  Response: { hasCity, cityId, cityData } or { hasCity = false }
-- ─────────────────────────────────────────────────────────────
Core.Callback.Register("nx_cityselect:CheckPlayerCity", function(source, cb)
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

    -- 7. Assign city in DB
    CityManager_AssignCity(char.identifier, char.charIdentifier, cityId)

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
--  ITEM USE: Badge items → trigger outfit change on client
-- ─────────────────────────────────────────────────────────────
AddEventHandler("onResourceStart", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for _, city in ipairs(Config.Cities) do
        -- capture loop variable
        local citySnapshot = city
        Inv:registerUsableItem(citySnapshot.badgeItem, function(data)
            local source   = data.source
            local user, char = GetUserAndChar(source)
            if not user or not char then return end

            -- Verify the user actually belongs to this city (prevent fake item use)
            local assignedCity = CityManager_GetPlayerCity(char.identifier, char.charIdentifier)
            if assignedCity ~= citySnapshot.id then
                Core.NotifyTip(source, "บัตรนี้ไม่ใช่ของคุณ", 3000)
                return
            end

            TriggerClientEvent("nx_cityselect:Client:ApplyOutfit", source, {
                outfit      = citySnapshot.outfit,
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
end)
