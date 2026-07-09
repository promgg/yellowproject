-- core/server_team.lua
-- lp_airdropteam — Team join validation | Safe zone timer | Death/respawn/elimination | Round cleanup
-- 2 แกนแยกอิสระ: โซนสู้กัน (battle team) ผูกกับเมืองใน nx_cityselect เสมอ ส่วนจุดเข้า/จุดออก
-- (entry team) คือ NPC สถานีที่กดค้างเข้าร่วมจริง เข้าได้ทุกสถานีไม่ว่าเมืองอะไร แต่ออกจากรอบทาง
-- ไหนก็ตามจะกลับไปที่สถานีเดิมที่เข้ามาเสมอ ดู Config.Team ใน config.lua

local TeamsById = {}
for _, t in ipairs(Config.Team.teams) do
    TeamsById[t.id] = t
end

local CityToTeam = {}
for _, t in ipairs(Config.Team.teams) do
    CityToTeam[t.cityId] = t.id
end

local PlayerTeam      = {} -- [src] = battle teamId (โซนสู้กัน/เกิดใหม่ในรอบ — ผูกกับเมือง)
local PlayerEntryTeam = {} -- [src] = entry teamId (จุดเข้า/จุดออก — ผูกกับ NPC ที่กดจริง)
local PlayerRespawns  = {} -- [src] = count
local RoundActive     = false
local JoiningLocked   = false
local ZoneOpenAt      = 0  -- GetGameTimer() timestamp (ms) เมื่อ safe zone จะหมดเวลา

local function DBG(fmt, ...)
    print(('[lp_airdropteam:team] ' .. fmt):format(...))
end

local function ResetTeamState()
    PlayerTeam      = {}
    PlayerEntryTeam = {}
    PlayerRespawns  = {}
    RoundActive     = false
    JoiningLocked   = false
    ZoneOpenAt      = 0
end

-- จุดที่จะส่งผู้เล่นกลับไปเมื่อออกจากรอบ (ตายครั้งที่ 2 / backapt / จบรอบ): สถานีที่เข้ามาจริง
-- ถ้าหาไม่เจอ (ไม่ควรเกิด) fallback กลับไปใช้ battle team กันเหตุ error
local function ReturnTeamFor(src)
    return TeamsById[PlayerEntryTeam[src]] or TeamsById[PlayerTeam[src]]
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
-- วาปทุกคนที่ยังอยู่ในรอบ (ยังไม่ถูกเด้งออก) กลับสถานีที่เข้ามา
function EndTeamRound()
    if not (Config.Team and Config.Team.enabled) then return end
    if not RoundActive and next(PlayerTeam) == nil then return end

    local n = 0
    for src in pairs(PlayerTeam) do
        local returnTeam = ReturnTeamFor(src)
        if returnTeam then
            n = n + 1
            TriggerClientEvent('lp_airdropteam:CL:ReviveAt', src, returnTeam.joinCoords, true)
        end
    end
    DBG('EndTeamRound: sent %d player(s) back to their entry station', n)

    ResetTeamState()
end

-- ─── เข้าร่วมทีม (client ยิงตอนกดค้าง prompt ที่จุด NPC สถานีไหนก็ได้) ─────────────────
-- entryTeamId = สถานีที่กดค้างจริง (ใช้เป็นจุดกลับตอนออกจากรอบ)
-- battle teamId = derive จากเมืองใน nx_cityselect เสมอ (ใช้เป็นโซนสู้กัน/เกิดใหม่ในรอบ)
VORPcore.Callback.Register('lp_airdropteam:JoinTeam', function(source, cb, entryTeamId)
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

    local entryTeam = TeamsById[entryTeamId]
    if not entryTeam then
        cb({ ok = false, reason = 'no_team' })
        return
    end

    local cityId = exports['nx_cityselect']:GetPlayerCityId(source)
    local battleTeamId = cityId and CityToTeam[cityId]
    local battleTeam = battleTeamId and TeamsById[battleTeamId]
    if not battleTeam then
        cb({ ok = false, reason = 'no_team' })
        return
    end

    PlayerTeam[source]      = battleTeamId
    PlayerEntryTeam[source] = entryTeamId
    PlayerRespawns[source]  = 0

    local remainingMs = math.max(0, ZoneOpenAt - GetGameTimer())
    DBG('src=%d entry=%s battle=%s(city=%s) remainingMs=%d', source, entryTeamId, battleTeamId, tostring(cityId), remainingMs)

    cb({
        ok             = true,
        teamId         = battleTeamId,
        label          = battleTeam.label,
        coords         = battleTeam.zoneSpawn,
        remainingMs    = remainingMs,
        safeZoneRadius = Config.Team.safeZoneRadius,
    })
end)

-- ─── ตาย: hook event ที่ MJ-Respwan/core/client.lua ยิงจริง (บรรทัด TriggerServerEvent
-- ("vorp_core:Server:OnPlayerDeath", ...) ในเธรด DEATH HANDLER ของมัน) ─────────────────
-- ตายครั้งที่ <= maxRespawns -> เกิดใหม่ในโซนสู้กัน (battle team) ได้อีก
-- ตายเกิน maxRespawns -> เด้งกลับสถานีที่เข้ามา ออกจากรอบถาวร
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
        local returnTeam = ReturnTeamFor(src)
        PlayerTeam[src]      = nil
        PlayerEntryTeam[src] = nil
        TriggerClientEvent('lp_airdropteam:CL:ReviveAt', src, returnTeam.joinCoords, true)
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    PlayerTeam[src]      = nil
    PlayerEntryTeam[src] = nil
    PlayerRespawns[src]  = nil
end)

-- ─── /backapt: ผู้เล่นขอออกจากรอบเองได้ตลอดเวลา วาปกลับสถานีที่เข้ามา ──────────────────
RegisterCommand('backapt', function(source, args, rawCommand)
    local src = source
    local teamId = PlayerTeam[src]

    if not teamId then
        TriggerClientEvent('pNotify:SendNotification', src, { text = 'คุณไม่ได้เข้าร่วมกิจกรรมอยู่', type = 'error', timeout = 4000 })
        return
    end

    local returnTeam = ReturnTeamFor(src)
    if not returnTeam then return end

    DBG('src=%d used /backapt, leaving battleTeam=%s entry=%s', src, teamId, tostring(PlayerEntryTeam[src]))

    PlayerTeam[src]      = nil
    PlayerEntryTeam[src] = nil
    TriggerClientEvent('lp_airdropteam:CL:ReviveAt', src, returnTeam.joinCoords, true)
end, false)
