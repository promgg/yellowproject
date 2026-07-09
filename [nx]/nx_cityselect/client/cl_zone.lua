-- client/cl_zone.lua
-- Territory zone detection (PolyZone), minimap blips, HUD indicator

local currentZone  = nil   -- cityId of zone the player is currently in
local zoneBlips    = {}    -- blip handles for territory markers
local zoneObjects  = {}    -- PolyZone objects
local playerCityId = nil   -- own city, set after assignment

-- ─────────────────────────────────────────────────────────────
--  INTERNAL: Remove all territory blips
-- ─────────────────────────────────────────────────────────────
local function ClearBlips()
    for _, blip in ipairs(zoneBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    zoneBlips = {}
end

-- ─────────────────────────────────────────────────────────────
--  INTERNAL: Add territory radius blip for a city
-- ─────────────────────────────────────────────────────────────
local function AddTerritoryBlip(city)
    -- Use center of bounding box of zone points
    local sumX, sumY, count = 0, 0, 0
    for _, pt in ipairs(city.zones) do
        sumX = sumX + pt.x
        sumY = sumY + pt.y
        count = count + 1
    end
    if count == 0 then return end

    local cx = sumX / count
    local cy = sumY / count
    local cz = (city.minZ + city.maxZ) / 2

    -- Estimate rough radius from zone extents
    local maxDist = 0
    for _, pt in ipairs(city.zones) do
        local d = math.sqrt((pt.x - cx)^2 + (pt.y - cy)^2)
        if d > maxDist then maxDist = d end
    end

    -- RDR3: BlipAddForRadius (0x45F13B7E0A15C880)
    local blip = Citizen.InvokeNative(0x45F13B7E0A15C880, -1282792512, cx, cy, cz, maxDist * 1.1)

    -- RDR3: BlipAddModifier (0x662D364ABF16DE2F) for color
    local r, g, b = city.color.r, city.color.g, city.color.b
    local colorName
    if r > g and r > b then
        colorName = 'BLIP_MODIFIER_MP_COLOR_10'  -- red
    elseif g > r and g > b then
        colorName = 'BLIP_MODIFIER_MP_COLOR_8'   -- green
    elseif b > r and b > g then
        colorName = 'BLIP_MODIFIER_MP_COLOR_1'   -- light blue
    else
        colorName = 'BLIP_MODIFIER_MP_COLOR_4'   -- orange/gold
    end
    Citizen.InvokeNative(0x662D364ABF16DE2F, blip, joaat(colorName))

    table.insert(zoneBlips, blip)
end

-- ─────────────────────────────────────────────────────────────
--  INTERNAL: Notify player of zone change
-- ─────────────────────────────────────────────────────────────
local function OnZoneEnter(city)
    currentZone = city.id
    local isOwn = (playerCityId == city.id)
    local subtitle = isOwn and Lang.territory_own or Lang.territory_foreign

    TriggerEvent("nx_cityselect:Client:ZoneChanged", city.id, isOwn)

    -- Push HUD territory label update to NUI
    SendNUIMessage({
        action     = "SET_TERRITORY",
        zoneName   = city.label,
        color      = city.color,
        isOwnCity  = isOwn,
    })
end

local function OnZoneExit(city)
    if currentZone == city.id then
        currentZone = nil
        TriggerEvent("nx_cityselect:Client:ZoneChanged", nil, false)
        SendNUIMessage({ action = "SET_TERRITORY", zoneName = nil })
    end
end

-- ─────────────────────────────────────────────────────────────
--  INTERNAL: Build PolyZones for all cities
-- ─────────────────────────────────────────────────────────────
local function InitZones()
    -- Clear existing zones
    for _, zone in ipairs(zoneObjects) do
        zone:destroy()
    end
    zoneObjects = {}
    ClearBlips()

    for _, city in ipairs(Config.Cities) do
        if #city.zones >= 3 then
            local cityRef = city  -- capture

            local zone = PolyZone:Create(city.zones, {
                name     = "nx_city_" .. city.id,
                minZ     = city.minZ,
                maxZ     = city.maxZ,
                debugPoly = Config.Debug,
            })

            zone:onPlayerInOut(function(isInside, _point)
                if isInside then
                    OnZoneEnter(cityRef)
                else
                    OnZoneExit(cityRef)
                end
            end)

            table.insert(zoneObjects, zone)
            AddTerritoryBlip(city)
        end
    end
end

-- ─────────────────────────────────────────────────────────────
--  EVENT: City assigned — store own city for comparisons
-- ─────────────────────────────────────────────────────────────
AddEventHandler("nx_cityselect:Client:CityAssigned", function(cityId)
    playerCityId = cityId
end)

-- ─────────────────────────────────────────────────────────────
--  EVENT: Character spawned — initialise zones
-- ─────────────────────────────────────────────────────────────
RegisterNetEvent("vorp:SelectedCharacter")
AddEventHandler("vorp:SelectedCharacter", function()
    Wait(Config.SpawnFreezeTime + 500)
    InitZones()
end)

-- ─────────────────────────────────────────────────────────────
--  CLIENT EXPORT: GetCurrentZone
--  Returns { cityId, name, label, color, isOwnCity } or nil
-- ─────────────────────────────────────────────────────────────
exports("GetCurrentZone", function()
    if not currentZone then return nil end
    local city = GetCityById(currentZone)
    if not city then return nil end
    return {
        cityId    = city.id,
        name      = city.name,
        label     = city.label,
        color     = city.color,
        isOwnCity = (playerCityId == city.id),
    }
end)

-- ─────────────────────────────────────────────────────────────
--  CLIENT EXPORT: IsInOwnCity
-- ─────────────────────────────────────────────────────────────
exports("IsInOwnCity", function()
    if not currentZone or not playerCityId then return false end
    return currentZone == playerCityId
end)

-- ─────────────────────────────────────────────────────────────
--  CLIENT EXPORT: GetPlayerCityData (client-side)
-- ─────────────────────────────────────────────────────────────
exports("GetPlayerCityData", function()
    if not playerCityId then return nil end
    local city = GetCityById(playerCityId)
    if not city then return nil end
    return {
        cityId      = city.id,
        name        = city.name,
        label       = city.label,
        description = city.description,
        color       = city.color,
        spawnPoint  = city.spawnPoint,
    }
end)
