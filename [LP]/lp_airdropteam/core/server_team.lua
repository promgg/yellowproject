-- core/server_team.lua
-- lp_airdropteam — Team join validation | Safe zone timer | Death/respawn/elimination | Round cleanup
-- แบ่งทีมตามเมืองที่ผู้เล่นสังกัดใน nx_cityselect (ดู Config.Team ใน config.lua)

local TeamsById = {}
for _, t in ipairs(Config.Team.teams) do
    TeamsById[t.id] = t
end

local CityToTeam = {}
for _, t in ipairs(Config.Team.teams) do
    CityToTeam[t.cityId] = t.id
end

local PlayerTeam     = {} -- [src] = teamId
local PlayerRespawns = {} -- [src] = count
local RoundActive    = false
local JoiningLocked  = false
local ZoneOpenAt     = 0  -- GetGameTimer() timestamp (ms) เมื่อ safe zone จะหมดเวลา

local function DBG(fmt, ...)
    print(('[lp_airdropteam:team] ' .. fmt):format(...))
end

local function ResetTeamState()
    PlayerTeam     = {}
    PlayerRespawns = {}
    RoundActive    = false
    JoiningLocked  = false
    ZoneOpenAt     = 0
end

DBG('server_team.lua loaded OK (teams=%d)', #Config.Team.teams)

-- ─── เริ่มรอบทีม: เรียกจาก GameStart() ใน server.lua ──────────────────────────
function StartTeamRound()
    if not (Config.Team and Config.Team.enabled) then return end
    ResetTeamState()
    RoundActive = true
    ZoneOpenAt  = GetGameTimer() + (Config.Team.safeZoneDuration * 1000)

    DBG('StartTeamRound: safeZoneDuration=%ds', Config.Team.safeZoneDuration)

    Citizen.CreateThread(function()
        while RoundActive and GetGameTimer() < ZoneOpenAt do
            Citizen.Wait(1000)
        end
        if RoundActive then
            JoiningLocked = true
            DBG('Zone opened (safe zone timer elapsed)')
            TriggerClientEvent('lp_airdropteam:CL:ZoneOpened', -1)
        end
    end)
end

-- ─── จบรอบทีม: เรียกจาก AirdropAutoDelete()/GameFinish() ใน server.lua ────────
-- วาปทุกคนที่ยังอยู่ในรอบ (ยังไม่ถูกเด้งออก) กลับจุดเข้าร่วมของทีมตัวเอง
function EndTeamRound()
    if not (Config.Team and Config.Team.enabled) then return end
    if not RoundActive and next(PlayerTeam) == nil then return end

    local n = 0
    for src, teamId in pairs(PlayerTeam) do
        local team = TeamsById[teamId]
        if team then
            n = n + 1
            TriggerClientEvent('lp_airdropteam:CL:ReviveAt', src, team.joinCoords, true)
        end
    end
    DBG('EndTeamRound: sent %d player(s) back to their join point', n)

    ResetTeamState()
end

-- ─── เข้าร่วมทีม (client ยิงตอนกดค้าง prompt ที่จุด NPC) ──────────────────────
VORPcore.Callback.Register('lp_airdropteam:JoinTeam', function(source, cb)
    if not (Config.Team and Config.Team.enabled) or not RoundActive then
        cb({ ok = false, reason = 'no_round' })
        return
    end
    if JoiningLocked then
        cb({ ok = false, reason = 'locked' })
        return
    end
    if PlayerTeam[source] then
        cb({ ok = false, reason = 'already_joined' })
        return
    end

    local cityId = exports['nx_cityselect']:GetPlayerCityId(source)
    local teamId = cityId and CityToTeam[cityId]
    if not teamId then
        cb({ ok = false, reason = 'no_team' })
        return
    end

    local team = TeamsById[teamId]
    PlayerTeam[source]     = teamId
    PlayerRespawns[source] = 0

    local remainingMs = math.max(0, ZoneOpenAt - GetGameTimer())
    DBG('src=%d joined team=%s city=%s remainingMs=%d', source, teamId, cityId, remainingMs)

    cb({
        ok             = true,
        teamId         = teamId,
        label          = team.label,
        coords         = team.zoneSpawn,
        remainingMs    = remainingMs,
        safeZoneRadius = Config.Team.safeZoneRadius,
    })
end)

-- ─── ตาย: hook event ที่ MJ-Respwan/core/client.lua ยิงจริง (บรรทัด TriggerServerEvent
-- ("vorp_core:Server:OnPlayerDeath", ...) ในเธรด DEATH HANDLER ของมัน) ─────────────────
-- ตายครั้งที่ <= maxRespawns -> เกิดใหม่ในโซนได้อีก
-- ตายเกิน maxRespawns -> เด้งกลับจุดเข้าร่วม ออกจากรอบถาวร
RegisterNetEvent('vorp_core:Server:OnPlayerDeath')
AddEventHandler('vorp_core:Server:OnPlayerDeath', function(killerServerId, deathCause)
    local src = source
    local teamId = PlayerTeam[src]

    DBG('src=%d vorp_core:Server:OnPlayerDeath received (killer=%s cause=%s)', src, tostring(killerServerId), tostring(deathCause))

    if not teamId then
        DBG('src=%d died but is not in a team round (ignored)', src)
        return
    end
    if not RoundActive then
        DBG('src=%d died but RoundActive=false (round already ended? ignored)', src)
        return
    end

    local team = TeamsById[teamId]
    if not team then return end

    PlayerRespawns[src] = (PlayerRespawns[src] or 0) + 1
    DBG('src=%d team=%s died, respawns=%d/%d', src, teamId, PlayerRespawns[src], Config.Team.maxRespawns)

    if PlayerRespawns[src] <= Config.Team.maxRespawns then
        TriggerClientEvent('lp_airdropteam:CL:ReviveAt', src, team.zoneSpawn, false)
    else
        PlayerTeam[src] = nil
        TriggerClientEvent('lp_airdropteam:CL:ReviveAt', src, team.joinCoords, true)
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    PlayerTeam[src]     = nil
    PlayerRespawns[src] = nil
end)

-- ─── /backapt: ผู้เล่นขอออกจากรอบเองได้ตลอดเวลา วาปกลับจุดเข้าร่วมของทีมตัวเอง ──────────
RegisterCommand('backapt', function(source, args, rawCommand)
    local src = source
    local teamId = PlayerTeam[src]

    if not teamId then
        TriggerClientEvent('pNotify:SendNotification', src, { text = 'คุณไม่ได้เข้าร่วมกิจกรรมอยู่', type = 'error', timeout = 4000 })
        return
    end

    local team = TeamsById[teamId]
    if not team then return end

    DBG('src=%d used /backapt, leaving team=%s voluntarily', src, teamId)

    PlayerTeam[src] = nil
    TriggerClientEvent('lp_airdropteam:CL:ReviveAt', src, team.joinCoords, true)
end, false)
