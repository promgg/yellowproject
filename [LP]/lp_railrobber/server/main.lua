-- lp_railrobber / server/main.lua  (STAGE 1 — PvE spine)
-- SINGLE authority for the whole heist. Clients only REQUEST (buy intel, "I
-- entered the ambush zone", "train spawned", "wave cleared") — the server owns
-- every transition, the cooldown, and the single-heist gate. Shared read-only
-- state is mirrored into GlobalState.lp_railrobber for all clients / late joiners.

local Core = exports.vorp_core:GetCore()
local S = Config.States

-- ── the one and only heist (nil when idle) ──────────────────────────────────
local heist = nil
--[[ heist = {
        buyerSrc, buyerCharId, buyerCity,
        ambush = <Config.AmbushPoints entry>,
        state, trainNet, ownerSrc,
        waveIndex, reservedAt,
} ]]
local lastHeistEndedAt = 0 -- os.time() of last COMPLETE/FAILED — feeds the cooldown
local cooldowns = {}       -- [src] = { [event] = nextAllowedMs }

-- ── helpers ─────────────────────────────────────────────────────────────────
local function dbg(msg) if Config.Debug then print(('[lp_railrobber] %s'):format(msg)) end end
local function notify(src, text, kind, timeout) TriggerClientEvent('lp_railrobber:cl:notify', src, text, kind, timeout) end
local function logTx(msg) print(('[lp_railrobber][TX] %s'):format(msg)) end
local function logSus(src, ev, why) print(('[lp_railrobber][SUSPECT] src=%s event=%s reason=%s'):format(tostring(src), ev, why)) end

local function getChar(src)
    local user = Core.getUser(src)
    if not user then return nil end
    return user.getUsedCharacter
end

local function getCityId(src)
    local ok, cityId = pcall(function() return exports.nx_cityselect:GetPlayerCityId(src) end)
    if ok then return cityId end
    return nil
end

local function ratelimited(src, event, ms)
    cooldowns[src] = cooldowns[src] or {}
    local now = GetGameTimer()
    if cooldowns[src][event] and now < cooldowns[src][event] then return true end
    cooldowns[src][event] = now + ms
    return false
end

local function distance(a, b)
    return #(vector3(a.x, a.y, a.z) - vector3(b.x, b.y, b.z))
end

local function playerCoords(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    return GetEntityCoords(ped)
end

-- LIVE train position, resolved server-side (server can read networked-entity
-- coords directly under OneSync). This replaces relying only on the owner
-- client's one-time trainStopped report, which goes stale/wrong: the train
-- keeps moving through the whole PvE phase, so a fallback to the ambush point
-- can be hundreds of metres from where the train actually stopped — making the
-- hold radius match ZERO players and silently hand out zero rewards.
local function liveTrainCoords()
    if not heist or not heist.trainNet then return nil end
    -- NetworkDoesNetworkIdExist is CLIENT-ONLY (it doesn't exist server-side and
    -- threw a script error every call, which aborted breachCar mid-handler —
    -- that's why holding E never advanced the phase). NetworkGetEntityFromNetworkId
    -- + DoesEntityExist alone is safe server-side (returns 0/false on a bad id).
    local ent = NetworkGetEntityFromNetworkId(heist.trainNet)
    if not ent or ent == 0 or not DoesEntityExist(ent) then return nil end
    return GetEntityCoords(ent)
end

-- pick a random carriage for THIS wave, distinct from carriages already used
-- this heist (so waves don't stack on the same car — players explore the train)
local function pickWaveCarriage(h)
    local lo, hi = Config.LootCarriageRange[1], Config.LootCarriageRange[2]
    local used = {}
    for _, c in pairs(h.waveCarriages or {}) do used[c] = true end
    local pick, tries = nil, 0
    repeat
        pick = math.random(lo, hi)
        tries = tries + 1
    until not used[pick] or tries > 20
    return pick
end

local Inventory = exports.vorp_inventory

local function rollReward()
    local items = {}
    for _, it in ipairs(Config.Reward.items) do
        if math.random(1, 100) <= it.chance then
            local amt = type(it.amount) == 'table' and math.random(it.amount[1], it.amount[2]) or it.amount
            items[#items + 1] = { name = it.name, amount = amt }
        end
    end
    return items
end

local function giveReward(src)
    local char = getChar(src)
    if not char then return end
    local cash = math.random(Config.Reward.cashMin, Config.Reward.cashMax)
    pcall(function() char.addCurrency(Config.Reward.currency, cash) end)
    local items = rollReward()
    for _, it in ipairs(items) do
        -- 3-arg form, NO metadata table (passing {} makes vorp treat it as a
        -- unique-metadata item and it silently fails to add) — matches lp_robbery
        if exports.vorp_inventory:canCarryItem(src, it.name, it.amount) then
            exports.vorp_inventory:addItem(src, it.name, it.amount)
        end
    end
    logTx(('reward src=%s cash=%d items=%d'):format(src, cash, #items))
    notify(src, ('คุณงัดตู้สำเร็จ! ได้ $%d + ของปล้น'):format(cash), 'success', 6000)
end

-- mirror the shareable slice of state to every client (bounded single object)
local function syncState()
    if not heist then
        GlobalState.lp_railrobber = { state = S.IDLE }
        return
    end
    GlobalState.lp_railrobber = {
        state       = heist.state,
        ambushId    = heist.ambush and heist.ambush.id or nil,
        trainNet    = heist.trainNet,
        buyerCity   = heist.buyerCity,
        breachTotal   = heist.lootTotal,   -- STAGE 2: number of loot cars
        breachDone    = heist.breachDone,  -- how many breached
        breached      = heist.breached,    -- { [carIndex] = true } — which are done
        holdRemaining = heist.holdRemaining, -- countdown (sec) after breach before the breacher gets paid
    }
end

local function endHeist(reason, newState)
    if not heist then return end
    logTx(('heist ended state=%s reason=%s'):format(newState, tostring(reason)))
    -- broadcast teardown: the owner deletes the train + guards, everyone else just
    -- clears their observer blip / hold HUD (their myTrain is 0, so it's a no-op there)
    TriggerClientEvent('lp_railrobber:cl:teardown', -1)
    heist = nil
    lastHeistEndedAt = os.time()
    syncState()
end

local function cooldownRemaining()
    local rem = (lastHeistEndedAt + Config.IntelCooldownMinutes * 60) - os.time()
    return rem > 0 and rem or 0
end

-- ── STAGE 2 (scope cut): reward the breacher only, after a short countdown ──
-- No city-vs-city KotH / roster / cap for now — client wants requirements
-- clarified first. Whoever actually breached the loot car gets paid once the
-- countdown ends.
local function resolveHold()
    if not heist then return end
    local src = heist.breacherSrc
    if src then
        giveReward(src)
        logTx(('HOLD complete — reward given to breacher src=%s'):format(src))
    else
        logTx('HOLD complete — no breacher recorded, no reward')
    end
    TriggerClientEvent('lp_railrobber:cl:notify', -1, 'กิจกรรมปล้นรถไฟจบแล้ว!', 'alert', 6000)
    endHeist('breacher_rewarded', S.COMPLETE)
end

local function startHold()
    if not heist then return end
    heist.state = S.HOLD
    heist.holdStartedAt = os.time()
    heist.holdRemaining = Config.Hold.durationSec
    syncState()
    logTx(('HOLD started — breacher src=%s gets paid in %ds'):format(tostring(heist.breacherSrc), Config.Hold.durationSec))
    TriggerClientEvent('lp_railrobber:cl:notify', -1, 'งัดตู้สำเร็จ! รอสักครู่เพื่อรับรางวัล...', 'alert', 6000)

    CreateThread(function()
        while heist and heist.state == S.HOLD do
            Wait(Config.Hold.tickSec * 1000)
            if not heist or heist.state ~= S.HOLD then return end
            heist.holdRemaining = math.max(0, Config.Hold.durationSec - (os.time() - heist.holdStartedAt))
            syncState()
            if heist.holdRemaining <= 0 then resolveHold(); return end
        end
    end)
end

-- ── buy intel — starts the heist, tells the buyer's WHOLE CITY the ambush ────
RegisterNetEvent('lp_railrobber:sv:buyIntel', function()
    local src = source
    if ratelimited(src, 'buyIntel', 1000) then return end

    if heist then
        notify(src, 'มีขบวนที่กำลังถูกปล้นอยู่แล้ว', 'error'); return
    end
    local rem = cooldownRemaining()
    if rem > 0 then
        notify(src, ('รอข่าวขบวนถัดไปอีก %d นาที'):format(math.ceil(rem / 60)), 'error'); return
    end

    local char = getChar(src)
    if not char then return end

    local pc = playerCoords(src)
    if not pc or distance(pc, Config.IntelNPC.coords) > (Config.InteractRange + 2.0) then
        logSus(src, 'buyIntel', 'out_of_range'); return
    end

    local cityId = getCityId(src)
    if not cityId then
        notify(src, 'ต้องสังกัดเมืองก่อนถึงจะซื้อข่าวได้', 'error'); return
    end

    -- price (server-side money check + deduct)
    local price = Config.IntelNPC.price
    if (char.money or 0) < price.amount then
        notify(src, 'เงินสดไม่พอ', 'error'); return
    end
    local paid = pcall(function() char.removeCurrency(price.currency, price.amount) end)
    if not paid then logSus(src, 'buyIntel', 'removeCurrency_failed'); return end

    local ambush = Config.AmbushPoints[math.random(#Config.AmbushPoints)]
    heist = {
        buyerSrc = src, buyerCharId = tostring(char.charIdentifier), buyerCity = cityId,
        ambush = ambush, state = S.RESERVED, trainNet = nil, ownerSrc = nil,
        waveIndex = 0, reservedAt = os.time(),
    }
    syncState()
    logTx(('intel bought by src=%s city=%s -> ambush=%s (paid %d)'):format(src, cityId, ambush.id, price.amount))

    -- reveal the ambush point to the buyer's WHOLE city
    for _, pid in ipairs(GetPlayers()) do
        local pidn = tonumber(pid)
        if getCityId(pidn) == cityId then
            TriggerClientEvent('lp_railrobber:cl:intelReceived', pidn, {
                ambush = { coords = ambush.coords, heading = ambush.heading, id = ambush.id },
                isBuyer = (pidn == src),
            })
        end
    end
end)

-- ── buyer reached the ambush zone -> spawn the approaching train ─────────────
RegisterNetEvent('lp_railrobber:sv:reachedAmbush', function()
    local src = source
    if ratelimited(src, 'reachedAmbush', 1000) then return end
    if not heist or heist.state ~= S.RESERVED then return end
    if src ~= heist.buyerSrc then logSus(src, 'reachedAmbush', 'not_buyer'); return end

    local pc = playerCoords(src)
    if not pc or distance(pc, heist.ambush.coords) > Config.AmbushRadius then
        logSus(src, 'reachedAmbush', 'not_in_zone'); return
    end

    heist.state = S.TRAIN_EN_ROUTE
    heist.ownerSrc = src -- the buyer's client owns/spawns the mission train (CreateMissionTrain is client-side)
    syncState()
    logTx(('buyer src=%s reached ambush %s -> spawning train'):format(src, heist.ambush.id))

    local spawn = heist.ambush.coords + heist.ambush.spawnOffset
    TriggerClientEvent('lp_railrobber:cl:spawnTrain', src, {
        hash = Config.TrainHash,
        spawn = { x = spawn.x, y = spawn.y, z = spawn.z },
        heading = heist.ambush.heading,
        cruise = Config.CruiseSpeed,
    })
end)

-- ── owner reports the train net id -> broadcast + start PvE wave 1 ───────────
RegisterNetEvent('lp_railrobber:sv:trainSpawned', function(trainNet)
    local src = source
    if not heist or heist.state ~= S.TRAIN_EN_ROUTE or src ~= heist.ownerSrc then return end
    if type(trainNet) ~= 'number' then return end

    heist.trainNet = trainNet
    heist.state = S.PVE
    heist.trainSpawnedAt = os.time() -- clock starts here for the hard 20-min clear ceiling
    heist.waveIndex = 1
    -- EACH wave gets its own random carriage (no repeats) — players search the
    -- whole train instead of every wave piling onto one fixed car.
    heist.waveCarriages = {}
    heist.waveCarriages[1] = pickWaveCarriage(heist)
    syncState()
    logTx(('train spawned net=%d, wave 1 car=%d -> PVE'):format(trainNet, heist.waveCarriages[1]))

    -- everyone resolves the train (like bcc-train); owner spawns the guard wave
    TriggerClientEvent('lp_railrobber:cl:trainSync', -1, trainNet)
    TriggerClientEvent('lp_railrobber:cl:spawnWave', heist.ownerSrc, {
        carriage = heist.waveCarriages[1],
        count = Config.Waves[1].count,
        model = Config.GuardModel,
        weapon = Config.GuardWeapon,
        wave = 1,
    })
end)

-- ── owner reports the current wave is cleared -> next wave or PvE done ───────
-- NOTE (Stage 2): guard death is currently owner-reported (client-trusted). Stage 2
-- must track guard netIds server-side and verify deaths before advancing.
RegisterNetEvent('lp_railrobber:sv:waveCleared', function(wave)
    local src = source
    if ratelimited(src, 'waveCleared', 500) then return end
    if not heist or heist.state ~= S.PVE or src ~= heist.ownerSrc then return end
    if wave ~= heist.waveIndex then logSus(src, 'waveCleared', 'wave_mismatch'); return end

    if heist.waveIndex >= #Config.Waves then
        heist.state = S.BREACHING
        heist.breached = {}                 -- [carIndex] = true
        heist.breachDone = 0
        heist.lootTotal = 1
        heist.lootCarriage = heist.waveCarriages[heist.waveIndex] -- last wave's car = the vault
        syncState()
        logTx(('all guard waves cleared -> BREACHING, loot car=%d'):format(heist.lootCarriage))
        TriggerClientEvent('lp_railrobber:cl:stopTrain', heist.ownerSrc)      -- owner brakes + reports coords
        TriggerClientEvent('lp_railrobber:cl:beginBreach', -1, { heist.lootCarriage }) -- everyone can now breach
        return
    end

    heist.waveIndex = heist.waveIndex + 1
    heist.waveCarriages[heist.waveIndex] = pickWaveCarriage(heist)
    logTx(('wave cleared -> spawning wave %d, car=%d'):format(heist.waveIndex, heist.waveCarriages[heist.waveIndex]))
    TriggerClientEvent('lp_railrobber:cl:spawnWave', heist.ownerSrc, {
        carriage = heist.waveCarriages[heist.waveIndex],
        count = Config.Waves[heist.waveIndex].count,
        model = Config.GuardModel,
        weapon = Config.GuardWeapon,
        wave = heist.waveIndex,
    })
end)

-- ── owner reports where the train stopped -> hold centre ────────────────────
RegisterNetEvent('lp_railrobber:sv:trainStopped', function(coords)
    local src = source
    if not heist or src ~= heist.ownerSrc then return end
    if type(coords) ~= 'table' and type(coords) ~= 'vector3' then return end
    heist.holdCenter = vector3(coords.x, coords.y, coords.z)
    dbg('hold centre recorded from owner')
end)

-- ── breach a loot car (STAGE 2) ─────────────────────────────────────────────
RegisterNetEvent('lp_railrobber:sv:breachCar', function(carIndex)
    local src = source
    if ratelimited(src, 'breachCar', 500) then return end
    if not heist or heist.state ~= Config.States.BREACHING then return end
    if type(carIndex) ~= 'number' then return end

    if carIndex ~= heist.lootCarriage then logSus(src, 'breachCar', 'not_loot_car'); return end
    if heist.breached[carIndex] then return end

    -- server-side sanity: must be near the (long) train's LIVE position; client
    -- already gated the precise per-car distance, so this is a coarse anti-cheat
    -- only. Use the live position, not the stale/one-shot holdCenter report.
    local center = liveTrainCoords()
    if center then
        local pc = playerCoords(src)
        if not pc or #(pc - center) > Config.BreachServerRadius then
            logSus(src, 'breachCar', 'too_far'); return
        end
    end

    heist.breached[carIndex] = true
    heist.breachDone = heist.breachDone + 1
    heist.breacherSrc = src -- whoever actually breached the car gets the reward
    syncState()
    logTx(('loot car %d breached by src=%s (%d/%d)'):format(carIndex, src, heist.breachDone, heist.lootTotal))
    notify(src, ('งัดตู้สำเร็จ (%d/%d)'):format(heist.breachDone, heist.lootTotal), 'success', 4000)

    if heist.breachDone >= heist.lootTotal then
        startHold()
    end
end)

-- ── admin / abort ───────────────────────────────────────────────────────────
RegisterCommand('railrobber_abort', function(src)
    if src ~= 0 and not IsPlayerAceAllowed(src, 'lp_railrobber.admin') then return end
    endHeist('admin_abort', S.CLEANUP)
    print('[lp_railrobber] heist aborted by admin')
end, false)

-- ── lifecycle ───────────────────────────────────────────────────────────────
AddEventHandler('playerDropped', function()
    local src = source
    cooldowns[src] = nil
    if heist and heist.buyerSrc == src and (heist.state == S.RESERVED or heist.state == S.TRAIN_EN_ROUTE) then
        logTx('buyer dropped before PvE -> fail heist')
        endHeist('buyer_dropped', S.FAILED)
    end
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    heist = nil
    syncState()
    dbg('GlobalState reset on resource start')
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if heist and heist.ownerSrc then
        TriggerClientEvent('lp_railrobber:cl:teardown', heist.ownerSrc)
    end
end)

-- watchdog: auto-fail a reservation the buyer never fulfils, AND enforce a hard
-- ceiling once the train has spawned. The second check replaces per-player
-- death/disconnect tracking entirely — covers a dead/AFK/disconnected owner (the
-- revive system means "dead" isn't permanent, so this clock is the actual
-- backstop) without ever needing a state-specific handler for it.
CreateThread(function()
    while true do
        Wait(15000)
        if heist and heist.state == S.RESERVED then
            if os.time() - heist.reservedAt > Config.EnRouteTimeoutSec then
                logTx('reservation timed out (buyer never reached ambush) -> fail')
                endHeist('reservation_timeout', S.FAILED)
            end
        elseif heist and heist.trainSpawnedAt
            and (heist.state == S.PVE or heist.state == S.BREACHING or heist.state == S.HOLD) then
            if os.time() - heist.trainSpawnedAt > Config.TrainClearTimeoutMin * 60 then
                logTx(('train clear ceiling (%d min) hit -> fail, cooldown starts'):format(Config.TrainClearTimeoutMin))
                TriggerClientEvent('lp_railrobber:cl:notify', -1, 'หมดเวลาปล้นรถไฟ! กิจกรรมถูกยกเลิก', 'error', 6000)
                endHeist('clear_timeout', S.FAILED)
            end
        end
    end
end)
