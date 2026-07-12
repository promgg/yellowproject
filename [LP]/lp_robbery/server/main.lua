-- lp_robbery / server/main.lua
-- Server is the SINGLE authority for every state transition. Client can only *request*
-- (requestStore/requestBank) and *confirm* (confirmStore/confirmBankBlow/loot) — every
-- one of those events re-validates source/item/coords/job/state here. This closes the
-- devchacha-robbery exploit where the item was only checked in a separate `canRob`
-- callback that a cheat client could skip entirely by firing the state-transition event
-- directly (free robbery, no item spent, no distance/police check).

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
    requestStore = 1000,
    confirmStore = 500,
    requestBank  = 1000,
    confirmBank  = 500,
    loot         = 800,
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
--  Nothing changes GlobalState (i.e. nothing "starts" a robbery) unless it goes
--  through requestStore/requestBank FIRST (which is the only place the item is
--  checked/consumed), and the matching confirm* re-validates the pending record.
-- ════════════════════════════════════════════════════════════════════════════
local pending = {} -- [src] = { type='store'|'bank', id, subId, coords, plantAt, expires }

-- ════════════════════════════════════════════════════════════════════════════
--  STORE — request → confirm
-- ════════════════════════════════════════════════════════════════════════════
RegisterServerEvent('lp_robbery:sv:requestStore')
AddEventHandler('lp_robbery:sv:requestStore', function(storeId)
    local src = source
    if not checkCooldown(src, 'requestStore') then return end

    local function fail(reason)
        notify(src, reason, 'error')
        dbg('BLOCKED requestStore src=%s store=%s reason=%s', src, tostring(storeId), reason)
        TriggerClientEvent('lp_robbery:cl:storeRequestResult', src, storeId, false)
    end

    local store = type(storeId) == 'string' and Config.Stores[storeId]
    if not store then return fail('ไม่พบสถานที่นี้') end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return fail('เกิดข้อผิดพลาด') end
    if #(GetEntityCoords(ped) - store.coords) > Config.Range then return fail('คุณอยู่ไกลเกินไป') end

    local st, rem = statusOf('store_' .. storeId)
    if st == 'cooling' then return fail(('สถานที่นี้เพิ่งถูกปล้น งัดได้อีกใน %d นาที'):format(math.ceil(rem / 60))) end
    if st ~= 'fresh' then return fail('กำลังมีการปล้นที่นี่อยู่') end

    if not getChar(src) then return fail('เกิดข้อผิดพลาด') end

    if getPoliceCount() < Config.Police.RequiredForStore then
        return fail('ตำรวจในพื้นที่ไม่พอ')
    end

    local itemCount = exports.vorp_inventory:getItemCount(src, nil, Config.Item)
    if not itemCount or itemCount < 1 then
        return fail('คุณต้องมีระเบิดลูกเล็ก')
    end

    -- Consumed here regardless of the later skill-check result (by design)
    exports.vorp_inventory:subItem(src, Config.Item, 1)

    pending[src] = {
        type = 'store', id = storeId, coords = store.coords,
        expires = os.time() + Config.PendingTTL,
    }

    logTx(src, 'store-request', ('store=%s'):format(storeId))
    TriggerClientEvent('lp_robbery:cl:storeRequestResult', src, storeId, true)
end)

RegisterServerEvent('lp_robbery:sv:confirmStore')
AddEventHandler('lp_robbery:sv:confirmStore', function(storeId)
    local src = source
    if not checkCooldown(src, 'confirmStore') then return end

    -- One-shot: consumed whether this validates or not, blocking any replay
    local p = pending[src]
    pending[src] = nil

    local store = type(storeId) == 'string' and Config.Stores[storeId]
    if not store then return end

    if not p or p.type ~= 'store' or p.id ~= storeId or os.time() > p.expires then
        notify(src, 'คำขอหมดอายุ กรุณาลองใหม่', 'error')
        logSus(src, 'confirmStore', ('invalid_pending store=%s'):format(tostring(storeId))) -- ยิง confirm โดยข้าม request
        return
    end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end
    if #(GetEntityCoords(ped) - store.coords) > Config.Range then
        notify(src, 'คุณอยู่ไกลเกินไป', 'error')
        dbg('BLOCKED confirmStore src=%s store=%s reason=out_of_range', src, tostring(storeId))
        return
    end

    local key = 'store_' .. storeId
    if statusOf(key) ~= 'fresh' then
        notify(src, 'สถานที่นี้ถูกดำเนินการไปแล้ว', 'error')
        return
    end

    setState(key, { state = 'unlocking', unlockTime = os.time() + (Config.RobberyDuration * 60) })

    notify(src, ('วางระเบิดสำเร็จ ตู้เซฟจะเปิดใน %d นาที'):format(Config.RobberyDuration), 'success')
    logTx(src, 'store-confirm', ('store=%s unlock_in=%dm'):format(storeId, Config.RobberyDuration))
    policeAlert(store.label, store.coords)
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
--  LOOT — both types, requires state == open ('unlocking' + unlockTime passed)
-- ════════════════════════════════════════════════════════════════════════════
RegisterServerEvent('lp_robbery:sv:loot')
AddEventHandler('lp_robbery:sv:loot', function(kind, id, subId)
    local src = source
    if not checkCooldown(src, 'loot') then return end

    local function fail(reason)
        notify(src, reason, 'error')
        dbg('BLOCKED loot src=%s kind=%s id=%s sub=%s reason=%s', src, tostring(kind), tostring(id), tostring(subId), reason)
    end

    local coords, key, rewardsCfg
    if kind == 'bank' then
        subId = tonumber(subId)
        local bank = type(id) == 'string' and Config.Banks[id]
        local vault = bank and bank.vaults and bank.vaults[subId]
        if not vault then return fail('ไม่พบสถานที่นี้') end
        coords, key, rewardsCfg = vault.coords, id .. '_' .. subId, Config.Rewards.BankVault
    elseif kind == 'store' then
        local store = type(id) == 'string' and Config.Stores[id]
        if not store then return fail('ไม่พบสถานที่นี้') end
        coords, key, rewardsCfg = store.coords, 'store_' .. id, Config.Rewards.Store
    else
        logSus(src, 'loot', ('bad_kind kind=%s'):format(tostring(kind))) -- client ปกติส่งแค่ store/bank
        return fail('ประเภทไม่ถูกต้อง')
    end

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
        logTx(src, 'payout-lost', ('kind=%s key=%s reason=char_gone_after_mark'):format(kind, key))
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

    logTx(src, 'payout', ('kind=%s key=%s cash=%d items=%s'):format(kind, key, cash, summary or 'none'))
end)

-- ════════════════════════════════════════════════════════════════════════════
--  Cleanup (checklist #3/#12)
-- ════════════════════════════════════════════════════════════════════════════
AddEventHandler('playerDropped', function()
    local src = source
    cooldowns[src] = nil
    pending[src] = nil
end)
