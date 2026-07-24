-- lp_battlepass / server/sv_main.lua
-- Server-authoritative. Client ส่งได้แค่ "คำขอเคลม" (level) — server ตัดสินทุกอย่าง
-- EXP มาจาก server ล้วน: quest hook (export), ไอเทม, แอดมิน — client ไม่มี event ยิง XP เลย
-- season รายเดือน (รีเซ็ตอัตโนมัติในโค้ด) | Premium ปลดล็อกด้วยการถือ vip_card

local VORPcore = exports.vorp_core:GetCore()

-- ════════════════════════════════════════════════════════════════════════════
--  DB (oxmysql) — parameterized ทุก query, CREATE TABLE IF NOT EXISTS
-- ════════════════════════════════════════════════════════════════════════════
MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `lp_battlepass` (
            `identifier`  VARCHAR(60) NOT NULL,
            `season`      VARCHAR(7)  NOT NULL,
            `level`       INT         NOT NULL DEFAULT 1,
            `xp`          INT         NOT NULL DEFAULT 0,
            `daily_xp`    INT         NOT NULL DEFAULT 0,
            `daily_date`  VARCHAR(10) NULL,
            `claimed`     TEXT        NULL,
            `claimed_vip` TEXT        NULL,
            PRIMARY KEY (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end)

-- ════════════════════════════════════════════════════════════════════════════
--  Helpers
-- ════════════════════════════════════════════════════════════════════════════
local function dbg(fmt, ...)
    if Config.Debug then print(('[lp_battlepass] ' .. fmt):format(...)) end
end

-- log ทุก transaction (แจกของ/แอดมิน/level) เสมอ — observability (ข้อ 11)
local function logTx(src, kind, detail)
    print(('[lp_battlepass][TX] src=%s name=%s kind=%s | %s')
        :format(tostring(src), tostring(GetPlayerName(src) or '?'), kind, tostring(detail)))
end

local function notify(src, text, ntype)
    TriggerClientEvent('pNotify:SendNotification', src, { text = text, type = ntype or 'info', timeout = 4000 })
end

local function getUser(src)        return VORPcore.getUser(src) end
local function getIdentifier(src)
    local u = getUser(src); if not u then return nil end
    return u.getIdentifier and u.getIdentifier() or nil
end
local function getChar(src)
    local u = getUser(src); if not u then return nil end
    return u.getUsedCharacter
end

local function isAdmin(char)
    local g = char and char.group
    for _, ag in ipairs(Config.AdminGroups or {}) do if g == ag then return true end end
    return false
end

-- Premium: เช็คไอเทมในกระเป๋าฝั่ง server (ไม่เชื่อ flag จาก client)
local function isVip(src)
    for _, item in ipairs(Config.VIP.items or {}) do
        local cnt = exports.vorp_inventory:getItemCount(src, nil, item)
        if cnt and cnt > 0 then return true end
    end
    return false
end

local function currentSeason() return os.date('%Y-%m') end      -- ซีซั่นรายเดือน
local function todayDate()     return os.date('%Y-%m-%d') end

local function claimedToCsv(set)
    local arr = {}
    for k in pairs(set) do arr[#arr + 1] = k end
    table.sort(arr)
    return table.concat(arr, ',')
end

-- ── แจกรางวัล (server หยิบจาก config เท่านั้น; ไม่เช็ค canCarry ให้แจกทะลุ limit เสมอ) ──
local CURRENCY = { money = 0, gold = 1, rol = 2 }
local function giveReward(src, cfg)
    if cfg.type == 'item' then
        exports.vorp_inventory:addItem(src, cfg.item, cfg.amount)
    elseif cfg.type == 'currency' then
        local char = getChar(src)
        if char then char.addCurrency(CURRENCY[cfg.currency] or 0, cfg.amount) end
    end
end

-- ════════════════════════════════════════════════════════════════════════════
--  Rate limiting (ข้อ 3)
-- ════════════════════════════════════════════════════════════════════════════
local cooldowns   = {}
local COOLDOWN_MS = { claim = 400, requestOpen = 1000 }
local function checkCooldown(src, action)
    local t = GetGameTimer()
    cooldowns[src] = cooldowns[src] or {}
    local last = cooldowns[src][action] or 0
    if (t - last) < (COOLDOWN_MS[action] or 400) then return false end
    cooldowns[src][action] = t
    return true
end

-- ════════════════════════════════════════════════════════════════════════════
--  Cache (per-src) + load guard กัน race ตอนโหลดครั้งแรก (ข้อ 4)
-- ════════════════════════════════════════════════════════════════════════════
local cache   = {} -- [src] = { identifier, season, level, xp, daily_xp, daily_date, claimed={set}, claimedVIP={set} }
local loading = {} -- [src] = { cb, cb, ... } คิว callback ระหว่างโหลด

-- รีเซ็ตตามซีซั่น/วันปัจจุบัน (idempotent — เรียกได้ทุกครั้งก่อนใช้ st)
local function applySeasonAndDaily(st)
    local season = currentSeason()
    if st.season ~= season then
        st.season      = season
        st.level, st.xp = 1, 0
        st.claimed, st.claimedVIP = {}, {}
        st.daily_xp    = 0
        st.daily_date  = todayDate()
        st.dirty = true
    end
    local today = todayDate()
    if st.daily_date ~= today then
        st.daily_date = today
        st.daily_xp   = 0
        st.dirty = true
    end
end

local function persist(st)
    if not st then return end
    MySQL.update([[
        UPDATE lp_battlepass SET season=?, level=?, xp=?, daily_xp=?, daily_date=?, claimed=?, claimed_vip=?
        WHERE identifier=?
    ]], {
        st.season, st.level, st.xp, st.daily_xp, st.daily_date,
        claimedToCsv(st.claimed), claimedToCsv(st.claimedVIP), st.identifier,
    })
    st.dirty = false
end

local function loadPlayer(src, cb)
    -- FiveM เอา server id ของคนที่หลุดไปแล้วไปแจกให้คนใหม่ได้ ถ้า entry เก่ายังค้างอยู่ใน cache
    -- คนใหม่จะเข้า fast path แล้วได้ progress ของคนเก่าไปเลย (ไม่โหลดแถวตัวเอง) และ persist()
    -- จะเขียน session ของคนใหม่ลง identifier ของคนเก่า → ต้องเทียบ identifier ทุกครั้งก่อนใช้ cache
    local identifier = getIdentifier(src)
    if cache[src] then
        if identifier and cache[src].identifier == identifier then
            if cb then cb(cache[src]) end return
        end
        if cache[src].dirty then persist(cache[src]) end -- เซฟของคนเก่าก่อนทิ้ง (เผื่อ playerDropped ไม่ทัน)
        cache[src] = nil -- คนละคน = ถือว่าไม่มี cache ต้องโหลดใหม่
    end
    if loading[src] then loading[src][#loading[src] + 1] = cb; return end -- คิวไว้ ให้โหลดครั้งเดียว
    loading[src] = { cb }

    local function finish(st)
        local cbs = loading[src]; loading[src] = nil
        -- ยืนยันอีกรอบตอน callback กลับมา: ผู้เล่นอาจหลุดกลางคันแล้ว id ถูกรีไซเคิลให้คนใหม่
        -- ระหว่างรอ MySQL ตอบ ถ้าไม่ตรงห้าม cache (ไม่งั้น entry ผีจะฟื้นหลัง playerDropped ล้างไปแล้ว)
        if st and st.identifier ~= getIdentifier(src) then st = nil end
        cache[src] = st
        for _, c in ipairs(cbs or {}) do if c then c(st) end end
    end
    if not identifier then finish(nil) return end

    MySQL.single('SELECT * FROM lp_battlepass WHERE identifier = ?', { identifier }, function(row)
        local st
        if row then
            st = {
                identifier = identifier,
                season     = row.season or currentSeason(),
                level      = tonumber(row.level) or 1,
                xp         = tonumber(row.xp) or 0,
                daily_xp   = tonumber(row.daily_xp) or 0,
                daily_date = row.daily_date,
                claimed    = {},
                claimedVIP = {},
            }
            for _, n in ipairs(BPArray.split(row.claimed))     do st.claimed[n]    = true end
            for _, n in ipairs(BPArray.split(row.claimed_vip)) do st.claimedVIP[n] = true end
        else
            st = {
                identifier = identifier, season = currentSeason(), level = 1, xp = 0,
                daily_xp = 0, daily_date = todayDate(), claimed = {}, claimedVIP = {},
            }
            MySQL.insert('INSERT IGNORE INTO lp_battlepass (identifier, season, daily_date) VALUES (?, ?, ?)',
                { identifier, st.season, st.daily_date })
        end
        applySeasonAndDaily(st)
        finish(st)
    end)
end

-- ════════════════════════════════════════════════════════════════════════════
--  Build payload + push (per-player, ไม่ broadcast — ข้อ 8)
-- ════════════════════════════════════════════════════════════════════════════
local function buildPayload(src, st)
    return {
        level      = st.level,
        xp         = st.xp,
        maxXp      = Config.XpPerLevel,
        maxLevel   = Config.MaxLevel,
        claimed    = claimedToCsv(st.claimed),
        claimedVIP = claimedToCsv(st.claimedVIP),
        rewards    = Config.LevelRewards,
        rewards2   = Config.LevelRewardsVIP,
        vip        = isVip(src) and 'Y' or 'N',
        season     = st.season,
        dailyXp    = st.daily_xp,
        dailyCap   = Config.DailyXpCap,
    }
end

local function pushState(src)
    local st = cache[src]; if not st then return end
    TriggerClientEvent(Events.pushState, src, buildPayload(src, st))
end

-- ════════════════════════════════════════════════════════════════════════════
--  Core: เพิ่ม XP (server-only) — isQuest=true จำกัดเพดานรายวัน, false = ไม่จำกัด
-- ════════════════════════════════════════════════════════════════════════════
local function doAddXP(src, amount, isQuest)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return end
    loadPlayer(src, function(st)
        if not st then return end
        applySeasonAndDaily(st)

        if st.level >= Config.MaxLevel then pushState(src); return end -- เต็มแล้ว

        local grant = amount
        if isQuest then
            local room = Config.DailyXpCap - st.daily_xp
            if room <= 0 then notify(src, Config.Locale.dailyCapped, 'error'); return end
            grant = math.min(amount, room)
            st.daily_xp = st.daily_xp + grant
        end

        local before = st.level
        st.xp = st.xp + grant
        while st.xp >= Config.XpPerLevel and st.level < Config.MaxLevel do
            st.xp = st.xp - Config.XpPerLevel
            st.level = st.level + 1
        end
        if st.level >= Config.MaxLevel then st.xp = 0 end
        st.dirty = true
        persist(st)

        if st.level > before then notify(src, Config.Locale.levelUp, 'success') end
        logTx(src, isQuest and 'xp-quest' or 'xp-item', ('+%d xp -> lv%d (xp %d)'):format(grant, st.level, st.xp))
        pushState(src)
    end)
end

-- Public API — resource อื่น (lp_daliyquest) เรียกได้ (server-to-server เท่านั้น ไม่ใช่ NetEvent)
exports('addQuestXP', function(src, amount) doAddXP(src, amount, true) end)   -- นับเพดานรายวัน
exports('addXP',      function(src, amount) doAddXP(src, amount, false) end)  -- ไม่จำกัด (special)
AddEventHandler(Events.addXP, function(src, amount, isQuest)                  -- local event เท่านั้น
    doAddXP(src, amount, isQuest ~= false)
end)

-- ════════════════════════════════════════════════════════════════════════════
--  Net events (client ยิงได้ — cooldown + validate ทุกตัว)
-- ════════════════════════════════════════════════════════════════════════════

RegisterNetEvent(Events.requestOpen, function()
    local src = source
    if not checkCooldown(src, 'requestOpen') then return end
    loadPlayer(src, function(st)
        if not st then return end
        TriggerClientEvent(Events.openUI, src, buildPayload(src, st))
    end)
end)

-- เคลม Standard 1 เลเวล
RegisterNetEvent(Events.reward, function(level)
    local src = source
    if not checkCooldown(src, 'claim') then return end
    level = tonumber(level)
    if not level or level ~= math.floor(level) or level < 1 or level > Config.MaxLevel then return end
    local cfg = Config.LevelRewards[level]; if not cfg then return end

    loadPlayer(src, function(st)
        if not st then return end
        applySeasonAndDaily(st)
        if level > st.level then notify(src, Config.Locale.notReached, 'error'); return end
        if st.claimed[level] then notify(src, Config.Locale.claimAlready, 'error'); return end

        -- ATOMIC: จอง slot ทันทีหลังเช็ค (ไม่มี yield คั่น) → กัน double-claim
        st.claimed[level] = true
        st.dirty = true
        giveReward(src, cfg)
        persist(st)
        notify(src, Config.Locale.claimSuccess, 'success')
        logTx(src, 'claim-std', ('lv%d %s x%d'):format(level, tostring(cfg.item or cfg.currency), cfg.amount))
        pushState(src)
    end)
end)

-- เคลม Premium 1 เลเวล (ต้องถือ vip_card)
RegisterNetEvent(Events.rewardVIP, function(level)
    local src = source
    if not checkCooldown(src, 'claim') then return end
    level = tonumber(level)
    if not level or level ~= math.floor(level) or level < 1 or level > Config.MaxLevel then return end
    local cfg = Config.LevelRewardsVIP[level]; if not cfg then return end

    loadPlayer(src, function(st)
        if not st then return end
        applySeasonAndDaily(st)
        if not isVip(src) then notify(src, Config.Locale.notVip, 'error'); pushState(src); return end
        if level > st.level then notify(src, Config.Locale.notReached, 'error'); return end
        if st.claimedVIP[level] then notify(src, Config.Locale.claimAlready, 'error'); return end

        st.claimedVIP[level] = true
        st.dirty = true
        giveReward(src, cfg)
        persist(st)
        notify(src, Config.Locale.claimSuccess, 'success')
        logTx(src, 'claim-vip', ('lv%d %s x%d'):format(level, tostring(cfg.item or cfg.currency), cfg.amount))
        pushState(src)
    end)
end)

-- เคลมทั้งหมดที่ถึงแล้ว (ทั้ง loop เป็น sync → atomic, กัน dupe)
RegisterNetEvent(Events.claimAllReward, function()
    local src = source
    if not checkCooldown(src, 'claim') then return end
    loadPlayer(src, function(st)
        if not st then return end
        applySeasonAndDaily(st)
        local vip = isVip(src)
        local granted = 0
        for lvl = 1, st.level do
            local s = Config.LevelRewards[lvl]
            if s and not st.claimed[lvl] then
                st.claimed[lvl] = true
                giveReward(src, s)
                granted = granted + 1
            end
            if vip then
                local v = Config.LevelRewardsVIP[lvl]
                if v and not st.claimedVIP[lvl] then
                    st.claimedVIP[lvl] = true
                    giveReward(src, v)
                    granted = granted + 1
                end
            end
        end
        if granted > 0 then
            st.dirty = true
            persist(st)
            notify(src, ('รับรางวัลทั้งหมด %d ชิ้น'):format(granted), 'success')
            logTx(src, 'claim-all', ('granted=%d lv<=%d vip=%s'):format(granted, st.level, tostring(vip)))
            pushState(src)
        else
            notify(src, 'ไม่มีรางวัลให้รับ', 'info')
        end
    end)
end)

-- ════════════════════════════════════════════════════════════════════════════
--  Usable items — เพิ่ม XP / เลเวล โดยตรง (ไม่จำกัดเพดาน)
-- ════════════════════════════════════════════════════════════════════════════
-- vorp_inventory ไม่มี re-entrancy guard ในเส้น UseItem — เดิม subItem แล้วเพิ่ม XP ทันทีโดยไม่เช็คว่า
-- หักไอเทมสำเร็จ กดรัวๆ (callback ยิงซ้อนก่อน subItem รอบแรกจะ propagate) ได้ XP หลายเท่าจากไอเทมใบเดียว
-- แก้: ให้ XP เข้าเฉพาะตอน subItem คืน success=true เท่านั้น (คลิกที่ 2 ที่ไอเทมหมดแล้ว sub จะ fail ไม่เพิ่ม XP ซ้ำ)
for _, v in ipairs(Config.XpUpItem or {}) do
    exports.vorp_inventory:registerUsableItem(v.item, function(data)
        local src = data.source
        exports.vorp_inventory:subItem(src, v.item, 1, nil, function(success)
            if success then doAddXP(src, v.xp, false) end
        end)
    end)
end

for _, v in ipairs(Config.LevelUpItem or {}) do
    exports.vorp_inventory:registerUsableItem(v.item, function(data)
        local src = data.source
        exports.vorp_inventory:subItem(src, v.item, 1, nil, function(success)
            if success then doAddXP(src, v.level * Config.XpPerLevel, false) end
        end)
    end)
end

-- ════════════════════════════════════════════════════════════════════════════
--  Admin commands (เช็ค group ฝั่ง server เท่านั้น — ข้อ 9)
--    /addbp <playerId> <levels>   เพิ่มเลเวลให้เป้าหมาย
--    /removebp <playerId>         รีเซ็ต pass ของเป้าหมาย
-- ════════════════════════════════════════════════════════════════════════════
RegisterCommand('addbp', function(src, args)
    local char = getChar(src)
    if not char or not isAdmin(char) then notify(src, Config.Locale.adminOnly, 'error'); return end
    local target = tonumber(args[1])
    local levels = math.max(1, math.floor(tonumber(args[2]) or 1))
    if not target or not GetPlayerName(target) then notify(src, Config.Locale.notOnline, 'error'); return end
    doAddXP(target, levels * Config.XpPerLevel, false)
    notify(src, ('เพิ่ม %d เลเวลให้ ID %d'):format(levels, target), 'success')
    logTx(src, 'admin-addbp', ('target=%d +%d lv'):format(target, levels))
end, false)

RegisterCommand('removebp', function(src, args)
    local char = getChar(src)
    if not char or not isAdmin(char) then notify(src, Config.Locale.adminOnly, 'error'); return end
    local target = tonumber(args[1])
    if not target or not GetPlayerName(target) then notify(src, Config.Locale.notOnline, 'error'); return end
    loadPlayer(target, function(st)
        if not st then return end
        st.level, st.xp = 1, 0
        st.claimed, st.claimedVIP = {}, {}
        st.daily_xp = 0; st.daily_date = todayDate()
        st.season = currentSeason()
        st.dirty = true
        persist(st)
        pushState(target)
        notify(src, ('รีเซ็ต BattlePass ของ ID %d'):format(target), 'success')
        logTx(src, 'admin-removebp', ('target=%d'):format(target))
    end)
end, false)

-- ════════════════════════════════════════════════════════════════════════════
--  Cleanup (ข้อ 3/12)
-- ════════════════════════════════════════════════════════════════════════════
AddEventHandler('playerDropped', function()
    local src = source
    if cache[src] and cache[src].dirty then persist(cache[src]) end
    cache[src]     = nil
    cooldowns[src] = nil
    loading[src]   = nil
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, st in pairs(cache) do if st.dirty then persist(st) end end
end)
