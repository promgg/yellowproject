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

-- lp_leaderboard (บอร์ดเมือง): สรุปผล "ต่อรอบ airdrop" ต่อเมือง (ต่อ battle team = เมืองตัวเอง)
local RoundParticipating = {} -- [cityId] = true (เมืองที่มีคนเข้าร่วมในรอบนี้)
local RoundWinnerCity    = nil -- cityId ของเมืองที่ลูทกล่องได้คนแรกในรอบ (ชนะรอบ)

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
    RoundParticipating = {}
    RoundWinnerCity    = nil
end

-- ยิงสรุปผลรอบไป lp_leaderboard (soft integration — ไม่ต้อง depend; ถ้าไม่มี resource ก็เงียบ)
-- เรียกก่อน ResetTeamState เสมอ (ใช้ค่า RoundParticipating/RoundWinnerCity ของรอบที่เพิ่งจบ)
local function FireCityResult()
    if next(RoundParticipating) == nil then return end
    local cities = {}
    for cityId in pairs(RoundParticipating) do
        cities[#cities + 1] = { id = cityId }
    end
    TriggerEvent('lp_leaderboard:SV:CityRoundResult', { cities = cities, winner = RoundWinnerCity })
    DBG('FireCityResult: cities=%d winner=%s', #cities, tostring(RoundWinnerCity))
end

-- server.lua/ClaimAirdrop เรียกตอนลูทกล่องสำเร็จ — เมืองของผู้ลูทคนแรก = ผู้ชนะรอบ
function RecordAirdropWinner(src)
    if not (Config.Team and Config.Team.enabled) or not RoundActive then return end
    if RoundWinnerCity then return end -- ล็อกผู้ชนะคนแรกของรอบ
    local teamId = PlayerTeam[src]
    local team   = teamId and TeamsById[teamId]
    if team and team.cityId then
        RoundWinnerCity = team.cityId
        DBG('RecordAirdropWinner: src=%d winnerCity=%s', src, team.cityId)
    end
end

-- จุดที่จะส่งผู้เล่นกลับไปเมื่อออกจากรอบ (ตายครั้งที่ 2 / backapt / จบรอบ): สถานีที่เข้ามาจริง
-- ถ้าหาไม่เจอ (ไม่ควรเกิด) fallback กลับไปใช้ battle team กันเหตุ error
local function ReturnTeamFor(src)
    return TeamsById[PlayerEntryTeam[src]] or TeamsById[PlayerTeam[src]]
end

-- นับจำนวนคนที่อยู่ใน battle team (เมือง) เดียวกันตอนนี้ — ใช้คุม Config.Team.maxPerCity
local function CountInBattleTeam(teamId)
    local n = 0
    for _, t in pairs(PlayerTeam) do
        if t == teamId then n = n + 1 end
    end
    return n
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
            -- ปิดรับสมัครแล้วไม่มีใครสมัครเลย = ยกเลิกกิจกรรมทิ้ง ไม่ปล่อยให้รอบว่างรันต่อ
            --
            -- เดิมรอบว่างรันต่อจนครบ Config["TimeToRemove"] (30 นาที): กล่อง/blip/PTFX ค้างบนแมพ,
            -- zone lock เปิด (ใครเดินเข้าเขตโดนดาเมจ/เด้งออก), IsAirdropStarted ค้าง = จัดรอบใหม่
            -- หรือสั่ง /apteam ไม่ได้เลยจนกว่าจะครบเวลา
            --
            -- AirdropAutoDelete() (server.lua) เป็นตัวเดียวที่ล้างครบทั้ง prop/blip/zone lock/state
            -- และเรียก EndTeamRound() ให้เอง — GameFinish() ใช้ไม่ได้ (ทิ้ง blip ค้างฝั่ง client)
            if next(PlayerTeam) == nil then
                DBG('Joining locked with 0 participants -> cancelling round')
                TriggerClientEvent('pNotify:SendNotification', -1, {
                    text = 'สิ้นสุดกิจกรรมแอร์ดรอป เนื่องจากไม่มีผู้เข้าร่วม',
                    type = 'warning',
                    timeout = 6000,
                })
                AirdropAutoDelete()
                return
            end

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

    FireCityResult() -- สรุปผลรอบ (เข้า/ชนะ/แพ้ ต่อเมือง) ไป lp_leaderboard ก่อนล้าง state
    ResetTeamState()
end

-- ─── สถานะการเข้าร่วม สำหรับรีซอร์สอื่นเอาไปแสดงผล ─────────────────────────────
-- lp_fasttravel เรียกตัวนี้ตอนสร้างรายการสถานี เพื่อรู้ว่าจะโชว์ปุ่มแอร์ดรอปแบบไหน
-- state: 'open' = เข้าร่วมได้ | 'locked' = เปิดโซนแล้ว เข้าเพิ่มไม่ได้
--        'joined' = เข้าร่วมไปแล้ว | 'closed' = ไม่มีรอบเปิดอยู่
--
-- เป็นข้อมูลอ่านอย่างเดียว ไม่เปลี่ยนสถานะอะไร การตัดสินใจจริงยังอยู่ที่ callback JoinTeam
-- ด้านล่างเสมอ — ต่อให้ client โกหกว่าปุ่มกดได้ ก็ยังผ่านด่านเดิมทั้งหมด
exports('GetJoinState', function(src)
    if not (Config.Team and Config.Team.enabled) then
        return { state = 'closed' }
    end
    if PlayerTeam[src] then
        return { state = 'joined' }
    end
    if not RoundActive then
        return { state = 'closed' }
    end
    if JoiningLocked then
        return { state = 'locked' }
    end

    return {
        state       = 'open',
        remainingMs = math.max(0, ZoneOpenAt - GetGameTimer()),
    }
end)

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

    -- จำกัดจำนวนคนต่อเมือง (battle team เดียวกัน) — เช็คสด ๆ ตอน join จริง กันแทรกคิวพร้อมกัน
    if CountInBattleTeam(battleTeamId) >= Config.Team.maxPerCity then
        DBG('src=%d rejected: city=%s battle=%s is full (max=%d)', source, tostring(cityId), battleTeamId, Config.Team.maxPerCity)
        cb({ ok = false, reason = 'city_full' })
        return
    end

    PlayerTeam[source]      = battleTeamId
    PlayerEntryTeam[source] = entryTeamId
    PlayerRespawns[source]  = 0

    -- lp_leaderboard: บันทึกว่าเมืองนี้ (battle team = เมืองตัวเอง) เข้าร่วมรอบนี้แล้ว
    if battleTeam.cityId then RoundParticipating[battleTeam.cityId] = true end

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
