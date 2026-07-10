-- lp_welfarelogin / server/server.lua
-- Server-authoritative. Client ส่งได้แค่ "คำขอเคลม" (track + day) — server ตัดสินทุกอย่าง:
-- day-index, สิทธิ์ VIP, ตาราง reward, เวลาออนไลน์ ล้วนอยู่ฝั่ง server เท่านั้น
-- online reward = อัตโนมัติ 100% (client ไม่ส่งอะไรเลย)

local VORPcore = exports.vorp_core:GetCore()

-- ════════════════════════════════════════════════════════════════════════════
--  DB (oxmysql) — parameterized ทุก query, CREATE TABLE IF NOT EXISTS (migration ปลอดภัย)
-- ════════════════════════════════════════════════════════════════════════════
MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `welfare_progress` (
            `identifier`        VARCHAR(60) NOT NULL,
            `cycle_day`         INT         NOT NULL DEFAULT 1,
            `last_welfare_date` VARCHAR(10) NULL,
            `free_claimed`      TEXT        NULL,
            `vip_claimed`       TEXT        NULL,
            `online_seconds`    INT         NOT NULL DEFAULT 0,
            `online_claimed`    TEXT        NULL,
            `online_date`       VARCHAR(10) NULL,
            `last_popup_date`   VARCHAR(10) NULL,
            PRIMARY KEY (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end)

-- ════════════════════════════════════════════════════════════════════════════
--  Helpers
-- ════════════════════════════════════════════════════════════════════════════
local function dbg(fmt, ...)
    if Config.Debug then print(('[lp_welfarelogin] ' .. fmt):format(...)) end
end

-- log ทุก transaction เงิน/item เสมอ (ไม่ขึ้นกับ Debug) — observability (ข้อ 11)
local function logTx(src, kind, id, def)
    local parts = {}
    for _, r in ipairs(def.rewards) do
        parts[#parts + 1] = (r.type == 'currency')
            and (r.currency .. ' x' .. r.amount)
            or  (tostring(r.name) .. ' x' .. r.amount)
    end
    print(('[lp_welfarelogin][TX] src=%s name=%s kind=%s id=%s reward=%s')
        :format(tostring(src), tostring(GetPlayerName(src) or '?'), kind, tostring(id), table.concat(parts, ', ')))
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

-- welfare-day: พลิกตอน Config.ResetHour (เลื่อนเวลาถอยหลังเท่ากับ ResetHour แล้วเอาแค่วันที่)
local function welfareDate()
    return os.date('%Y-%m-%d', os.time() - ((Config.ResetHour or 4) * 3600))
end

-- JSON array (TEXT ใน DB) <-> set { [id]=true }
local function jsonToSet(s)
    local set = {}
    if s and s ~= '' then
        local ok, arr = pcall(json.decode, s)
        if ok and type(arr) == 'table' then
            for _, v in ipairs(arr) do set[tonumber(v) or v] = true end
        end
    end
    return set
end
local function setToJson(set)
    local arr = {}
    for k, v in pairs(set) do if v then arr[#arr + 1] = k end end
    if #arr == 0 then return '[]' end
    return json.encode(arr)
end

-- ── VIP: เช็คไอเทมในกระเป๋าฝั่ง server (ไม่เชื่อ flag จาก client) ────────────
local function isVip(src)
    for _, item in ipairs(Config.VIP.items or {}) do
        local cnt = exports.vorp_inventory:getItemCount(src, nil, item)
        if cnt and cnt > 0 then return true end
    end
    return false
end

-- ── แจกรางวัล (server คำนวณ/หยิบจาก config เท่านั้น) ────────────────────────
-- ตั้งใจไม่เช็ค canCarryItem ก่อนแจก — vorp_inventory:addItem ไม่มี hard cap ในตัวอยู่แล้ว
-- (ใส่เกิน weight/limit ได้โดยธรรมชาติของ export นี้) จึงปล่อยให้ทะลุ limit ไปเลย ผู้เล่นจะได้
-- ของรางวัลรายวัน/ออนไลน์เสมอ ไม่มีเคสตกหล่นเพราะกระเป๋าเต็ม
local CURRENCY_ID = { money = 0, gold = 1, rol = 2 }
local function grantRewards(src, rewards)
    local char = getChar(src)
    for _, r in ipairs(rewards) do
        if r.type == 'item' then
            exports.vorp_inventory:addItem(src, r.name, r.amount)
        elseif r.type == 'currency' and char then
            char.addCurrency(CURRENCY_ID[r.currency] or 0, r.amount)
        end
    end
end

-- ════════════════════════════════════════════════════════════════════════════
--  Rate limiting / anti-spam (ข้อ 3) — mirror lp_daliyquest
-- ════════════════════════════════════════════════════════════════════════════
local cooldowns   = {}
local COOLDOWN_MS = { claim = 500, requestState = 1000, playerReady = 3000 }
local function checkCooldown(src, action)
    local t = GetGameTimer()
    cooldowns[src] = cooldowns[src] or {}
    local last = cooldowns[src][action] or 0
    if (t - last) < (COOLDOWN_MS[action] or 500) then return false end
    cooldowns[src][action] = t
    return true
end

-- ════════════════════════════════════════════════════════════════════════════
--  Cache (per-source) — cache hot data, ไม่ SELECT ใน hot path (ข้อ 4)
-- ════════════════════════════════════════════════════════════════════════════
local cache = {} -- [src] = { identifier, cycle_day, last_welfare_date, free={}, vip={},
                 --           online_seconds, online_claimed={}, online_date, last_popup_date, dirty }

local function persist(st)
    if not st then return end
    MySQL.update([[
        UPDATE welfare_progress SET
            cycle_day = ?, last_welfare_date = ?, free_claimed = ?, vip_claimed = ?,
            online_seconds = ?, online_claimed = ?, online_date = ?, last_popup_date = ?
        WHERE identifier = ?
    ]], {
        st.cycle_day, st.last_welfare_date, setToJson(st.free), setToJson(st.vip),
        st.online_seconds, setToJson(st.online_claimed), st.online_date, st.last_popup_date,
        st.identifier,
    })
    st.dirty = false
end

-- ปรับ state ให้ตรง welfare-day ปัจจุบัน: เลื่อน cycle_day (+1 ต่อวันที่ล็อกอิน,
-- ครบ cycleDays วนกลับ 1 + ล้าง claimed) และรีเซ็ต online เมื่อข้ามวัน
local function refreshDay(st)
    local wd = welfareDate()
    if st.last_welfare_date ~= wd then
        if st.last_welfare_date == nil then
            st.cycle_day = st.cycle_day or 1           -- ครั้งแรก = day 1
        else
            local nd = (st.cycle_day or 1) + 1
            if nd > Config.Daily.cycleDays then
                nd = 1
                st.free, st.vip = {}, {}               -- รอบใหม่ ล้าง claimed
            end
            st.cycle_day = nd
        end
        st.last_welfare_date = wd
        st.dirty = true
    end
    if st.online_date ~= wd then
        st.online_date     = wd
        st.online_seconds  = 0
        st.online_claimed  = {}
        st.dirty = true
    end
end

local function loadProgress(src, cb)
    local identifier = getIdentifier(src)
    if not identifier then if cb then cb(nil) end return end
    MySQL.query('SELECT * FROM welfare_progress WHERE identifier = ?', { identifier }, function(rows)
        local st
        if rows and rows[1] then
            local r = rows[1]
            st = {
                identifier        = identifier,
                cycle_day         = r.cycle_day or 1,
                last_welfare_date = r.last_welfare_date,
                free              = jsonToSet(r.free_claimed),
                vip               = jsonToSet(r.vip_claimed),
                online_seconds    = r.online_seconds or 0,
                online_claimed    = jsonToSet(r.online_claimed),
                online_date       = r.online_date,
                last_popup_date   = r.last_popup_date,
            }
        else
            st = {
                identifier = identifier, cycle_day = 1, last_welfare_date = nil,
                free = {}, vip = {}, online_seconds = 0, online_claimed = {},
                online_date = welfareDate(), last_popup_date = nil,
            }
            MySQL.insert('INSERT INTO welfare_progress (identifier, cycle_day, online_date) VALUES (?, ?, ?)',
                { identifier, 1, st.online_date })
        end
        refreshDay(st)
        cache[src] = st
        if cb then cb(st) end
    end)
end

-- ════════════════════════════════════════════════════════════════════════════
--  Build NUI payload (per-player เท่านั้น — ไม่ broadcast, ข้อ 8)
-- ════════════════════════════════════════════════════════════════════════════
local function buildState(src, st)
    local vip = isVip(src)
    local cd  = st.cycle_day
    local dayCards, vipCards = {}, {}
    for d = 1, Config.Daily.cycleDays do
        local f, state = Config.DailyFree[d], nil
        if st.free[d] then state = 'completed'
        elseif d <= cd then state = 'current'
        else state = 'locked' end
        dayCards[d] = { num = d, label = f and f.title or '', img = f and f.img or nil, state = state }

        local v, vstate = Config.DailyVip[d], nil
        if st.vip[d] then vstate = 'completed'
        elseif d <= cd then vstate = vip and 'current' or 'locked'
        else vstate = 'locked' end
        vipCards[d] = { num = d, label = v and v.title or '', img = v and v.img or nil, state = vstate, vip = true }
    end

    local onlineSlots = {}
    for i, tier in ipairs(Config.Online) do
        onlineSlots[i] = {
            hours = tier.hours,
            img   = tier.img,
            state = st.online_claimed[tier.id] and 'done' or 'locked',
        }
    end

    -- คูณด้วย OnlineTestSpeedup ตัวเดียวกับที่ onlineThresholdSec() ใช้ปลดล็อก tier
    -- เพื่อให้หลอด progress กับ checkmark ตรงกันเสมอ (prod: speedup=1 = ไม่มีผลใดๆ)
    local displayHours = (st.online_seconds * (Config.OnlineTestSpeedup or 1)) / 3600

    return {
        action      = 'open',
        dayCards    = dayCards,
        vipCards    = vipCards,
        onlineSlots = onlineSlots,
        onlineHours = displayHours,
        onlineMax   = Config.OnlineMaxHours or 6,
        isVip       = vip,
    }
end

local function pushState(src)
    local st = cache[src]; if not st then return end
    TriggerClientEvent('lp_welfarelogin:state', src, buildState(src, st))
end

-- ════════════════════════════════════════════════════════════════════════════
--  Net events (client ยิงได้ — ทุกตัวมี cooldown + validate)
-- ════════════════════════════════════════════════════════════════════════════

-- client บอกว่าเลือกตัวละครเสร็จ (จาก vorp:SelectedCharacter) → eager-load cache + auto-popup
RegisterNetEvent('lp_welfarelogin:playerReady', function()
    local src = source
    if not checkCooldown(src, 'playerReady') then return end
    loadProgress(src, function(st)
        if not st then return end
        local popup = false
        if Config.AutoPopup then
            local wd = welfareDate()
            if st.last_popup_date ~= wd then
                st.last_popup_date = wd
                st.dirty = true
                persist(st)
                popup = true
            end
        end
        local state = buildState(src, st)
        state.popup = popup
        TriggerClientEvent('lp_welfarelogin:state', src, state)
    end)
end)

-- ขอ state ล่าสุด (ตอนเปิด UI เอง)
RegisterNetEvent('lp_welfarelogin:requestState', function()
    local src = source
    if not checkCooldown(src, 'requestState') then return end
    local st = cache[src]
    if st then
        refreshDay(st)
        pushState(src)
    else
        loadProgress(src, function(s) if s then pushState(src) end end)
    end
end)

-- เคลม daily login (track = 'free'|'vip') — server หา reward/day เอง, กัน dupe แบบ atomic
RegisterNetEvent('lp_welfarelogin:claim', function(track, day)
    local src = source
    if not checkCooldown(src, 'claim') then return end

    -- validate input จาก client (ข้อ 1)
    if track ~= 'free' and track ~= 'vip' then return end
    day = tonumber(day)
    if not day or day ~= math.floor(day) then return end

    local st = cache[src]; if not st then return end
    refreshDay(st)

    -- bounds เทียบ cycle_day ของ server (client จะยิง day 30 ตอนอยู่ day 5 ไม่ได้)
    if day < 1 or day > st.cycle_day then return end

    local claimedSet = (track == 'free') and st.free or st.vip
    if claimedSet[day] then
        notify(src, Config.Locale.claimAlready, 'error')
        return
    end

    -- ── ATOMIC: จอง slot ทันทีหลังเช็ค (ไม่มี yield คั่นระหว่างเช็คกับ set) ──
    -- event handler ของ RedM รันจนจบโดยไม่ถูกแทรก การยิงซ้ำในเฟรมเดียวกันตัวที่ 2
    -- จะเห็น claimedSet[day]=true แล้ว abort → กัน double-claim ได้แน่นอน
    claimedSet[day] = true
    st.dirty = true

    -- validate ที่เหลือ; ถ้า fail คืน slot (revert)
    local def = (track == 'free' and Config.DailyFree[day]) or Config.DailyVip[day]
    if not def then claimedSet[day] = nil; return end

    if track == 'vip' and not isVip(src) then
        claimedSet[day] = nil
        notify(src, Config.Locale.notVip, 'error')
        pushState(src) -- รีเฟรชการ์ดให้เป็น locked ทันที เผื่อ UI ค้าง state เก่าตอนยังมี vip_card อยู่
        return
    end
    -- commit
    grantRewards(src, def.rewards)
    persist(st)
    logTx(src, 'daily-' .. track, day, def)
    notify(src, Config.Locale.claimSuccess, 'success')
    pushState(src)
end)

-- ════════════════════════════════════════════════════════════════════════════
--  Online reward — แจก tier อัตโนมัติ (1 thread รวมทุกผู้เล่น, ข้อ 6)
--  client ไม่มีส่วนเกี่ยวข้องเลย (zero trust surface)
-- ════════════════════════════════════════════════════════════════════════════
-- เกณฑ์วินาทีของแต่ละ tier (หาร OnlineTestSpeedup เพื่อเทสให้ยิงเร็ว; prod=1 = ไม่มีผล)
local function onlineThresholdSec(tier)
    return (tier.minutes * 60) / (Config.OnlineTestSpeedup or 1)
end

-- เช็ค/แจก tier ที่ถึงเกณฑ์ (ใช้ทั้ง ticker และคำสั่ง debug) — คืน true ถ้ามีการแจก
local function grantOnlineTiers(src, st)
    local changed = false
    for _, tier in ipairs(Config.Online) do
        if not st.online_claimed[tier.id] and st.online_seconds >= onlineThresholdSec(tier) then
            st.online_claimed[tier.id] = true
            grantRewards(src, tier.rewards)
            logTx(src, 'online', tier.id, tier)
            notify(src, Config.Locale.onlineReward, 'success')
            changed = true
        end
    end
    return changed
end

CreateThread(function()
    local interval = Config.OnlineTickSeconds or 60
    while true do
        Wait(interval * 1000)
        for _, pid in ipairs(GetPlayers()) do
            local src = tonumber(pid)
            local st  = cache[src]
            if st then
                refreshDay(st)                       -- จัดการเลื่อนวัน + รีเซ็ต online ข้าม 04:00
                st.online_seconds = st.online_seconds + interval
                st.dirty = true
                if grantOnlineTiers(src, st) then pushState(src) end
            end
        end
    end
end)

-- ════════════════════════════════════════════════════════════════════════════
--  Debug command (เฉพาะ Config.Debug=true + admin) — เทสได้โดยไม่ต้องรอวันจริง
--    /welfaredebug nextday      เลื่อนไปวันถัดไป (จำลอง welfare-day ใหม่)
--    /welfaredebug reset        รีเซ็ต progress ของตัวเองเป็นเริ่มใหม่ (ทั้ง daily login + online)
--    /welfaredebug onlinereset  รีเซ็ตเฉพาะ online reward (ไม่แตะ daily login ที่เคลมไปแล้ว)
--    /welfaredebug online <s>   บวกเวลาออนไลน์ <s> วินาที แล้วเช็ค tier ทันที
--    /welfaredebug vip          เช็คสถานะ VIP ปัจจุบัน (มี vip_card ไหม)
-- ════════════════════════════════════════════════════════════════════════════
if Config.Debug then
    RegisterCommand('welfaredebug', function(src, args)
        local char = getChar(src)
        if not char or (char.group ~= 'admin' and char.group ~= 'superadmin') then
            notify(src, 'welfaredebug: เฉพาะแอดมิน', 'error'); return
        end
        local st = cache[src]
        if not st then notify(src, 'welfaredebug: เปิด /welfare ก่อน (ยังไม่โหลด progress)', 'error'); return end
        local sub = tostring(args[1] or ''):lower()

        if sub == 'nextday' then
            local nd = (st.cycle_day or 1) + 1
            if nd > Config.Daily.cycleDays then nd = 1; st.free, st.vip = {}, {} end
            st.cycle_day = nd
            st.last_welfare_date = welfareDate()
            st.dirty = true; persist(st); pushState(src)
            notify(src, ('welfaredebug: cycle_day = %d'):format(nd), 'success')

        elseif sub == 'reset' then
            st.cycle_day = 1; st.free, st.vip = {}, {}
            st.online_seconds = 0; st.online_claimed = {}
            st.last_welfare_date = welfareDate(); st.online_date = welfareDate()
            st.last_popup_date = nil  -- ให้ auto-popup เด้งใหม่ได้ตอน relog
            st.dirty = true; persist(st); pushState(src)
            notify(src, 'welfaredebug: reset progress แล้ว', 'success')

        elseif sub == 'onlinereset' then
            st.online_seconds = 0; st.online_claimed = {}
            st.online_date = welfareDate()
            st.dirty = true; persist(st); pushState(src)
            notify(src, 'welfaredebug: รีเซ็ต online reward แล้ว', 'success')

        elseif sub == 'online' then
            local add = tonumber(args[2]) or 3600
            st.online_seconds = st.online_seconds + add
            st.dirty = true
            grantOnlineTiers(src, st)
            persist(st); pushState(src)
            notify(src, ('welfaredebug: +%ds (รวม %ds online)'):format(add, st.online_seconds), 'info')

        elseif sub == 'vip' then
            notify(src, ('welfaredebug: isVip = %s'):format(tostring(isVip(src))), 'info')

        else
            notify(src, 'welfaredebug: nextday | reset | onlinereset | online <วินาที> | vip', 'info')
        end
    end, false)
end

-- ════════════════════════════════════════════════════════════════════════════
--  Persistence lifecycle (ข้อ 12) — autosave / drop / resource stop
-- ════════════════════════════════════════════════════════════════════════════
CreateThread(function()
    while true do
        Wait((Config.AutoSaveSeconds or 120) * 1000)
        for _, st in pairs(cache) do
            if st.dirty then persist(st) end
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    if cache[src] then persist(cache[src]) end
    cache[src]     = nil
    cooldowns[src] = nil
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, st in pairs(cache) do
        if st.dirty then persist(st) end
    end
end)
