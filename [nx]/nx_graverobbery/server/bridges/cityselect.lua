NX_GR = NX_GR or {}
NX_GR.CitySelect = {}

-- cache ผลลัพธ์ต่อ source กัน MySQL.query.await ยิงซ้ำทุกคนออนไลน์ทุกครั้งที่มี alert dispatch
-- (village ของตัวละครแทบไม่เปลี่ยนกลางเซสชัน, TTL กันกรณีย้ายเมืองจริงๆ ให้ค่อยรีเฟรชเอง)
local villageIdCache = {} -- [source] = { villageId = ..., cachedAt = os.time() }
local CACHE_TTL_SECONDS = 300

function NX_GR.CitySelect.GetPlayerVillageId(source, character)
    local cached = villageIdCache[source]
    if cached and (os.time() - cached.cachedAt) < CACHE_TTL_SECONDS then
        return cached.villageId
    end

    local villageId = nil
    if NX_GR.SafeResourceStarted('nx_cityselect') then
        local ok, cityId = pcall(function()
            return exports.nx_cityselect:GetPlayerCityId(source)
        end)
        if ok and cityId then villageId = cityId end
    end

    if not villageId and character then
        local rows = MySQL.query.await(
            'SELECT city_id FROM nx_player_city WHERE identifier = ? AND charidentifier = ? LIMIT 1',
            { character.identifier, tonumber(character.charIdentifier) }
        )
        villageId = rows and rows[1] and rows[1].city_id or nil
    end

    villageIdCache[source] = { villageId = villageId, cachedAt = os.time() }
    return villageId
end

function NX_GR.CitySelect.InvalidatePlayer(source)
    villageIdCache[source] = nil
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
