-- server/sv_exports.lua
-- Server-side export functions for use by other resources

local Core = exports.vorp_core:GetCore()

-- ─────────────────────────────────────────────────────────────
--  GetPlayerCity(source)
--  Returns city config table enriched with slot info, or nil
-- ─────────────────────────────────────────────────────────────
exports("GetPlayerCity", function(source)
    if not source then return nil end

    local user = Core.getUser(source)
    if not user then return nil end

    local char = user.getUsedCharacter
    if not char then return nil end

    local cityId = CityManager_GetPlayerCity(char.identifier, char.charIdentifier)
    if not cityId then return nil end

    local cityData = GetCityById(cityId)
    if not cityData then return nil end

    return {
        id          = cityData.id,
        name        = cityData.name,
        label       = cityData.label,
        description = cityData.description,
        color       = cityData.color,
        spawnPoint  = cityData.spawnPoint,
        badgeItem   = cityData.badgeItem,
    }
end)

-- ─────────────────────────────────────────────────────────────
--  GetPlayerCityId(source)
--  Returns just the cityId string, or nil
-- ─────────────────────────────────────────────────────────────
exports("GetPlayerCityId", function(source)
    if not source then return nil end

    local user = Core.getUser(source)
    if not user then return nil end

    local char = user.getUsedCharacter
    if not char then return nil end

    return CityManager_GetPlayerCity(char.identifier, char.charIdentifier)
end)

-- ─────────────────────────────────────────────────────────────
--  GetAllCities()
--  Returns the full Config.Cities array (read-only copy)
-- ─────────────────────────────────────────────────────────────
exports("GetAllCities", function()
    local result = {}
    for _, city in ipairs(Config.Cities) do
        table.insert(result, {
            id          = city.id,
            name        = city.name,
            label       = city.label,
            description = city.description,
            color       = city.color,
            spawnPoint  = city.spawnPoint,
            badgeItem   = city.badgeItem,
        })
    end
    return result
end)

-- ─────────────────────────────────────────────────────────────
--  GetCityCounts()
--  Returns { [cityId] = { count, max, available } }
-- ─────────────────────────────────────────────────────────────
exports("GetCityCounts", function()
    local raw    = CityManager_GetCounts()
    local result = {}
    for cityId, info in pairs(raw) do
        result[cityId] = {
            count     = info.count,
            max       = Config.MaxPlayersPerCity,
            available = info.available,
        }
    end
    return result
end)
