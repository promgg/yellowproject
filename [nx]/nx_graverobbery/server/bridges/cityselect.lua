NX_GR = NX_GR or {}
NX_GR.CitySelect = {}

function NX_GR.CitySelect.GetPlayerVillageId(source, character)
    if NX_GR.SafeResourceStarted('nx_cityselect') then
        local ok, cityId = pcall(function()
            return exports.nx_cityselect:GetPlayerCityId(source)
        end)
        if ok and cityId then return cityId end
    end

    if not character then return nil end

    local rows = MySQL.query.await(
        'SELECT city_id FROM nx_player_city WHERE identifier = ? AND charidentifier = ? LIMIT 1',
        { character.identifier, tonumber(character.charIdentifier) }
    )
    return rows and rows[1] and rows[1].city_id or nil
end

function NX_GR.CitySelect.GetAllVillages()
    if NX_GR.SafeResourceStarted('nx_cityselect') then
        local ok, cities = pcall(function()
            return exports.nx_cityselect:GetAllCities()
        end)
        if ok and cities then return cities end
    end
    return {}
end

function NX_GR.CitySelect.GetOnlinePlayersInVillage(villageId)
    local result = {}
    for _, playerId in ipairs(GetPlayers()) do
        local source = tonumber(playerId)
        local character = NX_GR.VORP.GetCharacter(source)
        if character then
            local cityId = NX_GR.CitySelect.GetPlayerVillageId(source, character)
            if cityId == villageId then
                result[#result + 1] = { source = source, character = character }
            end
        end
    end
    return result
end

function NX_GR.CitySelect.GetVillageRole()
    return nil
end
