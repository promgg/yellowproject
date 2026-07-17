-- lp_railrobber / server/main.lua
-- SINGLE authority for the whole heist. The intel buyer owns mission entity
-- spawning, while every nearby player may plant the bomb and loot a free car.
-- (no party/group system exists anywhere in this codebase — confirmed via a
-- dedicated research pass on vorp_core + nx_cityselect). Clients only REQUEST
-- (buy intel, "I entered the ambush zone", "ambush cleared", "carriage cleared",
-- "plant the bomb", "confirm the blow", "I picked car N") — the server owns
-- every transition, the cooldown, the single-heist gate, and every reward.
-- Kill-credit for NPC batches is NOT gated (any nearby player can help fight),
-- but only the buyer's client is trusted to REPORT a batch cleared — same trust
-- model the old wave system already used. Reward-granting events (plant confirm,
-- plant/loot rewards are distance, state, item, token, and per-target lock gated.
-- Shared read-only state is mirrored into GlobalState.lp_railrobber for all
-- clients / late joiners.

local Core = exports.vorp_core:GetCore()
local S = Config.States

-- ── the one and only heist (nil when idle) ──────────────────────────────────
local heist = nil
--[[ heist = {
        buyerSrc, buyerCharId,
        ambush = <Config.AmbushPoints entry>,
        state, trainNet, ownerSrc,
        reservedAt, trainSpawnedAt,
        carriageAssignments,       -- array of carriage indices, one per carriage NPC
        breached = { [carIndex] = true }, carLocks = { [carIndex] = src }, breachDone, perimeterSpawned,
        plantingSrc,
} ]]
local lastHeistEndedAt = 0 -- os.time() of last COMPLETE/FAILED — feeds the cooldown
local cooldowns = {}       -- [src] = { [event] = nextAllowedMs }
local pending = {}         -- [src] = { plantAt, expires } — bomb-plant anti-replay token
local lockpickPending = {} -- [src] = { carIndex, expires } — car-lockpick reward anti-replay token
-- (declared here, not next to sv:lockpickAttempt below, so endHeist() above that
-- handler can see it too — a Lua local declared later isn't visible to code above it)

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

-- ── notify only players who actually have a stake in this heist — the buyer
-- (always) plus anyone physically near `center` — instead of broadcasting to
-- -1 (every player on the server, including people with zero connection to
-- this heist). center may be nil (e.g. train not resolvable yet); in that case
-- only the buyer is notified.
local function notifyNearby(alwaysSrc, center, radius, text, kind, timeout)
    if alwaysSrc then notify(alwaysSrc, text, kind, timeout) end
    if not center then return end
    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        if src and src ~= alwaysSrc then
            local pc = playerCoords(src)
            if pc and #(pc - center) <= radius then
                notify(src, text, kind, timeout)
            end
        end
    end
end

-- LIVE train position, resolved server-side (server can read networked-entity
-- coords directly under OneSync). NetworkDoesNetworkIdExist is CLIENT-ONLY —
-- NetworkGetEntityFromNetworkId + DoesEntityExist alone is safe server-side.
local function liveTrainCoords()
    if not heist or not heist.trainNet then return nil end
    local ent = NetworkGetEntityFromNetworkId(heist.trainNet)
    if not ent or ent == 0 or not DoesEntityExist(ent) then return nil end
    return GetEntityCoords(ent)
end

-- assign `count` NPCs to random carriages in [lo,hi] — repeats allowed (this
-- is "scatter N peds across the train", not "N distinct wave cars" like before)
local function assignCarriagesForBatch(count, lo, hi)
    local out = {}
    for i = 1, count do
        out[i] = math.random(lo, hi)
    end
    return out
end

local Inventory = exports.vorp_inventory

-- ต่อตู้: 50% ของงานดำ 1-2 ชิ้นไม่ซ้ำกัน (สุ่มจาก pool) / 50% blueprint_low 1-2 ชิ้น — ไม่มีเงินสดแล้ว
local function rollCarReward()
    local cfg = Config.CarReward
    local items = {}

    if math.random(1, 100) <= (cfg.poolChancePercent or 50) then
        local count = math.random(cfg.poolCount[1], cfg.poolCount[2])
        local shuffled = {}
        for _, name in ipairs(cfg.pool) do shuffled[#shuffled + 1] = name end
        for i = #shuffled, 2, -1 do
            local j = math.random(i)
            shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
        end
        for i = 1, math.min(count, #shuffled) do
            items[#items + 1] = { name = shuffled[i], amount = 1 }
        end
    else
        local count = math.random(cfg.blueprintCount[1], cfg.blueprintCount[2])
        items[#items + 1] = { name = cfg.blueprintItem, amount = count }
    end

    return items
end

local function giveCarReward(src, carIndex)
    local char = getChar(src)
    if not char then return end
    local items = rollCarReward()
    local given = 0
    for _, it in ipairs(items) do
        -- pcall ต่อชิ้น — กันไม่ให้ไอเทมชิ้นหนึ่ง error แล้วทำให้ของที่เหลือในลูปไม่ถูกให้
        -- ไปด้วย (ยังไม่ atomic ระหว่างชิ้น แต่อย่างน้อย throw เดียวไม่ตัดของทั้งชุด/ข้าม
        -- logTx+notify ท้ายฟังก์ชันไปเฉยๆ) — 3-arg form, NO metadata table, matches lp_robbery
        local ok = pcall(function()
            if exports.vorp_inventory:canCarryItem(src, it.name, it.amount) then
                exports.vorp_inventory:addItem(src, it.name, it.amount)
                given = given + 1
            end
        end)
        if not ok then
            print(('[lp_railrobber][ERROR] giveCarReward addItem failed car=%d src=%s item=%s'):format(carIndex, src, it.name))
        end
    end
    logTx(('reward car=%d src=%s items=%d/%d'):format(carIndex, src, given, #items))
    notify(src, ('งัดตู้ %d สำเร็จ! ได้ของปล้น %d ชิ้น'):format(carIndex, given), 'success', 4000)
end

-- mirror the shareable slice of state to every client (bounded single object)
local function syncState()
    if not heist then
        GlobalState.lp_railrobber = { state = S.IDLE }
        return
    end
    GlobalState.lp_railrobber = {
        state         = heist.state,
        ambushId      = heist.ambush and heist.ambush.id or nil,
        trainNet      = heist.trainNet,
        buyerSrc      = heist.buyerSrc, -- mission train/entity owner; interaction is shared
        carsDone      = heist.breachDone,
        breached      = heist.breached,       -- { [carIndex] = true }
        plantingSrc   = heist.plantingSrc,
        perimeterSpawned = heist.perimeterSpawned,
    }
end

local function endHeist(reason, newState)
    if not heist then return end
    logTx(('heist ended state=%s reason=%s'):format(newState, tostring(reason)))
    -- broadcast teardown: the owner deletes the train + peds, everyone else just
    -- clears their observer blip / prompts (their myTrain is 0, so it's a no-op there)
    TriggerClientEvent('lp_railrobber:cl:teardown', -1)
    pending = {}
    lockpickPending = {}
    heist = nil
    lastHeistEndedAt = os.time()
    syncState()
end

local function cooldownRemaining()
    local rem = (lastHeistEndedAt + Config.IntelCooldownMinutes * 60) - os.time()
    return rem > 0 and rem or 0
end

-- ── buy intel — starts the heist, buyer-only blip ────────────────────────────
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

    -- price (server-side money check + deduct) — never refunded on any later timeout/failure
    local price = Config.IntelNPC.price
    if (char.money or 0) < price.amount then
        notify(src, 'เงินสดไม่พอ', 'error'); return
    end
    local paid = pcall(function() char.removeCurrency(price.currency, price.amount) end)
    if not paid then logSus(src, 'buyIntel', 'removeCurrency_failed'); return end

    local ambush = Config.AmbushPoints[math.random(#Config.AmbushPoints)]
    heist = {
        buyerSrc = src, buyerCharId = tostring(char.charIdentifier),
        ambush = ambush, state = S.RESERVED, trainNet = nil, ownerSrc = nil,
        reservedAt = os.time(),
    }
    syncState()
    logTx(('intel bought by src=%s -> ambush=%s (paid %d)'):format(src, ambush.id, price.amount))

    TriggerClientEvent('lp_railrobber:cl:intelReceived', src, {
        ambush = { coords = ambush.coords, heading = ambush.heading, id = ambush.id },
    })
end)

-- ── buyer reached the ambush zone -> spawn the ground ambush batch ───────────
RegisterNetEvent('lp_railrobber:sv:reachedAmbush', function()
    local src = source
    if ratelimited(src, 'reachedAmbush', 1000) then return end
    if not heist or heist.state ~= S.RESERVED then return end
    if src ~= heist.buyerSrc then logSus(src, 'reachedAmbush', 'not_buyer'); return end

    local pc = playerCoords(src)
    if not pc or distance(pc, heist.ambush.coords) > Config.AmbushRadius then
        logSus(src, 'reachedAmbush', 'not_in_zone'); return
    end

    heist.state = S.AMBUSH
    syncState()
    logTx(('buyer src=%s reached ambush %s -> ground combat'):format(src, heist.ambush.id))

    TriggerClientEvent('lp_railrobber:cl:spawnAmbush', src, {
        coords = heist.ambush.coords, heading = heist.ambush.heading,
        count = Config.AmbushGuardCount, model = Config.GuardModel, weapon = Config.GuardWeapon,
    })
end)

-- ── ambush cleared (kill-agnostic; only buyer's client reports it) -> spawn train ──
RegisterNetEvent('lp_railrobber:sv:ambushCleared', function()
    local src = source
    if ratelimited(src, 'ambushCleared', 500) then return end
    if not heist or heist.state ~= S.AMBUSH then return end
    if src ~= heist.buyerSrc then logSus(src, 'ambushCleared', 'not_buyer'); return end

    heist.state = S.TRAIN_EN_ROUTE
    heist.ownerSrc = src -- the buyer's client owns/spawns the mission train (CreateMissionTrain is client-side)
    syncState()
    logTx(('ambush cleared -> spawning train for src=%s'):format(src))

    local spawn = heist.ambush.coords + heist.ambush.spawnOffset
    TriggerClientEvent('lp_railrobber:cl:spawnTrain', src, {
        hash = Config.TrainHash,
        spawn = { x = spawn.x, y = spawn.y, z = spawn.z },
        heading = heist.ambush.heading,
        cruise = Config.CruiseSpeed,
    })
end)

-- ── owner reports the train net id -> broadcast + spawn the carriage batch ───
RegisterNetEvent('lp_railrobber:sv:trainSpawned', function(trainNet)
    local src = source
    if ratelimited(src, 'trainSpawned', 1000) then return end
    if not heist or heist.state ~= S.TRAIN_EN_ROUTE or src ~= heist.ownerSrc then return end
    if type(trainNet) ~= 'number' then return end

    heist.trainNet = trainNet
    heist.state = S.PVE
    heist.trainSpawnedAt = os.time() -- clock starts here for the 30-min PVE+PLANT+LOOTING ceiling
    heist.carriageAssignments = assignCarriagesForBatch(Config.TrainNpcCount, Config.LootCarriageRange[1], Config.LootCarriageRange[2])
    syncState()
    logTx(('train spawned net=%d, %d NPCs scattered -> PVE'):format(trainNet, Config.TrainNpcCount))

    -- everyone resolves the train (like bcc-train); owner spawns the carriage batch
    TriggerClientEvent('lp_railrobber:cl:trainSync', -1, trainNet)
    TriggerClientEvent('lp_railrobber:cl:spawnCarriageBatch', heist.ownerSrc, {
        assignments = heist.carriageAssignments,
        model = Config.GuardModel, weapon = Config.GuardWeapon,
    })
end)

-- ── carriage batch cleared (kill-agnostic; buyer reports it) -> allow plant ──
RegisterNetEvent('lp_railrobber:sv:carriageCleared', function()
    local src = source
    if ratelimited(src, 'carriageCleared', 500) then return end
    if not heist then dbg(('carriageCleared REJECTED src=%s reason=no_heist'):format(src)); return end
    if heist.state ~= S.PVE then
        dbg(('carriageCleared REJECTED src=%s reason=wrong_state state=%s'):format(src, tostring(heist.state))); return
    end
    if src ~= heist.ownerSrc then
        dbg(('carriageCleared REJECTED src=%s reason=not_owner ownerSrc=%s'):format(src, tostring(heist.ownerSrc))); return
    end

    heist.state = S.PLANT
    syncState()
    logTx('carriage batch cleared -> PLANT')
    -- แจ้งเฉพาะ buyer + คนที่อยู่ใกล้รถไฟจริง ๆ (อาจช่วยรบอยู่) ไม่ broadcast ทั้งเซิร์ฟ
    notifyNearby(heist.buyerSrc, liveTrainCoords(), Config.NotifyRadius, 'เคลียร์ยามครบแล้ว! วางระเบิดที่หัวรถจักร', 'success', 6000)
end)

-- ── bomb plant at the locomotive — ported from lp_robbery's requestBank/confirmBankBlow ──
RegisterNetEvent('lp_railrobber:sv:requestPlant', function()
    local src = source
    if ratelimited(src, 'requestPlant', 1000) then return end
    if not heist or heist.state ~= S.PLANT then
        dbg(('requestPlant REJECTED src=%s reason=wrong_state state=%s'):format(src, heist and tostring(heist.state) or 'no_heist'))
        notify(src, 'ยังวางระเบิดไม่ได้', 'error')
        TriggerClientEvent('lp_railrobber:cl:plantRequestResult', src, false)
        return
    end

    local activePlanter = heist.plantingSrc
    if activePlanter then
        local activePending = pending[activePlanter]
        if activePending and os.time() <= activePending.expires then
            notify(src, 'มีผู้เล่นกำลังวางระเบิดอยู่', 'error')
            TriggerClientEvent('lp_railrobber:cl:plantRequestResult', src, false)
            return
        end
        pending[activePlanter] = nil
        heist.plantingSrc = nil
        syncState()
    end

    local center = liveTrainCoords()
    if not center then
        notify(src, 'เกิดข้อผิดพลาด', 'error')
        TriggerClientEvent('lp_railrobber:cl:plantRequestResult', src, false)
        return
    end
    local pc = playerCoords(src)
    if not pc or #(pc - center) > Config.BreachServerRadius then
        logSus(src, 'requestPlant', 'too_far')
        TriggerClientEvent('lp_railrobber:cl:plantRequestResult', src, false)
        return
    end

    local itemCount = exports.vorp_inventory:getItemCount(src, nil, Config.BombItem)
    if not itemCount or itemCount < 1 then
        notify(src, 'คุณต้องมีระเบิดลูกเล็ก', 'error')
        TriggerClientEvent('lp_railrobber:cl:plantRequestResult', src, false)
        return
    end
    -- consumed on request regardless of the later fuse outcome — matches lp_robbery exactly
    exports.vorp_inventory:subItem(src, Config.BombItem, 1)

    pending[src] = { plantAt = os.time(), expires = os.time() + Config.PendingTTL }
    heist.plantingSrc = src
    syncState()
    logTx(('plant requested src=%s'):format(src))
    TriggerClientEvent('lp_railrobber:cl:plantRequestResult', src, true)
end)

RegisterNetEvent('lp_railrobber:sv:confirmPlantBlow', function()
    local src = source
    if ratelimited(src, 'confirmPlant', 500) then return end

    -- one-shot: consumed whether this validates or not, blocking any replay
    local p = pending[src]
    pending[src] = nil

    if not heist or heist.state ~= S.PLANT or heist.plantingSrc ~= src then return end
    if not p or os.time() > p.expires then
        heist.plantingSrc = nil
        syncState()
        notify(src, 'คำขอหมดอายุ กรุณาลองใหม่', 'error')
        logSus(src, 'confirmPlantBlow', 'invalid_pending'); return
    end
    -- server-enforced fuse: blocks an instant-confirm cheat that skips the 15s wait
    if (os.time() - p.plantAt) < (Config.BombFuseTime - 1) then
        heist.plantingSrc = nil
        syncState()
        notify(src, 'ยังไม่ถึงเวลาระเบิด', 'error')
        logSus(src, 'confirmPlantBlow', ('fuse_too_early elapsed=%d'):format(os.time() - p.plantAt)); return
    end

    local center = liveTrainCoords()

    heist.state = S.LOOTING
    heist.plantingSrc = nil
    heist.breached = {}
    heist.carLocks = {}
    heist.breachDone = 0
    heist.perimeterSpawned = 0
    syncState()
    logTx('bomb confirmed -> LOOTING')

    -- rare, one-off event: -1 broadcast is acceptable here so everyone nearby sees/hears it
    TriggerClientEvent('lp_railrobber:cl:syncExplosion', -1, center and { x = center.x, y = center.y, z = center.z } or nil)
    TriggerClientEvent('lp_railrobber:cl:stopTrain', heist.ownerSrc)
    TriggerClientEvent('lp_railrobber:cl:beginLooting', -1)
end)

RegisterNetEvent('lp_railrobber:sv:cancelPlant', function()
    local src = source
    pending[src] = nil
    if heist and heist.state == S.PLANT and heist.plantingSrc == src then
        heist.plantingSrc = nil
        syncState()
    end
end)

-- ── pick a cargo car (shared, one active player per car) — item consumed HERE
-- itself, regardless of outcome. The REWARD is NOT granted here even on a
-- successful pick — it's deferred to sv:confirmCarLoot below, which only fires
-- once the client's lp_progbar actually finishes (not cancelled). This mirrors
-- the plant flow's request/confirm pending-token pattern, and closes the gap
-- where cancelling the progbar after a successful minigame still paid out.
-- (lockpickPending itself is declared near the top of the file, alongside
-- `pending`, so endHeist() above can clear it too.)
RegisterNetEvent('lp_railrobber:sv:lockpickAttempt', function(carIndex, success)
    local src = source
    if ratelimited(src, 'lockpickAttempt', 400) then return end
    if not heist or heist.state ~= S.LOOTING then return end
    carIndex = tonumber(carIndex)
    if not carIndex or carIndex < Config.LootCarriageRange[1] or carIndex > Config.LootCarriageRange[2] then return end
    if heist.breached[carIndex] then return end -- already done

    heist.carLocks = heist.carLocks or {}
    local lockedBy = heist.carLocks[carIndex]
    if lockedBy then
        local active = lockpickPending[lockedBy]
        if not active or active.carIndex ~= carIndex or os.time() > active.expires then
            lockpickPending[lockedBy] = nil
            heist.carLocks[carIndex] = nil
            lockedBy = nil
        end
    end
    if lockedBy and lockedBy ~= src then
        notify(src, ('ตู้ %d มีผู้เล่นกำลังงัดอยู่'):format(carIndex), 'error', 3000)
        return
    end

    local p = lockpickPending[src]
    if p and os.time() <= p.expires then
        logSus(src, 'lockpickAttempt', 'already_pending'); return -- must confirm/expire the current one first
    elseif p then
        if heist.carLocks[p.carIndex] == src then heist.carLocks[p.carIndex] = nil end
        lockpickPending[src] = nil
    end

    local center = liveTrainCoords()
    if center then
        local pc = playerCoords(src)
        if not pc or #(pc - center) > Config.BreachServerRadius then
            logSus(src, 'lockpickAttempt', 'too_far'); return
        end
    end

    -- item is consumed regardless of outcome — the real "cost" of a failed attempt,
    -- charged right here at the attempt, not deferred to the confirm step below
    local itemCount = exports.vorp_inventory:getItemCount(src, nil, Config.LockpickItem)
    if not itemCount or itemCount < 1 then
        notify(src, 'คุณต้องมีชุดงัดกุญแจ', 'error'); return
    end
    exports.vorp_inventory:subItem(src, Config.LockpickItem, 1)

    if not success then
        notify(src, ('งัดตู้ %d ไม่สำเร็จ ชุดงัดกุญแจเสียหาย'):format(carIndex), 'error', 3000)
        logTx(('lockpick failed car=%d src=%s'):format(carIndex, src))
        return -- no penalty beyond the item — car stays pickable, instant retry allowed
    end

    lockpickPending[src] = { carIndex = carIndex, expires = os.time() + Config.PendingTTL }
    heist.carLocks[carIndex] = src
    logTx(('lockpick succeeded car=%d src=%s -- awaiting progbar confirm'):format(carIndex, src))
    TriggerClientEvent('lp_railrobber:cl:lockpickAttemptResult', src, carIndex, true)
end)

-- ── reward — only after the client's progress bar actually completes ────────
RegisterNetEvent('lp_railrobber:sv:confirmCarLoot', function(carIndex)
    local src = source
    if ratelimited(src, 'confirmCarLoot', 400) then return end

    -- one-shot: consumed whether this validates or not, blocking any replay
    local p = lockpickPending[src]
    lockpickPending[src] = nil

    if not heist or heist.state ~= S.LOOTING then return end
    carIndex = tonumber(carIndex)
    if not p or os.time() > p.expires or p.carIndex ~= carIndex then
        if carIndex and heist.carLocks and heist.carLocks[carIndex] == src then
            heist.carLocks[carIndex] = nil
        end
        logSus(src, 'confirmCarLoot', 'invalid_pending'); return
    end
    local center = liveTrainCoords()
    local pc = playerCoords(src)
    if not center or not pc or #(pc - center) > Config.BreachServerRadius then
        if heist.carLocks and heist.carLocks[carIndex] == src then heist.carLocks[carIndex] = nil end
        logSus(src, 'confirmCarLoot', 'too_far')
        return
    end
    if not carIndex or heist.breached[carIndex] or not heist.carLocks or heist.carLocks[carIndex] ~= src then
        if carIndex and heist.carLocks and heist.carLocks[carIndex] == src then
            heist.carLocks[carIndex] = nil
        end
        return
    end

    heist.carLocks[carIndex] = nil
    heist.breached[carIndex] = true
    heist.breachDone = heist.breachDone + 1
    syncState()
    giveCarReward(src, carIndex)

    -- perimeter NPCs on a successful pick, capped
    if heist.perimeterSpawned < Config.LootPerimeterCap then
        local n = math.random(Config.LootPerimeterSpawnPerPick[1], Config.LootPerimeterSpawnPerPick[2])
        n = math.min(n, Config.LootPerimeterCap - heist.perimeterSpawned)
        heist.perimeterSpawned = heist.perimeterSpawned + n
        syncState()
        TriggerClientEvent('lp_railrobber:cl:spawnPerimeter', heist.ownerSrc, { count = n })
    end

    if heist.breachDone >= (Config.LootCarriageRange[2] - Config.LootCarriageRange[1] + 1) then
        TriggerClientEvent('lp_railrobber:cl:notify', -1, 'ปล้นรถไฟสำเร็จทั้งขบวน!', 'success', 6000)
        endHeist('all_cars_looted', S.COMPLETE)
    end
end)

RegisterNetEvent('lp_railrobber:sv:cancelCarLoot', function(carIndex)
    local src = source
    carIndex = tonumber(carIndex)
    local p = lockpickPending[src]
    if p and (not carIndex or p.carIndex == carIndex) then
        lockpickPending[src] = nil
        if heist and heist.carLocks and heist.carLocks[p.carIndex] == src then
            heist.carLocks[p.carIndex] = nil
        end
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
    pending[src] = nil
    lockpickPending[src] = nil
    if heist then
        if heist.plantingSrc == src then
            heist.plantingSrc = nil
            syncState()
        end
        if heist.carLocks then
            for carIndex, lockedBy in pairs(heist.carLocks) do
                if lockedBy == src then heist.carLocks[carIndex] = nil end
            end
        end
    end
    if heist and heist.buyerSrc == src
        and (heist.state == S.RESERVED or heist.state == S.AMBUSH or heist.state == S.TRAIN_EN_ROUTE) then
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

-- watchdog: two continuous clocks, neither resets on intra-group state changes.
-- Covers death/disconnect/AFK without per-player death/respawn tracking — the
-- server has a revive system, so a stuck/dead buyer just eats into the clock
-- instead of jamming the whole heist (and its cooldown) forever.
CreateThread(function()
    while true do
        Wait(15000)
        if heist and (heist.state == S.RESERVED or heist.state == S.AMBUSH) then
            if os.time() - heist.reservedAt > Config.AmbushClearTimeoutSec then
                logTx('ambush-clear timeout (30 min) hit -> fail')
                -- แจ้งเฉพาะ buyer + คนที่อยู่ใกล้จุดซุ่มจริง ๆ ไม่ broadcast ทั้งเซิร์ฟ
                notifyNearby(heist.buyerSrc, heist.ambush.coords, Config.NotifyRadius, 'หมดเวลา! กิจกรรมถูกยกเลิก', 'error', 6000)
                endHeist('ambush_timeout', S.FAILED)
            end
        elseif heist and heist.trainSpawnedAt
            and (heist.state == S.PVE or heist.state == S.PLANT or heist.state == S.LOOTING) then
            if os.time() - heist.trainSpawnedAt > Config.TrainClearTimeoutSec then
                logTx('train clear ceiling (30 min) hit -> fail, cooldown starts')
                notifyNearby(heist.buyerSrc, liveTrainCoords(), Config.NotifyRadius, 'หมดเวลาปล้นรถไฟ! กิจกรรมถูกยกเลิก', 'error', 6000)
                endHeist('clear_timeout', S.FAILED)
            end
        end
    end
end)
