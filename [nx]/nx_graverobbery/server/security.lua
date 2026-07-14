NX_GR = NX_GR or {}
NX_GR.Security = {}

local rateLimits = {} -- [source] = { [eventName] = { count, resetAt } } — nested per-source เพื่อเคลียร์ตอน playerDropped ได้ในทีเดียว
local suspiciousCounts = {}

local function now()
    return os.time()
end

function NX_GR.Security.Log(source, eventName, reason, data)
    data = data or {}
    local character = data.character or (source and source > 0 and NX_GR.VORP.GetCharacter(source))
    local identifier = source and source > 0 and NX_GR.VORP.GetIdentifier(source) or nil

    if Config.Logging.console then
        print(('[nx_graverobbery] security source=%s char=%s grave=%s village=%s event=%s reason=%s'):format(
            tostring(source),
            character and character.charIdentifier or 'nil',
            data.graveId or 'nil',
            data.villageId or 'nil',
            eventName,
            reason
        ))
    end

    if Config.Logging.database then
        MySQL.insert(
            'INSERT INTO nx_graverobbery_security_log (source, identifier, character_id, grave_id, village_id, event_name, reason) VALUES (?, ?, ?, ?, ?, ?, ?)',
            {
                source,
                identifier,
                character and character.charIdentifier or nil,
                data.graveId,
                data.villageId,
                eventName,
                reason,
            }
        )
    end
end

function NX_GR.Security.CheckRateLimit(source, eventName)
    local perSource = rateLimits[source]
    if not perSource then
        perSource = {}
        rateLimits[source] = perSource
    end

    local entry = perSource[eventName]
    local current = now()
    if not entry or current >= entry.resetAt then
        perSource[eventName] = { count = 1, resetAt = current + 60 }
        return true
    end

    entry.count = entry.count + 1
    if entry.count > Config.Security.maxRequestsPerMinute then
        suspiciousCounts[source] = (suspiciousCounts[source] or 0) + 1
        NX_GR.Security.Log(source, eventName, 'rate_limited')

        local threshold = Config.Security.suspiciousRequestThreshold or 0
        if threshold > 0 and suspiciousCounts[source] == threshold then
            NX_GR.Security.Log(source, eventName, 'suspicious_threshold_reached')
        end

        return false
    end

    return true
end

-- เรียกตอน playerDropped กัน rateLimits/suspiciousCounts โตค้างไม่มีที่สิ้นสุด
-- (ไม่งั้น source เดิมโดน reuse เร็วๆ อาจรับ counter ค้างของ session ก่อนหน้าไปด้วย)
function NX_GR.Security.ClearPlayer(source)
    rateLimits[source] = nil
    suspiciousCounts[source] = nil
end

function NX_GR.Security.GetPlayerCoords(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return nil end
    return GetEntityCoords(ped)
end

function NX_GR.Security.IsAliveAndOnFoot(source, character)
    if character and character.isDead then return false end

    local ped = GetPlayerPed(source)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return false end

    local okDead, isDead = pcall(IsEntityDead, ped)
    if okDead and isDead then return false end

    local okVehicle, inVehicle = pcall(IsPedInAnyVehicle, ped, false)
    if okVehicle and inVehicle then return false end

    local okMount, onMount = pcall(IsPedOnMount, ped)
    if okMount and onMount then return false end

    return true
end

function NX_GR.Security.IsNearGrave(source, grave, tolerance)
    local coords = NX_GR.Security.GetPlayerCoords(source)
    if not coords then return false, nil end

    local allowed = (grave.interaction and grave.interaction.distance or 2.0) + tolerance
    return NX_GR.Distance(coords, grave.coords) <= allowed, coords
end

function NX_GR.Security.IsAllowedTime()
    if not Config.AllowedTime.enabled then return true end

    local hour = GetClockHours and GetClockHours()
    if type(hour) ~= 'number' then return false end

    local startHour = Config.AllowedTime.startHour
    local endHour = Config.AllowedTime.endHour
    if startHour <= endHour then
        return hour >= startHour and hour < endHour
    end
    return hour >= startHour or hour < endHour
end

function NX_GR.Security.NewToken(source, graveId)
    return ('%s:%s:%s:%s:%s'):format(source, graveId, os.time(), math.random(100000, 999999), math.random(100000, 999999))
end
