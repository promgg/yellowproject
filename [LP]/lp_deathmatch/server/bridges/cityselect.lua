LP_DM = LP_DM or {}
LP_DM.CitySelect = {}

-- cache ผลลัพธ์ต่อ source กัน MySQL query ยิงซ้ำทุกคนออนไลน์ทุกครั้งที่ตรวจสอบ (เช่นตอนจบอีเว้นท์แจกรางวัล)
local villageIdCache = {} -- [source] = { villageId = ..., cachedAt = os.time() }
local CACHE_TTL_SECONDS = 300

function LP_DM.CitySelect.GetPlayerVillageId(source, character)
    local cached = villageIdCache[source]
    if cached and (os.time() - cached.cachedAt) < CACHE_TTL_SECONDS then
        return cached.villageId
    end

    local villageId = nil
    if LP_DM.SafeResourceStarted('nx_cityselect') then
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

function LP_DM.CitySelect.InvalidatePlayer(source)
    villageIdCache[source] = nil
end
