-- server/sv_exports.lua
-- Server-side export functions for use by other resources

local Core = exports.vorp_core:GetCore()

-- ─────────────────────────────────────────────────────────────
--  Point-in-polygon (ray casting) — PolyZone itself has NO server-side
--  polygon math (its server.lua is just a TriggerClientEvent relay), so
--  city-territory checks needed by other server-side resources (e.g.
--  lp_hunting blocking skinning inside city limits) are reimplemented here,
--  reusing the same Config.Cities[i].zones/minZ/maxZ data the client's
--  PolyZone instances are built from.
-- ─────────────────────────────────────────────────────────────
local function isPointInPolygon(x, y, poly)
    local inside = false
    local j = #poly
    for i = 1, #poly do
        local xi, yi = poly[i].x, poly[i].y
        local xj, yj = poly[j].x, poly[j].y
        if ((yi > y) ~= (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi) + xi) then
            inside = not inside
        end
        j = i
    end
    return inside
end

-- coords: vector3 or { x=, y=, z= } (z optional — if omitted, only the 2D
-- polygon is checked, minZ/maxZ is skipped)
local function getCityAtCoords(coords)
    if not coords or not coords.x or not coords.y then return nil end
    local z = coords.z
    for _, city in ipairs(Config.Cities) do
        if #city.zones >= 3 and (not z or (z >= city.minZ and z <= city.maxZ)) then
            if isPointInPolygon(coords.x, coords.y, city.zones) then
                return city.id
            end
        end
    end
    return nil
end

-- ─────────────────────────────────────────────────────────────
--  GetCityAtCoords(coords) -> cityId string, or nil if outside every city
-- ─────────────────────────────────────────────────────────────
exports("GetCityAtCoords", getCityAtCoords)

-- ─────────────────────────────────────────────────────────────
--  IsCoordsInAnyCity(coords) -> bool
-- ─────────────────────────────────────────────────────────────
exports("IsCoordsInAnyCity", function(coords)
    return getCityAtCoords(coords) ~= nil
end)

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
