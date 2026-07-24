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

-- 'YYYY-MM-DD' -> 'YYYY-MM' | เลขวันที่ของเดือน
-- ตัดจากสตริงตรงๆ ไม่เรียก os.date ซ้ำ เพื่อให้ทุกที่อ่านจากค่าเดียวกันเสมอ
-- (ถ้าเรียกแยกกันคนละครั้ง มีโอกาสคร่อมนาที 04:00 พอดีแล้วได้คนละวัน)
local function monthOf(date)  return date and date:sub(1, 7) or nil end
local function dayOfMonth(date) return tonumber(date:sub(9, 10)) end

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

-- คืน state ใน cache เฉพาะเมื่อ src ยังเป็นผู้เล่นคนเดิมจริงๆ
-- FiveM เอา server id ของคนที่หลุดไปแล้วไปแจกให้คนใหม่ได้ ถ้า entry เก่ายังค้างอยู่ คนใหม่จะได้
-- progress ของคนเก่าไปใช้ (เคลมของที่คนเก่าเคลมไปแล้วไม่ได้ / เคลมของที่ตัวเองยังไม่ควรได้)
-- และ persist() จะเขียน session ของคนใหม่ลง identifier ของคนเก่า → ไม่ตรงถือว่าไม่มี cache
local function getCache(src)
    local st = cache[src]
    if not st then return nil end
    if st.identifier ~= getIdentifier(src) then
        if st.dirty then persist(st) end -- เซฟของคนเก่าก่อนทิ้ง (เผื่อ playerDropped ไม่ทัน)
        cache[src] = nil
        return nil
    end
    return st
end

-- ปรับ state ให้ตรง welfare-day ปัจจุบัน
--
-- ⚠️ ผูกกับ "วันที่จริงในปฏิทิน" ไม่ใช่ streak
--    การ์ดใบที่ N = วันที่ N ของเดือน — เข้าวันที่ 1 แล้วหายไปโผล่วันที่ 30 จะได้แค่ใบ 1 กับ 30
--    ใบ 2-29 ที่ขาดไปถือว่าเสียถาวร (ยกเว้น VIP ที่ย้อนเก็บได้ ดู canClaimDay)
--
--    ของเดิมเป็น streak: +1 ทุกครั้งที่ล็อกอินวันใหม่ ไม่สนว่าห่างกันกี่วัน เคสข้างบนจะได้ใบ 1 กับ 2
--
-- ไม่ต้องแก้ schema — เดือนของรอบดูจาก last_welfare_date ที่เก็บอยู่แล้ว (7 ตัวแรก = YYYY-MM)
-- ข้ามเดือน = รอบใหม่ ล้าง claimed ทั้งสองแถว
-- cycle_day ยังเขียนต่อ (= วันที่ของเดือน) เพื่อไม่ให้ค่าใน DB กลายเป็นขยะที่อ่านไม่รู้เรื่อง
local function refreshDay(st)
    local wd    = welfareDate()
    local today = dayOfMonth(wd)

    if st.last_welfare_date ~= wd then
        if monthOf(st.last_welfare_date) ~= monthOf(wd) then
            st.free, st.vip = {}, {}
        end
        st.last_welfare_date = wd
        st.cycle_day = today
        st.dirty = true
    elseif st.cycle_day ~= today then
        st.cycle_day = today
        st.dirty = true
    end

    if st.online_date ~= wd then
        st.online_date     = wd
        st.online_seconds  = 0
        st.online_claimed  = {}
        st.dirty = true
    end
end

-- ใครเคลมวันไหนได้บ้าง — ใช้ร่วมกันระหว่าง buildState (แสดงผล) กับ claim (ตัดสินจริง)
-- เพื่อไม่ให้ UI กับ server ตัดสินคนละแบบ
--   วันนี้        -> เคลมได้ทุกคน
--   วันที่ผ่านมา  -> เฉพาะ VIP (ย้อนได้ทั้งเดือน ไม่จำกัดจำนวนวัน และครอบทั้งแถวฟรีและแถวทอง)
--   วันอนาคต     -> ไม่มีใครเคลมได้
-- การ์ดใบ 29-30 ในเดือนกุมภาพันธ์ตกเป็นวันอนาคตตลอดทั้งเดือนโดยธรรมชาติ จึงเคลมไม่ได้เอง
-- ไม่ต้องเขียนเงื่อนไขแยก (ตรงตามที่ตกลง: คงการ์ด 30 ใบ ไม่ยืดหดตามความยาวเดือน)
local function canClaimDay(day, today, vip)
    if day == today then return true end
    if day < today then return vip end
    return false
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
        -- ยืนยันว่า src ยังเป็นคนเดิมตอน callback กลับมา: ผู้เล่นอาจหลุดกลางคันแล้ว FiveM
        -- เอา id ไปแจกคนใหม่ระหว่างรอ MySQL ตอบ ถ้าไม่ตรงห้าม cache — ไม่งั้น entry ของคนเก่า
        -- จะฟื้นขึ้นมาหลัง playerDropped ล้างไปแล้ว และคนใหม่จะได้ progress ผิดคน
        if identifier ~= getIdentifier(src) then if cb then cb(nil) end return end
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
    -- 'missed' = วันที่ผ่านไปแล้วและเคลมไม่ได้อีก (คนไม่ใช่ VIP) — แยกจาก 'locked' ที่แปลว่า
    -- "ยังไม่ถึงวัน" โดยตั้งใจ ผู้เล่นต้องแยกออกว่าอันไหนรอได้ อันไหนเสียไปแล้ว
    -- ไม่งั้นกติกา "ขาดวันแล้วเสียถาวร" จะมองไม่เห็นเลยจากหน้าจอ
    local function cardState(claimed, d)
        if claimed[d] then return 'completed' end
        if canClaimDay(d, cd, vip) then return 'current' end
        if d < cd then return 'missed' end
        return 'locked'
    end

    local dayCards, vipCards = {}, {}
    for d = 1, Config.Daily.cycleDays do
        local f = Config.DailyFree[d]
        dayCards[d] = { num = d, label = f and f.title or '', img = f and f.img or nil,
                        state = cardState(st.free, d) }

        -- แถวทองต้องเป็น VIP ถึงจะกดได้ แม้เป็นวันปัจจุบันก็ตาม
        -- คนไม่ใช่ VIP เห็นทุกใบที่ยังไม่ได้เคลมเป็น 'locked' ไม่ใช่ 'missed' — เพราะเขาไม่เคยมี
        -- สิทธิ์ในแถวนี้ตั้งแต่แรก การขึ้นว่า "ขาดวัน" จะสื่อผิดว่าเคยกดได้แล้วพลาดไปเอง
        local v = Config.DailyVip[d]
        local vstate = cardState(st.vip, d)
        if not vip and vstate ~= 'completed' then vstate = 'locked' end
        vipCards[d] = { num = d, label = v and v.title or '', img = v and v.img or nil,
                        state = vstate, vip = true }
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
        currentDay  = cd, -- สำหรับ "DAY X / 30" ที่หัว UI
    }
end

local function pushState(src)
    local st = getCache(src); if not st then return end
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
    local st = getCache(src)
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

    local st = getCache(src); if not st then return end
    refreshDay(st)

    if day < 1 or day > Config.Daily.cycleDays then return end

    -- ตัดสินสิทธิ์ตามวันที่จริง — ตรรกะเดียวกับที่ buildState ใช้วาดการ์ด
    -- client ยิง day 30 ตอนวันที่ 5 ไม่ได้ และคนไม่ใช่ VIP ยิงย้อนวันที่ผ่านมาไม่ได้
    -- (isVip อ่านจากไอเทมในกระเป๋าฝั่ง server ไม่เชื่อ flag ที่ client ส่งมา)
    local vip = isVip(src)
    if not canClaimDay(day, st.cycle_day, vip) then
        notify(src, day < st.cycle_day and Config.Locale.claimMissed or Config.Locale.claimLocked, 'error')
        return
    end

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

    if track == 'vip' and not vip then
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
            local st  = getCache(src)
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
--    /welfaredebug nextday      แกล้งเป็นวันถัดไปของเดือน
--    /welfaredebug setday <n>   แกล้งเป็นวันที่ n ของเดือน (เทสเคสขาดวันได้ตรงๆ)
--    /welfaredebug newmonth     จำลองขึ้นเดือนใหม่ (ล้าง claimed ทั้งสองแถว)
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
        local st = getCache(src)
        if not st then notify(src, 'welfaredebug: เปิด /welfare ก่อน (ยังไม่โหลด progress)', 'error'); return end
        local sub = tostring(args[1] or ''):lower()

        if sub == 'nextday' or sub == 'setday' then
            -- ระบบผูกปฏิทินจริงแล้ว จึงแกล้งวันด้วยการเขียน last_welfare_date ย้อน/ไปข้างหน้า
            -- ให้ refreshDay รอบถัดไปคิดจากค่านั้น (ตั้ง cycle_day ตรงๆ อย่างเดียวไม่พอ
            -- เพราะ refreshDay จะเห็นว่า last_welfare_date เป็นวันนี้แล้วดึงกลับทันที)
            local nd
            if sub == 'setday' then
                nd = tonumber(args[2])
                if not nd or nd < 1 or nd > Config.Daily.cycleDays then
                    notify(src, 'welfaredebug: setday <1-' .. Config.Daily.cycleDays .. '>', 'error'); return
                end
            else
                nd = (st.cycle_day or 1) + 1
                if nd > Config.Daily.cycleDays then nd = 1 end
            end

            local wd = welfareDate()
            st.last_welfare_date = ('%s-%02d'):format(monthOf(wd), nd)
            st.cycle_day = nd
            st.dirty = true; persist(st); pushState(src)
            notify(src, ('welfaredebug: แกล้งเป็นวันที่ %d ของเดือน'):format(nd), 'success')

        elseif sub == 'newmonth' then
            -- จำลองขึ้นเดือนใหม่: ล้าง claimed ทั้งสองแถวเหมือนที่ refreshDay ทำจริง
            st.free, st.vip = {}, {}
            st.last_welfare_date = welfareDate()
            st.cycle_day = dayOfMonth(st.last_welfare_date)
            st.dirty = true; persist(st); pushState(src)
            notify(src, 'welfaredebug: ล้าง claimed แล้ว (จำลองขึ้นเดือนใหม่)', 'success')

        elseif sub == 'reset' then
            st.free, st.vip = {}, {}
            st.cycle_day = dayOfMonth(welfareDate())
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
            notify(src, 'welfaredebug: nextday | setday <1-30> | newmonth | reset | onlinereset | online <วินาที> | vip', 'info')
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
    -- ที่นี่อ่าน cache ตรงๆ ไม่ผ่าน getCache: ตอนหลุด VORP อาจปลด user ไปแล้ว getIdentifier
    -- จะคืน nil ทำให้ getCache มองเป็น "คนละคน" แล้วข้ามการเซฟ → เวลาออนไลน์ที่สะสมไว้หาย
    -- entry ตรงนี้การันตีว่าเป็นของเจ้าของจริงแล้วจาก guard ใน loadProgress/getCache
    -- และ persist() เขียนด้วย st.identifier เสมอ จึงลงแถวถูกคนแน่นอน
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
