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

-- ─── สถานะแอร์ดรอปของสถานีที่ผู้เล่นยืนอยู่ ──────────────────────────────────
-- ปุ่มโผล่เฉพาะสถานีที่ตั้ง airdropTeam ไว้ และเข้าได้เฉพาะทีมของสถานีนั้น
-- เจตนา: lp_airdropteam ฝั่ง server เชื่อ teamId ที่ client ส่งมาตรงๆ ไม่เช็คระยะ
--        เดิมมี "ต้องเดินไปยืนที่ NPC" เป็นตัวผูกทีมกับสถานที่ พอย้ายมาเป็นปุ่มในเมนู
--        ต้องผูกด้วยการจำกัดให้เลือกได้แค่ทีมของสถานีที่เปิดเมนูอยู่แทน
local function AirdropFor(src, station)
    if not station.airdropTeam then return nil end
    if GetResourceState('lp_airdropteam') ~= 'started' then return nil end

    local ok, info = pcall(function()
        return exports.lp_airdropteam:GetJoinState(src)
    end)
    if not ok or type(info) ~= 'table' then return nil end

    local labels = {
        A = 'ทีม A (Valentine)',
        B = 'ทีม B (Rhodes)',
        C = 'ทีม C (Annesburg)',
    }

    return {
        stationId   = station.id, -- NUI ส่งกลับมาตอนกดปุ่ม เพื่อให้ server ตรวจระยะซ้ำได้
        teamLabel   = labels[station.airdropTeam] or station.airdropTeam,
        state       = info.state,
        remainingMs = info.remainingMs or 0,
    }
    -- ไม่ส่ง teamId ไป client เลย — client ไม่จำเป็นต้องรู้ และไม่ควรมีโอกาสส่งค่านี้กลับมาเอง
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
    local airdrop = nil

    for _, station in ipairs(Config.Stations) do
        if CheckPlayerJob(char.job, char.jobGrade, station) then
            local distKm    = DistanceKm(pos, station.coords)
            local isCurrent = (distKm * 1000.0) <= Config.CurrentStationRadius

            list[#list + 1] = {
                id          = station.id,
                name        = station.name,
                description = station.description,
                image       = station.image,
                color       = station.color,
                distanceKm  = math.floor(distKm * 100 + 0.5) / 100,
                price       = CalcPrice(station, distKm),
                isCurrent   = isCurrent,
            }

            -- ส่งเฉพาะของสถานีที่ยืนอยู่ ไม่ส่งทั้งหมด — ไม่ให้ client มีข้อมูลทีมอื่นให้เลือกเลย
            if isCurrent then
                airdrop = AirdropFor(source, station)
            end
        end
    end

    cb({ stations = list, cooldown = remaining, airdrop = airdrop })
end)

-- ─── กดปุ่มเข้าร่วมแอร์ดรอปในเมนู ────────────────────────────────────────────
-- ตรวจซ้ำว่าผู้เล่นยืนอยู่ที่สถานีของทีมนั้นจริง แล้วค่อยบอก client ให้เรียก lp_airdropteam
-- (ตัว lp_airdropteam ตรวจรอบ/ล็อก/เมืองเต็มของมันเองอีกชั้น ตรงนี้เติมแค่เงื่อนไข "ยืนที่ไหน")
Core.Callback.Register('lp_fasttravel:CanJoinAirdrop', function(source, cb, stationId)
    local station = StationsById[stationId]
    if not station or not station.airdropTeam then
        cb({ ok = false, reason = 'invalid_station' })
        return
    end

    local pos = GetEntityCoords(GetPlayerPed(source))
    if #(pos - station.coords) > Config.CurrentStationRadius then
        cb({ ok = false, reason = 'too_far' })
        return
    end

    cb({ ok = true, teamId = station.airdropTeam })
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

    -- วาร์ปไปจุด arrival ไม่ใช่ station.coords — coords คือที่ยืนของ NPC คนเลยไปโผล่ทับตัวมัน
    -- ส่วนราคา/ระยะยังคิดจาก coords เหมือนเดิม (arrival ห่างกันไม่กี่เมตร ไม่มีผลกับราคา)
    cb({
        ok      = true,
        coords  = station.arrival or station.coords,
        heading = station.arrivalHeading or station.heading,
        price   = price,
    })
end)

-- ─── Player drop cleanup ─────────────────────────────────────────────────────
-- source ใน closure นี้ไม่ใช่ตัวแปรของ handler — ต้องจับจาก parameter ไม่งั้นล้างไม่ตรงคน
-- (ของเดิมอ้าง source ลอยๆ ทำให้ cooldown ไม่เคยถูกล้างจริงเลย)
AddEventHandler('playerDropped', function()
    local src = source
    lastTravel[src] = nil
end)
