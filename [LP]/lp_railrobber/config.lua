-- lp_railrobber / config.lua  (shared)
-- Moving-train robbery, 5-phase heist owned exclusively by the intel buyer (no
-- party/group system exists anywhere in this codebase, confirmed — the buyer
-- is the sole authority/beneficiary throughout):
--   1. buy intel ($1000, buyer-only blip)
--   2. ground ambush at the point (5 NPCs, kill-agnostic — anyone nearby can help)
--   3. train arrives, board, clear 10 NPCs scattered across carriages, plant a
--      bomb at the locomotive (full lp_robbery bank-heist bomb logic reused)
--   4. all 10 cars (idx 2-11) lockpickable, item-gated, buyer-only
--   5. all cars picked -> complete, train deleted
--
-- Server is the SINGLE authority for every state transition. This file is data
-- only. Coords marked "TUNE IN-GAME" are prototypes that must be re-checked on
-- the live track (direction, tunnels, bridges) — see the design notes.

Config = {}

Config.Debug = true -- gate for dbg() prints

-- ── Heist gating ────────────────────────────────────────────────────────────
Config.IntelCooldownMinutes = 60   -- how long before intel can be bought again (global)
-- Only ONE heist may run server-wide at a time (state is a single object).

-- metres — server-side "who has a stake in this" notify radius (used by
-- notifyNearby in server/main.lua). Buyer always gets these regardless of
-- distance; other players only get them if within this range of the relevant
-- point (ambush point or live train coords) — NOT broadcast to the whole
-- server, since most players have zero connection to any given heist.
Config.NotifyRadius = 150.0

-- ── Intel broker NPC ────────────────────────────────────────────────────────
-- Buying intel here starts a heist and tells ONLY THE BUYER the ambush point
-- (no party/group system exists in this codebase — the heist is buyer-exclusive
-- end to end; anyone else can physically help fight, but never sees the blip
-- and never gets credited/paid).
Config.IntelNPC = {
    model         = `A_M_M_BiVWorker_01`,         -- proven-good NPC model (same as lp_fasttravel's seller)
    coords        = vector3(1441.2980, 342.7788, 88.5151),     -- TUNE IN-GAME (placeholder near Valentine)
    heading       = 45.0,
    prompt        = 'ซื้อข่าวขบวนสินค้า',
    price         = { currency = 0, amount = 1000 }, -- currency 0 = cash
    spawnDistance = 35.0, -- proximity spawn/despawn radius (same pattern as nx_shop)
}

-- ── Ambush points (LOCKED coords, direction still TUNE IN-GAME) ──────────────
-- Entering an ambush point's radius is what spawns the train. `spawnOffset` is
-- where the train is birthed relative to the ambush point (it snaps to the
-- nearest track); tune so the train APPROACHES the point from up-track.
Config.AmbushRadius = 30.0 -- metres — buyer must enter this to trigger the train
Config.AmbushPoints = {
    {
        id = 'A1',
        coords = vector3(-1934.5616, -2606.0967, 69.8700), heading = 88.5265,
        spawnOffset = vector3(-350.0, 0.0, 0.0), -- TUNE IN-GAME so the train rolls toward the point
    },
    {
        id = 'A2',
        coords = vector3(-5827.2231, -3246.0247, -18.6066), heading = 145.5882,
        spawnOffset = vector3(-350.0, 0.0, 0.0), -- TUNE IN-GAME
    },
}

-- ── Train ───────────────────────────────────────────────────────────────────
-- CARGO train = separate boxcars, NO vestibule/connecting doors between cars
-- (passenger cars had those + couldn't be opened/removed). Walk on the roofs /
-- jump car-to-car. Proven-loading in bcc-train's shop; spike walked its roofs fine.
-- Other cargo hashes to try: 0x0660E567, 0x0941ADB7, 0x0CCC2F70, 0x1EEC5C2A ...
Config.TrainHash    = 0x0660E567 -- Cargo Train 2
Config.CruiseSpeed  = 10.0       -- 8-14 range
-- Guard/loot car is picked at RANDOM (per heist) from this index range, so
-- players must explore the train instead of always knowing it's car 8.
-- idx 2-11 confirmed valid on this cargo train.
Config.LootCarriageRange = { 2, 11 }
Config.GuardSpawnRange = 25.0    -- metres — carriage NPCs spawn only once the buyer walks within this range of that car (not all at once on boarding; avoids racing carriages that are still streaming in)

-- Guard attach offset ON the carriage. z was too LOW before (guards clipped INSIDE
-- the car). Default sits them on/above the roof. TUNE IN-GAME per train/carriage:
-- raise z if they float, lower if they clip; adjust startY/spacingY to spread them.
Config.GuardAttach = {
    x = 0.0,
    z = 2.0,        -- tested-visible height on cargo car (not sunk)
    startY = -2.5,  -- first guard offset along the car length
    spacingY = 1.6, -- gap between guards
}

-- ── Guard model/weapon (shared by ambush + carriage NPC batches) ────────────
Config.GuardModel = `s_m_m_unitrainguards_01`
Config.GuardWeapon = `WEAPON_REPEATER_CARBINE`

-- ── Phase 2: ground ambush (NEW) ──────────────────────────────────────────────
-- One batch of NPCs spawned AT the ambush point itself, before the train exists.
-- Kill-agnostic — any nearby player can help clear it — but only the buyer's
-- client reports the clear to the server (same trust model the old wave system
-- already used for waveCleared).
Config.AmbushGuardCount = 5

-- ── Phase 3: carriage combat (replaces the old 3-wave system) ────────────────
-- ONE batch, randomly scattered across carriages in Config.LootCarriageRange
-- (repeats allowed — a carriage can end up with 0, 1, or several NPCs by chance).
Config.TrainNpcCount = 10

-- ── Phase 3: bomb plant at the locomotive (logic ported verbatim from
-- lp_robbery's bank-vault plant: hold-E -> Spacebar() skill check -> progbar
-- w/ dynamite prop+anim -> confirm -> server-enforced fuse -> real explosion) ──
Config.BombItem      = 'small_bomb' -- same item lp_robbery already uses — one bomb economy across heist resources
Config.PlantDuration  = 6000        -- ms, progbar duration
Config.BombFuseTime   = 15          -- seconds — "หนีเร็ว!" window before the real explosion
Config.PendingTTL     = 30          -- seconds — anti-replay pending-token expiry (mirrors lp_robbery)
-- CLIENT: separate (wider) range for the plant prompt than CarBreachRange below —
-- the distance check is against the LOCOMOTIVE ENTITY'S ORIGIN (GetEntityCoords),
-- which sits somewhere near the middle of a multi-metre-long engine car, not at
-- its surface. Confirmed live: player standing right next to the loco still read
-- 7-9.6m away at CarBreachRange=3.5. 8.0 comfortably covers standing anywhere
-- on/beside the engine car; TUNE IN-GAME if still too tight/loose.
Config.PlantBreachRange = 8.0
Config.Explosion = {
    type = 29, radius = 10.0, shake = 1.0, cameraShake = 'LARGE_EXPLOSION_SHAKE',
}

-- ── Phase 4: 10-car lockpicking (replaces the single random-car breach) ──────
-- Every car in Config.LootCarriageRange is pickable. Buyer-only. Gated by
-- exports.lp_minigame:Lockpick() AND a real inventory item, consumed on EVERY
-- attempt regardless of outcome (unlike lp_robbery's zero-cost lockpick fail).
Config.CarLockpick     = { pins = 3, difficulty = 4 }
Config.LockpickItem    = 'lockpick' -- NEW item — does not exist in vorp_inventory's DB yet, must be added live
Config.CarBreachRange   = 3.5      -- CLIENT: must be this close to a car to pick it (renamed from BreachRange)
Config.BreachServerRadius = 200.0 -- SERVER: coarse anti-cheat radius from the train (also reused by the plant check)
Config.CarProgDuration  = 5000     -- ms, progbar after a successful lockpick

-- NPCs spawned around the train's EXTERIOR (not on it) per successful pick,
-- pressure that ramps up as the crew loots more cars — capped so a full clear
-- doesn't spiral perf-wise even on a bad RNG run.
Config.LootPerimeterSpawnPerPick = { 2, 4 }  -- random count in this range per successful pick
Config.LootPerimeterCap    = 30
Config.LootPerimeterRadius = { 8.0, 20.0 }   -- min/max metres from the train's live position

-- reward PER CAR (replaces the old single Config.Reward) — first-pass numbers,
-- targets ~10 cars totalling close to the old single-car payout; tune after a
-- full-clear playtest since 10 independent rolls don't compound the same way
-- one roll did.
-- ไม่มีเงินสดต่อตู้แล้ว — ต่อตู้: 50% ได้ของงานดำ 1-2 ชิ้นไม่ซ้ำกัน / 50% ได้ blueprint_low 1-2 ชิ้น
Config.CarReward = {
    poolChancePercent = 50,
    pool = {
        'loot_necklace', 'loot_ring', 'loot_watch', 'loot_chinese_coin',
        'loot_earring', 'loot_brooch', 'loot_silver_tooth',
    },
    poolCount = { 1, 2 },
    blueprintItem = 'blueprint_low',
    blueprintCount = { 1, 2 },
}

-- ── Ranges / keys ───────────────────────────────────────────────────────────
Config.InteractRange = 2.5
Config.KEY_E  = 0x17BEC168
Config.HoldMs = 900

-- ── Server-authoritative state machine ──────────────────────────────────────
Config.States = {
    IDLE            = 'IDLE',
    RESERVED        = 'RESERVED',          -- intel bought, ambush assigned, waiting for buyer to arrive
    AMBUSH          = 'AMBUSH',            -- buyer reached the ambush point; ground NPC batch spawned/fighting
    TRAIN_EN_ROUTE  = 'TRAIN_EN_ROUTE',    -- ambush cleared; train spawned + approaching
    PVE             = 'PVE',               -- train boarded; single 10-NPC carriage batch being cleared
    PLANT           = 'PLANT',             -- carriage NPCs dead; buyer may plant the bomb at the locomotive
    LOOTING         = 'LOOTING',           -- train stopped; all 10 cars pickable (buyer-only, item-gated)
    COMPLETE        = 'COMPLETE',
    FAILED          = 'FAILED',
    CLEANUP         = 'CLEANUP',
}

-- Two continuous clocks, neither ever resets on an intra-group state change.
-- The $1000 intel cost is never refunded on either timeout (money is only ever
-- deducted once, at purchase).
Config.AmbushClearTimeoutSec = 1800 -- covers RESERVED+AMBUSH: buyer must clear the ground ambush within 30 min of buying intel
Config.TrainClearTimeoutSec  = 1800 -- covers PVE+PLANT+LOOTING: whole train phase must resolve within 30 min of the train spawning
