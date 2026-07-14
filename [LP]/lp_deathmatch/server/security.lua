LP_DM = LP_DM or {}
LP_DM.Security = {}

local rateLimits = {} -- [source] = { [eventName] = { count, resetAt } } — nested per-source เพื่อเคลียร์ตอน playerDropped ได้ในทีเดียว
local suspiciousCounts = {}

local function now()
    return os.time()
end

function LP_DM.Security.Log(source, eventName, reason, data)
    data = data or {}
    local identifier = source and source > 0 and LP_DM.VORP.GetIdentifier(source) or nil

    if Config.Logging.console then
        print(('[lp_deathmatch] security source=%s identifier=%s event=%s reason=%s'):format(
            tostring(source), tostring(identifier), eventName, tostring(reason)
        ))
    end
end

function LP_DM.Security.CheckRateLimit(source, eventName)
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
        LP_DM.Security.Log(source, eventName, 'rate_limited')

        local threshold = Config.Security.suspiciousRequestThreshold or 0
        if threshold > 0 and suspiciousCounts[source] == threshold then
            LP_DM.Security.Log(source, eventName, 'suspicious_threshold_reached')
        end

        return false
    end

    return true
end

-- เรียกตอน playerDropped กัน rateLimits/suspiciousCounts โตค้างไม่มีที่สิ้นสุด
function LP_DM.Security.ClearPlayer(source)
    rateLimits[source] = nil
    suspiciousCounts[source] = nil
end

function LP_DM.Security.GetPlayerCoords(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return nil end
    return GetEntityCoords(ped)
end

-- ระยะระหว่างผู้ฆ่ากับเหยื่อ ณ ตอนรายงาน — กันรายงานเท็จข้ามแมพ (ผู้เล่นทั้งคู่ต้องออนไลน์และอยู่ในระยะที่สมเหตุสมผล)
function LP_DM.Security.ArePlausiblyNear(sourceA, sourceB, tolerance)
    local coordsA = LP_DM.Security.GetPlayerCoords(sourceA)
    local coordsB = LP_DM.Security.GetPlayerCoords(sourceB)
    if not coordsA or not coordsB then return false end

    return LP_DM.Distance(coordsA, coordsB) <= (tolerance or Config.Security.maxKillDistance)
end
