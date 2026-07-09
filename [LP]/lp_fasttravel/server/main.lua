-- server/main.lua
-- lp_fasttravel — Station list callback | Job/cooldown/money validation | Travel

local Core = exports.vorp_core:GetCore()
local lastTravel = {} -- [source] = os.time() of last successful travel

local StationsById = {}
for _, s in ipairs(Config.Stations) do
    StationsById[s.id] = s
end

local function CheckPlayerJob(charJob, jobGrade, station)
    if not station.jobsEnabled then return true end
    for _, job in ipairs(station.jobs or {}) do
        if charJob == job.name and (jobGrade or 0) >= job.grade then
            return true
        end
    end
    return false
end

local function DistanceKm(a, b)
    local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
    return math.sqrt(dx * dx + dy * dy + dz * dz) / 1000.0
end

local function CalcPrice(station, distKm)
    if station.priceOverride then return math.floor(station.priceOverride) end
    return math.max(1, math.floor((distKm * Config.PricePerKm) + 0.5))
end

Core.Callback.Register('lp_fasttravel:GetStations', function(source, cb)
    local user = Core.getUser(source)
    if not user then cb(nil) return end
    local char = user.getUsedCharacter
    if not char then cb(nil) return end

    local pos = GetEntityCoords(GetPlayerPed(source))

    local remaining = 0
    if lastTravel[source] then
        remaining = math.max(0, Config.Cooldown - (os.time() - lastTravel[source]))
    end

    local list = {}
    for _, station in ipairs(Config.Stations) do
        if CheckPlayerJob(char.job, char.jobGrade, station) then
            local distKm = DistanceKm(pos, station.coords)
            list[#list + 1] = {
                id          = station.id,
                name        = station.name,
                description = station.description,
                image       = station.image,
                color       = station.color,
                distanceKm  = math.floor(distKm * 100 + 0.5) / 100,
                price       = CalcPrice(station, distKm),
                isCurrent   = (distKm * 1000.0) <= Config.CurrentStationRadius,
            }
        end
    end

    cb({ stations = list, cooldown = remaining })
end)

Core.Callback.Register('lp_fasttravel:Travel', function(source, cb, stationId)
    local user = Core.getUser(source)
    if not user then cb({ ok = false, reason = 'no_user' }) return end
    local char = user.getUsedCharacter
    if not char then cb({ ok = false, reason = 'no_char' }) return end

    local station = StationsById[stationId]
    if not station then cb({ ok = false, reason = 'invalid_station' }) return end

    if not CheckPlayerJob(char.job, char.jobGrade, station) then
        cb({ ok = false, reason = 'no_job' })
        return
    end

    if lastTravel[source] and (os.time() - lastTravel[source]) < Config.Cooldown then
        cb({ ok = false, reason = 'cooldown' })
        return
    end

    local pos    = GetEntityCoords(GetPlayerPed(source))
    local distKm = DistanceKm(pos, station.coords)

    if (distKm * 1000.0) <= Config.CurrentStationRadius then
        cb({ ok = false, reason = 'already_here' })
        return
    end

    local price = CalcPrice(station, distKm)
    if (char.money or 0) < price then
        cb({ ok = false, reason = 'no_money' })
        return
    end

    char.removeCurrency(0, price) -- 0 = cash
    lastTravel[source] = os.time()

    cb({ ok = true, coords = station.coords, heading = station.heading, price = price })
end)

-- ─── Player drop cleanup ─────────────────────────────────────────────────────
AddEventHandler('playerDropped', function()
    lastTravel[source] = nil
end)
