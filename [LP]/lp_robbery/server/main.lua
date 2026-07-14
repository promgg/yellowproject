-- lp_robbery / server/main.lua
-- Server is the SINGLE authority for every state transition. Store is a single-step
-- lockpick loot (lootStore); bank keeps the *request*/*confirm* bomb-plant dance
-- (requestBank/confirmBankBlow) followed by lootBank. Every one of those events
-- re-validates source/item/coords/job/state here. This closes the devchacha-robbery
-- exploit where the item was only checked in a separate `canRob` callback that a cheat
-- client could skip entirely by firing the state-transition event directly (free
-- robbery, no item spent, no distance/police check).

local VORPcore = exports.vorp_core:GetCore()

-- ════════════════════════════════════════════════════════════════════════════
--  Helpers
-- ════════════════════════════════════════════════════════════════════════════
local function dbg(fmt, ...)
    if Config.Debug then print(('[lp_robbery] ' .. fmt):format(...)) end
end

-- observability (checklist #11) — payouts logged always
local function logTx(src, kind, detail)
    print(('[lp_robbery][TX] src=%s name=%s kind=%s | %s')
        :format(tostring(src), tostring(GetPlayerName(src) or '?'), kind, tostring(detail)))
end

-- suspicious/tamper attempts logged ALWAYS (ไม่ผูก Config.Debug) — client ปกติยิงไม่ถึงเคสพวกนี้
-- (เช่น confirm โดยไม่มี pending, ข้ามฟิวส์, type ปลอม) เห็นได้ในโปรดักชันเพื่อจับ cheater (ข้อ 11)
local function logSus(src, kind, detail)
    print(('[lp_robbery][SUSPECT] src=%s name=%s kind=%s | %s')
        :format(tostring(src), tostring(GetPlayerName(src) or '?'), kind, tostring(detail)))
end

local function notify(src, text, ntype)
    TriggerClientEvent('pNotify:SendNotification', src, { text = text, type = ntype or 'info', timeout = 4000 })
end

local function getChar(src)
    local user = VORPcore.getUser(src)
    return user and user.getUsedCharacter or nil
end

-- police count / alert: job read from the character server-side ONLY — never trust a
-- client-sent job (checklist #9)
local function getPoliceCount()
    local count = 0
    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        local char = src and getChar(src)
        if char then
            for _, job in ipairs(Config.Police.Jobs) do
                if char.job == job then count = count + 1; break end
            end
        end
    end
    return count
end

local function policeAlert(label, coords)
    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        local char = src and getChar(src)
        if char then
            for _, job in ipairs(Config.Police.Jobs) do
                if char.job == job then
                    TriggerClientEvent('lp_robbery:cl:policeAlert', src, label, coords)
                    notify(src, string.format(Config.PoliceAlertFormat, label), 'alert')
                    break
                end
            end
        end
    end
end

-- ════════════════════════════════════════════════════════════════════════════
--  GlobalState — shared robbery states (checklist #8: legit shared broadcast,
--  every nearby player must see the same countdown/looted status)
-- ════════════════════════════════════════════════════════════════════════════
local function getState(key)
    local states = GlobalState.lp_robbery_states or {}
    return states[key]
end

local function setState(key, value)
    local states = GlobalState.lp_robbery_states or {}
    states[key] = value
    GlobalState.lp_robbery_states = states
end

-- แปลงค่า state ดิบเป็นสถานะเชิงตรรกะ + เวลาที่เหลือ (วินาที)
--   'fresh'   — งัดได้ (ยังไม่ปล้น หรือ cooldown reloot ผ่านแล้ว)
--   'active'  — กำลังปลดล็อค/เย็นตัว ยังไม่ถึงเวลาเก็บ (คืน remaining)
--   'open'    — ปลดล็อคครบแล้ว พร้อมเก็บของ
--   'cooling' — เพิ่งถูกปล้น ยังติด reloot cooldown (คืน remaining)
-- reloot cooldown ที่หมดอายุจะถูกตีความเป็น 'fresh' อัตโนมัติ (ไม่ต้องมี timer แยกมาล้าง)
local function statusOf(key)
    local s = getState(key)
    if type(s) == 'table' then
        if s.state == 'unlocking' then
            local rem = (s.unlockTime or 0) - os.time()
            if rem > 0 then return 'active', rem end
            return 'open'
        elseif s.state == 'looted' then
            local rem = (s.relootAt or 0) - os.time()
            if rem > 0 then return 'cooling', rem end
            return 'fresh'
        end
    end
    return 'fresh'
end

-- Reset on resource start — no stale "looted" state survives a restart (checklist #12)
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    GlobalState.lp_robbery_states = {}
    dbg('GlobalState cleared on resource start')
end)

-- Time sync for clients (os.time() doesn't work client-side)
RegisterServerEvent('lp_robbery:sv:requestTime')
AddEventHandler('lp_robbery:sv:requestTime', function()
    TriggerClientEvent('lp_robbery:cl:syncTime', source, os.time())
end)

-- ════════════════════════════════════════════════════════════════════════════
--  Rate limiting (checklist #3) — per-src per-action cooldown, cleared on drop
-- ════════════════════════════════════════════════════════════════════════════
local cooldowns = {}
local COOLDOWN_MS = {
    lootStore    = 800,
    requestBank  = 1000,
    confirmBank  = 500,
    lootBank     = 800,
}
local function checkCooldown(src, action)
    local t = GetGameTimer()
    cooldowns[src] = cooldowns[src] or {}
    local last = cooldowns[src][action] or 0
    if (t - last) < (COOLDOWN_MS[action] or 800) then return false end
    cooldowns[src][action] = t
    return true
end

-- ════════════════════════════════════════════════════════════════════════════
--  Pending requests (per-src, short-lived, ~30s) — the anti-exploit core.
--  Bank only now (store has no bomb-plant step) — nothing changes GlobalState for
--  a bank robbery unless it goes through requestBank FIRST (the only place the
--  bomb item is checked/consumed), and confirmBankBlow re-validates the record.
-- ════════════════════════════════════════════════════════════════════════════
local pending = {} -- [src] = { type='bank', id, subId, coords, plantAt, expires }

-- ════════════════════════════════════════════════════════════════════════════
--  STORE — single step: client already ran the lockpick minigame; this is the
--  one authoritative event (no more request→confirm bomb dance, no item, no
--  unlock-wait). Rolls the reward directly and marks the reloot cooldown.
-- ════════════════════════════════════════════════════════════════════════════
RegisterServerEvent('lp_robbery:sv:lootStore')
AddEventHandler('lp_robbery:sv:lootStore', function(storeId)
    local src = source
    if not checkCooldown(src, 'lootStore') then return end

    local function fail(reason)
        notify(src, reason, 'error')
        dbg('BLOCKED lootStore src=%s store=%s reason=%s', src, tostring(storeId), reason)
    end

    local store = type(storeId) == 'string' and Config.Stores[storeId]
    if not store then return fail('ไม่พบสถานที่นี้') end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return fail('เกิดข้อผิดพลาด') end
    if #(GetEntityCoords(ped) - store.coords) > Config.Range then return fail('คุณอยู่ไกลเกินไป') end

    local key = 'store_' .. storeId
    local st, rem = statusOf(key)
    if st == 'cooling' then return fail(('สถานที่นี้เพิ่งถูกปล้น งัดได้อีกใน %d นาที'):format(math.ceil(rem / 60))) end
    if st ~= 'fresh' then return fail('กำลังมีการปล้นที่นี่อยู่') end

    local char = getChar(src)
    if not char then return fail('เกิดข้อผิดพลาด') end

    if getPoliceCount() < Config.Police.RequiredForStore then
        return fail('ตำรวจในพื้นที่ไม่พอ')
    end

    -- ATOMIC: mark looted BEFORE giving rewards (race prevention — two players
    -- hitting this at the same instant must not both get paid).
    setState(key, { state = 'looted', relootAt = os.time() + (Config.RelootCooldown * 60) })

    local cash = math.random(Config.Rewards.Store.minCash, Config.Rewards.Store.maxCash)
    char.addCurrency(0, cash)

    local given = {}
    -- สุ่ม N ชิ้นไม่ซ้ำกันจาก pool (แทนระบบ items/chance แบบเดิม ที่แต่ละไอเทม roll โอกาสตัวเองแยกกัน)
    local rewardsCfgStore = Config.Rewards.Store
    if rewardsCfgStore.pool and #rewardsCfgStore.pool > 0 then
        local minC, maxC = 1, 1
        if rewardsCfgStore.poolCount then minC, maxC = rewardsCfgStore.poolCount[1], rewardsCfgStore.poolCount[2] end
        local pickCount = math.random(minC, maxC)

        local shuffled = {}
        for _, name in ipairs(rewardsCfgStore.pool) do shuffled[#shuffled + 1] = name end
        for i = #shuffled, 2, -1 do
            local j = math.random(i)
            shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
        end

        for i = 1, math.min(pickCount, #shuffled) do
            local name = shuffled[i]
            if exports.vorp_inventory:canCarryItem(src, name, 1) then
                exports.vorp_inventory:addItem(src, name, 1)
                given[#given + 1] = '1x ' .. name
            else
                notify(src, ('กระเป๋าเต็ม ไม่สามารถรับ %s ได้'):format(name), 'error')
            end
        end
    end

    local summary = #given > 0 and table.concat(given, ', ') or nil
    notify(src, summary and ('งัดตู้เซฟสำเร็จ! ได้เงิน $%d และ %s'):format(cash, summary)
        or ('งัดตู้เซฟสำเร็จ! ได้เงิน $%d'):format(cash), 'success')

    logTx(src, 'store-loot', ('store=%s cash=%d items=%s'):format(storeId, cash, summary or 'none'))
    policeAlert(store.label, store.coords) -- แจ้งตำรวจตอนงัดสำเร็จ (แทนตอนวางระเบิดเดิม เพราะไม่มีขั้นวางระเบิดแล้ว)
end)

-- ════════════════════════════════════════════════════════════════════════════
--  BANK — request → confirm (blow), with server-enforced fuse time
-- ════════════════════════════════════════════════════════════════════════════
RegisterServerEvent('lp_robbery:sv:requestBank')
AddEventHandler('lp_robbery:sv:requestBank', function(bankId, vaultId)
    local src = source
    if not checkCooldown(src, 'requestBank') then return end

    local function fail(reason)
        notify(src, reason, 'error')
        dbg('BLOCKED requestBank src=%s bank=%s vault=%s reason=%s', src, tostring(bankId), tostring(vaultId), reason)
        TriggerClientEvent('lp_robbery:cl:bankRequestResult', src, bankId, vaultId, false)
    end

    local bank = type(bankId) == 'string' and Config.Banks[bankId]
    local vault = bank and bank.vaults and bank.vaults[tonumber(vaultId)]
    if not vault then return fail('ไม่พบสถานที่นี้') end
    vaultId = tonumber(vaultId)

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return fail('เกิดข้อผิดพลาด') end
    if #(GetEntityCoords(ped) - vault.coords) > Config.Range then return fail('คุณอยู่ไกลเกินไป') end

    local key = bankId .. '_' .. vaultId
    local st, rem = statusOf(key)
    if st == 'cooling' then return fail(('ห้องนิรภัยนี้เพิ่งถูกปล้น งัดได้อีกใน %d นาที'):format(math.ceil(rem / 60))) end
    if st ~= 'fresh' then return fail('กำลังมีการปล้นที่นี่อยู่') end

    if not getChar(src) then return fail('เกิดข้อผิดพลาด') end

    if getPoliceCount() < Config.Police.RequiredForBank then
        return fail('ตำรวจในพื้นที่ไม่พอ')
    end

    local itemCount = exports.vorp_inventory:getItemCount(src, nil, Config.Item)
    if not itemCount or itemCount < 1 then
        return fail('คุณต้องมีระเบิดลูกเล็ก')
    end

    exports.vorp_inventory:subItem(src, Config.Item, 1)

    pending[src] = {
        type = 'bank', id = bankId, subId = vaultId, coords = vault.coords,
        plantAt = os.time(), expires = os.time() + Config.PendingTTL,
    }

    logTx(src, 'bank-request', ('bank=%s vault=%s'):format(bankId, vaultId))
    TriggerClientEvent('lp_robbery:cl:bankRequestResult', src, bankId, vaultId, true)
end)

RegisterServerEvent('lp_robbery:sv:confirmBankBlow')
AddEventHandler('lp_robbery:sv:confirmBankBlow', function(bankId, vaultId)
    local src = source
    if not checkCooldown(src, 'confirmBank') then return end
    vaultId = tonumber(vaultId)

    local p = pending[src]
    pending[src] = nil

    local bank = type(bankId) == 'string' and Config.Banks[bankId]
    local vault = bank and bank.vaults and bank.vaults[vaultId]
    if not vault then return end

    if not p or p.type ~= 'bank' or p.id ~= bankId or p.subId ~= vaultId or os.time() > p.expires then
        notify(src, 'คำขอหมดอายุ กรุณาลองใหม่', 'error')
        logSus(src, 'confirmBankBlow', ('invalid_pending bank=%s vault=%s'):format(tostring(bankId), tostring(vaultId))) -- ข้าม request
        return
    end

    -- Server-enforced fuse: blocks an instant-confirm cheat that skips the 15s wait
    if (os.time() - p.plantAt) < (Config.BankFuseTime - 1) then
        notify(src, 'ยังไม่ถึงเวลาระเบิด', 'error')
        logSus(src, 'confirmBankBlow', ('fuse_too_early bank=%s vault=%s elapsed=%d'):format(tostring(bankId), tostring(vaultId), os.time() - p.plantAt))
        return
    end

    local key = bankId .. '_' .. vaultId
    if statusOf(key) ~= 'fresh' then
        notify(src, 'ห้องนิรภัยนี้ถูกดำเนินการไปแล้ว', 'error')
        return
    end

    setState(key, { state = 'unlocking', unlockTime = os.time() + (Config.BankRobberyDuration * 60) })

    -- rare, one-off event: -1 broadcast is acceptable here so everyone nearby sees/hears it
    TriggerClientEvent('lp_robbery:cl:syncExplosion', -1, bankId, vaultId)

    logTx(src, 'bank-confirm', ('bank=%s vault=%s unlock_in=%dm'):format(bankId, vaultId, Config.BankRobberyDuration))
    policeAlert(bank.label, vault.coords)
end)

-- ════════════════════════════════════════════════════════════════════════════
--  LOOT — bank vault only now (store loot merged into sv:lootStore above).
--  Requires state == open ('unlocking' + unlockTime passed).
-- ════════════════════════════════════════════════════════════════════════════
RegisterServerEvent('lp_robbery:sv:lootBank')
AddEventHandler('lp_robbery:sv:lootBank', function(bankId, vaultId)
    local src = source
    if not checkCooldown(src, 'lootBank') then return end

    local function fail(reason)
        notify(src, reason, 'error')
        dbg('BLOCKED lootBank src=%s bank=%s sub=%s reason=%s', src, tostring(bankId), tostring(vaultId), reason)
    end

    vaultId = tonumber(vaultId)
    local bank = type(bankId) == 'string' and Config.Banks[bankId]
    local vault = bank and bank.vaults and bank.vaults[vaultId]
    if not vault then return fail('ไม่พบสถานที่นี้') end
    local coords, key, rewardsCfg = vault.coords, bankId .. '_' .. vaultId, Config.Rewards.BankVault

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return fail('เกิดข้อผิดพลาด') end
    if #(GetEntityCoords(ped) - coords) > Config.Range then return fail('คุณอยู่ไกลเกินไป') end

    local st, rem = statusOf(key)
    if st == 'cooling' then return fail('มีคนเก็บของไปแล้ว') end
    if st == 'active' then return fail(('รออีก %d นาที'):format(math.ceil(rem / 60))) end
    if st ~= 'open' then return fail('ไม่มีอะไรให้เก็บที่นี่') end

    -- ATOMIC: mark looted BEFORE giving rewards (race prevention — two players
    -- hitting loot at the same instant must not both get paid). relootAt ให้จุดนี้
    -- กลับมางัดได้เองหลัง Config.RelootCooldown นาที (statusOf ตีความเป็น fresh เมื่อหมดเวลา)
    setState(key, { state = 'looted', relootAt = os.time() + (Config.RelootCooldown * 60) })

    local char = getChar(src)
    if not char then
        logTx(src, 'payout-lost', ('key=%s reason=char_gone_after_mark'):format(key))
        return
    end

    local cash = math.random(rewardsCfg.minCash, rewardsCfg.maxCash)
    char.addCurrency(0, cash)

    local given = {}
    for _, item in ipairs(rewardsCfg.items or {}) do
        local roll = math.random(1, 100)
        if roll <= item.chance then
            local amount
            if type(item.amount) == 'table' then
                amount = math.random(item.amount[1], item.amount[2])
            else
                amount = item.amount
            end

            if exports.vorp_inventory:canCarryItem(src, item.name, amount) then
                exports.vorp_inventory:addItem(src, item.name, amount)
                given[#given + 1] = amount .. 'x ' .. item.name
            else
                notify(src, ('กระเป๋าเต็ม ไม่สามารถรับ %s ได้'):format(item.name), 'error')
            end
        end
    end

    local summary = #given > 0 and table.concat(given, ', ') or nil
    if summary then
        notify(src, ('ได้รับเงิน $%d และ %s'):format(cash, summary), 'success')
    else
        notify(src, ('ได้รับเงิน $%d'):format(cash), 'success')
    end

    logTx(src, 'payout', ('key=%s cash=%d items=%s'):format(key, cash, summary or 'none'))
end)

-- ════════════════════════════════════════════════════════════════════════════
--  Cleanup (checklist #3/#12)
-- ════════════════════════════════════════════════════════════════════════════
AddEventHandler('playerDropped', function()
    local src = source
    cooldowns[src] = nil
    pending[src] = nil
end)
