-- lp_leaderboard / server/sv_main.lua
-- Server-authoritative ล้วน — client ส่งได้แค่ "ขอดู" / "ขอ reset(admin)"
--   KILL: นับจาก vorp_core:Server:OnPlayerDeath (ตายจริงในเกม) กัน self/NPC/ปั๊มซ้ำ
--   CITY: รับสรุปผลรอบจาก lp_airdropteam (event server→server) แล้วบวก เข้า/ชนะ/แพ้
--   GATHER JOBS (FISH/MINING/PLANTING/LUMBER): รับ event จาก resource งานนั้นๆ ทุกครั้งที่ทำสำเร็จ
--     1 ครั้ง — ขับเคลื่อนจาก Config.GatherJobs ทั้งหมด (เพิ่มหมวดใหม่ = แก้ config.lua อย่างเดียว)
-- สถิติเก็บใน memory (เร็ว) + flush ลง DB เป็นรอบ + ตอน resource stop

local VORPcore = exports.vorp_core:GetCore()

-- ════════════════════════════════════════════════════════════════════════════
--  In-memory stats (โหลดจาก DB ตอน start, sync กลับเป็นรอบ)
-- ════════════════════════════════════════════════════════════════════════════
local killStats = {}   -- [charid] = { name, kills, deaths, score }
local cityStats = {}   -- [cityId] = { label, entries, wins, losses }
local dirtyKill = {}   -- set ของ charid ที่ต้อง flush
local dirtyCity = {}   -- set ของ cityId ที่ต้อง flush

local gatherStats = {} -- [catId][charid] = { name, score, count }
local dirtyGather = {} -- [catId] = set ของ charid ที่ต้อง flush
for catId in pairs(Config.GatherJobs) do
    gatherStats[catId] = {}
    dirtyGather[catId] = {}
end

local boardsDirty = true
local ready = false

local openViewers = {} -- [src] = { charid=, name=, cityId= }
local lastDeathAt = {} -- [victimSrc] = os.clock() (กัน spam event ตาย)
local lastPair    = {} -- ["killer>victim"] = os.time() (กันปั๊มคู่เดิม)

-- rate-limit event ที่ client ยิงได้ (open/reset) — กัน spam ทำ computeBoards ซ้ำ
local cooldowns   = {} -- [src][action] = GetGameTimer() ล่าสุด
local COOLDOWN_MS = { open = 1000, reset = 2000 }
local function checkCooldown(src, action)
    local t = GetGameTimer()
    cooldowns[src] = cooldowns[src] or {}
    local last = cooldowns[src][action] or 0
    if (t - last) < (COOLDOWN_MS[action] or 1000) then return false end
    cooldowns[src][action] = t
    return true
end

local function dbg(fmt, ...)
    if Config.Debug then print(('[lp_leaderboard] ' .. fmt):format(...)) end
end
local function logTx(kind, detail)
    print(('[lp_leaderboard][TX] %s | %s'):format(kind, tostring(detail)))
end

-- ── VORP helpers ────────────────────────────────────────────────────────────
local function getChar(src)
    local u = VORPcore.getUser(src)
    if not u then return nil end
    return u.getUsedCharacter
end
local function charIdOf(char)  return char and (char.charIdentifier or char.identifier) or nil end
local function charNameOf(char)
    if not char then return '-' end
    local f = char.firstname or ''
    local l = char.lastname or ''
    local n = (f .. ' ' .. l):gsub('^%s+', ''):gsub('%s+$', '')
    return (n ~= '' and n) or ('#' .. tostring(charIdOf(char) or '?'))
end
local function isAdmin(char)
    local g = char and char.group
    for _, ag in ipairs(Config.AdminGroups or {}) do if g == ag then return true end end
    return false
end
local function cityOf(src)
    local ok, cid = pcall(function() return exports['nx_cityselect']:GetPlayerCityId(src) end)
    if ok then return cid end
    return nil
end

-- ── เปิด/ปิดหมวด (Config.Categories[].enabled) ──────────────────────────────
local function categoryEnabled(id)
    for _, c in ipairs(Config.Categories) do
        if c.id == id then return c.enabled ~= false end
    end
    return true
end
local function enabledCategories()
    local out = {}
    for _, c in ipairs(Config.Categories) do
        if c.enabled ~= false then out[#out + 1] = c end
    end
    return out
end

-- ════════════════════════════════════════════════════════════════════════════
--  DB
-- ════════════════════════════════════════════════════════════════════════════
MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `lp_leaderboard_kills` (
            `charid` VARCHAR(64)  NOT NULL,
            `name`   VARCHAR(100) NULL,
            `kills`  INT NOT NULL DEFAULT 0,
            `deaths` INT NOT NULL DEFAULT 0,
            `score`  INT NOT NULL DEFAULT 0,
            PRIMARY KEY (`charid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `lp_leaderboard_cities` (
            `city`    VARCHAR(64)  NOT NULL,
            `label`   VARCHAR(100) NULL,
            `entries` INT NOT NULL DEFAULT 0,
            `wins`    INT NOT NULL DEFAULT 0,
            `losses`  INT NOT NULL DEFAULT 0,
            PRIMARY KEY (`city`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    local gatherJobIds = {}
    for catId in pairs(Config.GatherJobs) do gatherJobIds[#gatherJobIds + 1] = catId end

    for _, catId in ipairs(gatherJobIds) do
        local job = Config.GatherJobs[catId]
        MySQL.query((([[
            CREATE TABLE IF NOT EXISTS `%s` (
                `charid` VARCHAR(64)  NOT NULL,
                `name`   VARCHAR(100) NULL,
                `score`  INT NOT NULL DEFAULT 0,
                `count`  INT NOT NULL DEFAULT 0,
                PRIMARY KEY (`charid`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]]):format(job.table)))
    end

    local function countMap(t) local n = 0; for _ in pairs(t) do n = n + 1 end; return n end

    local pending = 2 + #gatherJobIds
    local function onOneLoaded()
        pending = pending - 1
        if pending <= 0 then
            ready = true
            boardsDirty = true
            -- observability: log จำนวนที่โหลดเข้ามาเสมอ (ไม่ผูก Debug) — ข้อ E
            local ng = 0
            for catId in pairs(Config.GatherJobs) do ng = ng + countMap(gatherStats[catId]) end
            logTx('db-loaded', ('kills=%d cities=%d gather=%d (jobs=%d)')
                :format(countMap(killStats), countMap(cityStats), ng, #gatherJobIds))
        end
    end

    MySQL.query('SELECT charid, name, kills, deaths, score FROM lp_leaderboard_kills', {}, function(rows)
        if not rows then logTx('db-error', 'โหลด lp_leaderboard_kills คืน nil (query fail?)') end
        for _, r in ipairs(rows or {}) do
            killStats[tostring(r.charid)] = {
                name = r.name, kills = tonumber(r.kills) or 0,
                deaths = tonumber(r.deaths) or 0, score = tonumber(r.score) or 0,
            }
        end
        onOneLoaded()
    end)

    MySQL.query('SELECT city, label, entries, wins, losses FROM lp_leaderboard_cities', {}, function(rows)
        if not rows then logTx('db-error', 'โหลด lp_leaderboard_cities คืน nil (query fail?)') end
        for _, r in ipairs(rows or {}) do
            cityStats[tostring(r.city)] = {
                label = r.label, entries = tonumber(r.entries) or 0,
                wins = tonumber(r.wins) or 0, losses = tonumber(r.losses) or 0,
            }
        end
        onOneLoaded()
    end)

    for _, catId in ipairs(gatherJobIds) do
        local job = Config.GatherJobs[catId]
        MySQL.query('SELECT charid, name, score, count FROM ' .. job.table, {}, function(rows)
            if not rows then logTx('db-error', ('โหลด %s คืน nil (query fail?)'):format(job.table)) end
            for _, r in ipairs(rows or {}) do
                gatherStats[catId][tostring(r.charid)] = {
                    name = r.name, score = tonumber(r.score) or 0, count = tonumber(r.count) or 0,
                }
            end
            onOneLoaded()
        end)
    end
end)

local function markKillDirty(charid) dirtyKill[charid] = true; boardsDirty = true end
local function markCityDirty(cityId) dirtyCity[cityId] = true; boardsDirty = true end
local function markGatherDirty(catId, charid) dirtyGather[catId][charid] = true; boardsDirty = true end

local function flushDirty()
    if not ready then return end
    for charid in pairs(dirtyKill) do
        local s = killStats[charid]
        if s then
            MySQL.insert([[
                INSERT INTO lp_leaderboard_kills (charid,name,kills,deaths,score) VALUES (?,?,?,?,?)
                ON DUPLICATE KEY UPDATE name=VALUES(name),kills=VALUES(kills),deaths=VALUES(deaths),score=VALUES(score)
            ]], { charid, s.name, s.kills, s.deaths, s.score })
        end
        dirtyKill[charid] = nil
    end
    for cityId in pairs(dirtyCity) do
        local s = cityStats[cityId]
        if s then
            MySQL.insert([[
                INSERT INTO lp_leaderboard_cities (city,label,entries,wins,losses) VALUES (?,?,?,?,?)
                ON DUPLICATE KEY UPDATE label=VALUES(label),entries=VALUES(entries),wins=VALUES(wins),losses=VALUES(losses)
            ]], { cityId, s.label, s.entries, s.wins, s.losses })
        end
        dirtyCity[cityId] = nil
    end
    for catId, job in pairs(Config.GatherJobs) do
        for charid in pairs(dirtyGather[catId]) do
            local s = gatherStats[catId][charid]
            if s then
                MySQL.insert((([[
                    INSERT INTO %s (charid,name,score,count) VALUES (?,?,?,?)
                    ON DUPLICATE KEY UPDATE name=VALUES(name),score=VALUES(score),count=VALUES(count)
                ]]):format(job.table)), { charid, s.name, s.score, s.count })
            end
            dirtyGather[catId][charid] = nil
        end
    end
end

-- ════════════════════════════════════════════════════════════════════════════
--  Badges (ใช้ร่วมกันทุกหมวด — ส่ง badge list ที่ต้องการเข้าไป)
-- ════════════════════════════════════════════════════════════════════════════
local function badgeFrom(list, score)
    local pick = list[1]
    for _, b in ipairs(list) do
        if score >= b.min then pick = b end
    end
    return { name = pick.name, color = pick.color }
end
local function badgeFor(score) return badgeFrom(Config.Badges, score) end

-- ════════════════════════════════════════════════════════════════════════════
--  KILL tracking — vorp_core:Server:OnPlayerDeath (source = เหยื่อ, arg1 = killerServerId)
-- ════════════════════════════════════════════════════════════════════════════
local function ensureKill(charid, name)
    local s = killStats[charid]
    if not s then s = { name = name, kills = 0, deaths = 0, score = 0 }; killStats[charid] = s
    elseif name then s.name = name end
    return s
end

RegisterNetEvent('vorp_core:Server:OnPlayerDeath', function(killerServerId, deathCause)
    if not categoryEnabled('kill') then return end
    local victim = source
    -- กัน spam event ตายจาก client เดียว (ตายถี่ผิดปกติ)
    local now = os.clock()
    if lastDeathAt[victim] and (now - lastDeathAt[victim]) < 1.0 then return end
    lastDeathAt[victim] = now

    local vChar = getChar(victim)
    local vId   = charIdOf(vChar)
    if not vId then return end
    vId = tostring(vId)

    -- killer: ต้องเป็นผู้เล่นจริง ไม่ใช่ตัวเอง ไม่ใช่ NPC/สิ่งแวดล้อม
    local killer = tonumber(killerServerId)
    local kChar, kId
    local sameCity = false
    if killer and killer ~= 0 and killer ~= victim then
        kChar = getChar(killer)
        kId   = charIdOf(kChar)
        if kId then
            kId = tostring(kId)
            -- ยิงคนเมืองเดียวกัน (ทีมเดียวกัน) ไม่นับทั้ง kill/score ของ killer และ death ของเหยื่อ
            if kId ~= vId and Config.Kill.ignoreSameCity then
                local kCity, vCity = cityOf(killer), cityOf(victim)
                if kCity and vCity and tostring(kCity) == tostring(vCity) then
                    sameCity = true
                    dbg('same-city guard: %s(%s) ยิง %s(%s) เมืองเดียวกัน (%s) ไม่นับ kill/death', charNameOf(kChar), kId, charNameOf(vChar), vId, tostring(kCity))
                end
            end
        end
    end

    -- เหยื่อ: +death (ยกเว้นโดนเพื่อนร่วมเมืองยิงตาย)
    if Config.Kill.countDeaths and not sameCity then
        local vs = ensureKill(vId, charNameOf(vChar))
        vs.deaths = vs.deaths + 1
        markKillDirty(vId)
    end

    if not killer or killer == 0 then
        if not Config.Kill.ignoreNpc then boardsDirty = true end
        return
    end
    if killer == victim and Config.Kill.ignoreSelf then boardsDirty = true; return end
    if not kId then boardsDirty = true; return end
    if kId == vId then boardsDirty = true; return end -- ตัวละครเดียวกัน (กันเผื่อ)
    if sameCity then boardsDirty = true; return end

    -- anti-spoof: ตรวจระยะจากพิกัดที่ server รู้เอง (กัน client ปลอม event ตายให้พวกไกลๆ ได้ kill)
    if (Config.Kill.maxKillDistance or 0) > 0 then
        local kp, vp = GetPlayerPed(killer), GetPlayerPed(victim)
        if kp and vp and kp ~= 0 and vp ~= 0 then
            local d = #(GetEntityCoords(kp) - GetEntityCoords(vp))
            if d > Config.Kill.maxKillDistance then
                dbg('distance-guard: %s ยิง %s ระยะ %.0fm เกิน %dm ไม่นับ (อาจ spoof)',
                    charNameOf(kChar), charNameOf(vChar), d, Config.Kill.maxKillDistance)
                boardsDirty = true
                return
            end
        end
    end

    -- กันปั๊มคู่เดิม (killer→victim ซ้ำใน cooldown)
    if (Config.Kill.farmCooldown or 0) > 0 then
        local key = kId .. '>' .. vId
        local last = lastPair[key]
        local t = os.time()
        if last and (t - last) < Config.Kill.farmCooldown then
            dbg('farm-guard: %s ไม่เครดิต kill (คู่เดิมใน %ds)', key, Config.Kill.farmCooldown)
            boardsDirty = true
            return
        end
        lastPair[key] = t
    end

    local ks = ensureKill(kId, charNameOf(kChar))
    ks.kills = ks.kills + 1
    ks.score = ks.kills * (Config.Kill.pointsPerKill or 1)
    markKillDirty(kId)
    dbg('kill: %s(%s) -> +1 (kills=%d)', charNameOf(kChar), kId, ks.kills)
end)

-- ════════════════════════════════════════════════════════════════════════════
--  CITY result — จาก lp_airdropteam (server → server) ตอนจบรอบ
--    payload = { cities = { {id=cityId, label=?}, ... }, winner = cityId | nil }
-- ════════════════════════════════════════════════════════════════════════════
AddEventHandler(Events.cityResult, function(payload)
    if not categoryEnabled('city') then return end
    if type(payload) ~= 'table' or type(payload.cities) ~= 'table' then return end
    local winner = payload.winner
    local n = 0
    for _, c in ipairs(payload.cities) do
        local cid = c and tostring(c.id or '')
        if cid and cid ~= '' then
            local s = cityStats[cid]
            if not s then s = { label = nil, entries = 0, wins = 0, losses = 0 }; cityStats[cid] = s end
            s.label = Config.CityNames[cid] or c.label or s.label or cid
            s.entries = s.entries + 1
            if winner and cid == tostring(winner) then
                s.wins = s.wins + 1
            elseif winner then
                s.losses = s.losses + 1
            end
            markCityDirty(cid)
            n = n + 1
        end
    end
    logTx('city-round', ('cities=%d winner=%s'):format(n, tostring(winner)))
end)

-- ════════════════════════════════════════════════════════════════════════════
--  GATHER JOBS (FISH/MINING/PLANTING/LUMBER) — ขับเคลื่อนจาก Config.GatherJobs ทั้งหมด
--    payload = { src = ผู้เล่นที่ทำสำเร็จ, amount = จำนวนไอเทมที่ได้ }  (soft integration — ไม่ต้อง depend)
-- ════════════════════════════════════════════════════════════════════════════
local function ensureGather(catId, charid, name)
    local s = gatherStats[catId][charid]
    if not s then s = { name = name, score = 0, count = 0 }; gatherStats[catId][charid] = s
    elseif name then s.name = name end
    return s
end

local function buildGather(catId)
    local job = Config.GatherJobs[catId]
    local list = {}
    for charid, s in pairs(gatherStats[catId]) do
        list[#list + 1] = { charid = charid, name = s.name or ('#' .. charid), score = s.score, count = s.count }
    end
    table.sort(list, function(a, b)
        if a.score ~= b.score then return a.score > b.score end
        if a.count ~= b.count then return a.count > b.count end
        return (a.name or '') < (b.name or '')
    end)
    local byId, rows = {}, {}
    for i, r in ipairs(list) do
        local row = { rank = i, name = r.name, score = r.score, count = r.count, badge = badgeFrom(job.badges, r.score) }
        byId[r.charid] = row
        if i <= Config.TopN then rows[#rows + 1] = row end
    end
    return rows, byId
end

for catId, job in pairs(Config.GatherJobs) do
    AddEventHandler(job.event, function(payload)
        if not categoryEnabled(catId) then return end
        -- หมายเหตุ: ต้องใช้ payload.src ที่ resource ต้นทางแนบมาเอง ห้ามอ่าน global `source`
        -- ตรงๆ เพราะ TriggerEvent ข้าม resource ไม่รับประกันว่าจะเป็นผู้เล่นคนเดิม
        local src = tonumber(payload and payload.src)
        if not src then return end
        local amount = tonumber(payload and payload.amount) or 1
        if amount <= 0 then return end

        local char = getChar(src)
        local charid = charIdOf(char)
        if not charid then return end
        charid = tostring(charid)

        local s = ensureGather(catId, charid, charNameOf(char))
        s.score = s.score + amount
        s.count = s.count + 1
        markGatherDirty(catId, charid)
        dbg('%s: %s(%s) -> +%d (score=%d count=%d)', catId, charNameOf(char), charid, amount, s.score, s.count)
    end)
end

-- ════════════════════════════════════════════════════════════════════════════
--  Build boards
-- ════════════════════════════════════════════════════════════════════════════
local function buildKill()
    local list = {}
    for charid, s in pairs(killStats) do
        list[#list + 1] = { charid = charid, name = s.name or ('#' .. charid),
                            kills = s.kills, deaths = s.deaths, score = s.score }
    end
    table.sort(list, function(a, b)
        if a.score ~= b.score then return a.score > b.score end
        if a.kills ~= b.kills then return a.kills > b.kills end
        return (a.name or '') < (b.name or '')
    end)
    local byId, rows = {}, {}
    for i, r in ipairs(list) do
        local row = { rank = i, name = r.name, score = r.score, kills = r.kills,
                      deaths = r.deaths, badge = badgeFor(r.score) }
        byId[r.charid] = row
        if i <= Config.TopN then rows[#rows + 1] = row end
    end
    return rows, byId
end

local function buildCity()
    local list = {}
    for cid, s in pairs(cityStats) do
        local total = s.wins + s.losses
        local wr = total > 0 and math.floor((s.wins / total) * 100 + 0.5) or 0
        list[#list + 1] = { city = cid, label = s.label or Config.CityNames[cid] or cid,
                            entries = s.entries, wins = s.wins, losses = s.losses, winrate = wr }
    end
    table.sort(list, function(a, b)
        if a.wins ~= b.wins then return a.wins > b.wins end
        if a.winrate ~= b.winrate then return a.winrate > b.winrate end
        return (a.label or '') < (b.label or '')
    end)
    local byCity, rows = {}, {}
    for i, r in ipairs(list) do
        r.rank = i
        byCity[r.city] = r
        if i <= Config.TopN then rows[#rows + 1] = r end
    end
    return rows, byCity
end

local function buildPayloadFor(src, viewer, boards, adminFlag)
    local payload = {
        isAdmin    = adminFlag and true or false,
        categories = enabledCategories(),
        groups     = Config.Groups, -- meta ของแทบรวม (jobs) — NUI ใช้จัดกลุ่ม tab
    }

    -- ใส่เฉพาะหมวดที่ build มา (= หมวดที่เปิด) — กัน nil index จากหมวดที่ปิด (ข้อ D)
    if boards.killRows then
        local killYou
        if viewer.charid then
            killYou = boards.killById[viewer.charid]
                or { rank = '-', name = viewer.name, score = 0, kills = 0, deaths = 0, badge = badgeFor(0) }
        end
        payload.kill = { rows = boards.killRows, you = killYou }
    end

    if boards.cityRows then
        local cityYou
        if viewer.cityId and boards.cityByCity[viewer.cityId] then
            cityYou = boards.cityByCity[viewer.cityId]
        end
        payload.city = { rows = boards.cityRows, you = cityYou }
    end

    for catId, job in pairs(Config.GatherJobs) do
        local g = boards.gather[catId]
        if g then
            local you
            if viewer.charid then
                you = g.byId[viewer.charid]
                    or { rank = '-', name = viewer.name, score = 0, count = 0, badge = badgeFrom(job.badges, 0) }
            end
            payload[catId] = { rows = g.rows, you = you }
        end
    end

    return payload
end

-- build เฉพาะหมวดที่เปิด (enabled) — หมวดที่ปิดไม่เสีย CPU/ไม่ถูกส่งใน payload (ข้อ D)
local function computeBoards()
    local b = { gather = {} }
    if categoryEnabled('kill') then b.killRows, b.killById   = buildKill() end
    if categoryEnabled('city') then b.cityRows, b.cityByCity = buildCity() end
    for catId in pairs(Config.GatherJobs) do
        if categoryEnabled(catId) then
            local rows, byId = buildGather(catId)
            b.gather[catId] = { rows = rows, byId = byId }
        end
    end
    return b
end

-- ════════════════════════════════════════════════════════════════════════════
--  Open / push
-- ════════════════════════════════════════════════════════════════════════════
local function sendTo(src, boards)
    local viewer = openViewers[src]
    if not viewer then return end
    local char = getChar(src)
    local payload = buildPayloadFor(src, viewer, boards, isAdmin(char))
    TriggerClientEvent(Events.pushState, src, payload)
end

RegisterNetEvent(Events.requestOpen, function()
    local src = source
    if not checkCooldown(src, 'open') then return end -- กัน spam /leaderboard
    if not ready then
        TriggerClientEvent('pNotify:SendNotification', src, { text = Config.Locale.notReady, type = 'error', timeout = 3000 })
        return
    end
    local char = getChar(src)
    openViewers[src] = {
        charid = charIdOf(char) and tostring(charIdOf(char)) or nil,
        name   = charNameOf(char),
        cityId = cityOf(src) and tostring(cityOf(src)) or nil,
    }
    local boards = computeBoards()
    local payload = buildPayloadFor(src, openViewers[src], boards, isAdmin(char))
    TriggerClientEvent(Events.openUI, src, payload)
end)

RegisterNetEvent(Events.close, function()
    openViewers[source] = nil
end)

-- live-push loop (throttle) — ส่งเฉพาะคนที่เปิดค้าง และเมื่อ board มีการเปลี่ยน
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.PushInterval)
        if ready and boardsDirty and next(openViewers) then
            boardsDirty = false
            local boards = computeBoards()
            for src in pairs(openViewers) do sendTo(src, boards) end
        end
    end
end)

-- ════════════════════════════════════════════════════════════════════════════
--  Admin RESET — ไม่มีปุ่มใน UI แล้ว (ไม่จำเป็นถ้ามั่นใจใน anti-cheat) เหลือแค่คำสั่งแอดมิน
--  /lbreset <kill|city|<gather-id>|all>  — เช็ค group ฝั่ง server เท่านั้น
-- ════════════════════════════════════════════════════════════════════════════
local function pushAllOpen()
    if not next(openViewers) then return end
    local boards = computeBoards()
    for src in pairs(openViewers) do sendTo(src, boards) end
end

local function isValidResetCategory(category)
    if category == 'all' then return true end
    for _, c in ipairs(Config.Categories) do if c.id == category then return true end end
    return false
end

-- ล้างข้อมูลจริง (memory + DB) ตามหมวด — ใช้ร่วมกันทั้ง /lbreset และ /clearleaderboard
local function doReset(category)
    if category == 'kill' or category == 'all' then
        killStats, dirtyKill, lastPair = {}, {}, {}
        MySQL.query('DELETE FROM lp_leaderboard_kills')
    end
    if category == 'city' or category == 'all' then
        cityStats, dirtyCity = {}, {}
        MySQL.query('DELETE FROM lp_leaderboard_cities')
    end
    for catId, job in pairs(Config.GatherJobs) do
        if category == catId or category == 'all' then
            gatherStats[catId], dirtyGather[catId] = {}, {}
            MySQL.query('DELETE FROM ' .. job.table)
        end
    end
    boardsDirty = true
end

RegisterCommand('lbreset', function(src, args)
    if src == 0 then return end -- console: ใช้ /lbreset ในเกมเท่านั้น (ต้องมี char ผูก group)
    if not checkCooldown(src, 'reset') then return end
    local char = getChar(src)
    if not isAdmin(char) then
        TriggerClientEvent('pNotify:SendNotification', src, { text = Config.Locale.adminOnly, type = 'error', timeout = 3000 })
        return
    end
    local category = tostring(args[1] or 'all')
    if not isValidResetCategory(category) then
        TriggerClientEvent('pNotify:SendNotification', src, { text = 'หมวดไม่ถูกต้อง: ' .. category, type = 'error', timeout = 3000 })
        return
    end

    doReset(category)
    logTx('admin-reset', ('by=%s(%s) category=%s'):format(GetPlayerName(src) or '?', tostring(charIdOf(char)), category))
    TriggerClientEvent('pNotify:SendNotification', src, { text = Config.Locale.resetDone, type = 'success', timeout = 3000 })
    pushAllOpen()
end, false)

-- /clearleaderboard [category] — ล้างกระดานอันดับ ตรวจสิทธิ์ด้วย ACE (Config.AcePermission)
-- ต่างจาก /lbreset ตรงที่เช็ค ace ไม่ใช่ group → สั่งจาก console/RCON ก็ได้ (src == 0 = เต็มสิทธิ์อยู่แล้ว)
-- ให้สิทธิ์ผู้เล่นใน server.cfg:  add_ace group.admin lp_leaderboard.admin allow
RegisterCommand('clearleaderboard', function(src, args)
    local fromConsole = (src == 0)

    if not fromConsole and not IsPlayerAceAllowed(src, Config.AcePermission) then
        TriggerClientEvent('pNotify:SendNotification', src, { text = Config.Locale.adminOnly, type = 'error', timeout = 3000 })
        return
    end
    if not fromConsole and not checkCooldown(src, 'reset') then return end

    local category = tostring(args[1] or 'all')
    if not isValidResetCategory(category) then
        local msg = 'หมวดไม่ถูกต้อง: ' .. category .. ' (kill|city|fish|mining|planting|lumber|hunting|all)'
        if fromConsole then print('[lp_leaderboard] ' .. msg)
        else TriggerClientEvent('pNotify:SendNotification', src, { text = msg, type = 'error', timeout = 3000 }) end
        return
    end

    doReset(category)
    local who = fromConsole and 'console' or (GetPlayerName(src) or '?')
    logTx('ace-clear', ('by=%s src=%s category=%s'):format(who, tostring(src), category))
    if fromConsole then
        print(('[lp_leaderboard] clearleaderboard: ล้างหมวด "%s" เรียบร้อย'):format(category))
    else
        TriggerClientEvent('pNotify:SendNotification', src, { text = Config.Locale.resetDone, type = 'success', timeout = 3000 })
    end
    pushAllOpen()
end, false)

-- ════════════════════════════════════════════════════════════════════════════
--  Persist loop + cleanup
-- ════════════════════════════════════════════════════════════════════════════
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.PersistEvery)
        flushDirty()
        -- sweep กันปั๊มคู่ที่หมดอายุ (กัน lastPair โตไม่จำกัด — key ที่เกิน farmCooldown ไร้ประโยชน์แล้ว)
        local ttl = Config.Kill.farmCooldown or 0
        if ttl > 0 then
            local now = os.time()
            for key, ts in pairs(lastPair) do
                if (now - ts) > ttl then lastPair[key] = nil end
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    openViewers[src] = nil
    lastDeathAt[src] = nil
    cooldowns[src]   = nil
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    flushDirty()
end)
