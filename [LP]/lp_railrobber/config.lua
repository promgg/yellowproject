-- lp_railrobber / config.lua  (shared)
-- Moving-train robbery PvPvE. STAGE 1 covers the PvE spine only:
--   buy intel -> assign ambush -> buyer's city told -> buyer enters ambush zone
--   -> train spawns up-track and approaches -> NPC guard waves defend.
-- Breach / KotH hold / reward = STAGE 2 (stubbed, clearly marked).
--
-- Server is the SINGLE authority for every state transition. This file is data
-- only. Coords marked "TUNE IN-GAME" are prototypes that must be re-checked on
-- the live track (direction, tunnels, bridges) — see the design notes.

Config = {}

Config.Debug = true -- gate for dbg() prints

-- ── Heist gating ────────────────────────────────────────────────────────────
Config.IntelCooldownMinutes = 60   -- how long before intel can be bought again (global)
-- Only ONE heist may run server-wide at a time (state is a single object).

-- ── Intel broker NPC ────────────────────────────────────────────────────────
-- Buying intel here starts a heist and tells the BUYER'S WHOLE CITY the ambush point.
Config.IntelNPC = {
    model   = `s_m_m_sdticketseller_01`,         -- proven-good NPC model (same as lp_fasttravel's seller)
    coords  = vector3(1441.2980, 342.7788, 88.5151),     -- TUNE IN-GAME (placeholder near Valentine)
    heading = 45.0,
    prompt  = 'ซื้อข่าวขบวนสินค้า',
    price   = { currency = 0, amount = 250 },     -- currency 0 = cash
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
Config.GuardSpawnRange = 25.0    -- guards spawn only when a player comes this close to the guard car

-- Guard attach offset ON the carriage. z was too LOW before (guards clipped INSIDE
-- the car). Default sits them on/above the roof. TUNE IN-GAME per train/carriage:
-- raise z if they float, lower if they clip; adjust startY/spacingY to spread them.
Config.GuardAttach = {
    x = 0.0,
    z = 2.0,        -- tested-visible height on cargo car (not sunk)
    startY = -2.5,  -- first guard offset along the car length
    spacingY = 1.6, -- gap between guards
}

-- ── Guard waves (PvE) ───────────────────────────────────────────────────────
-- STAGE 1: guards spawn on the train, attached to the guard carriage, and fight
-- whoever boards. Each wave spawns after the previous is cleared.
Config.GuardModel = `s_m_m_unitrainguards_01`
Config.GuardWeapon = `WEAPON_REPEATER_CARBINE`
Config.Waves = {
    { count = 3 }, -- wave 1
    { count = 3 }, -- wave 2
    { count = 2 }, -- wave 3 (heavier could be added in Stage 2)
}

-- ── STAGE 2: breach + reward ─────────────────────────────────────────────────
-- After the waves are cleared the train stops and players breach the loot car.
-- SCOPE CUT (per client): no city-vs-city KotH / participant cap / roster for
-- now — reward goes to whoever actually breached the car, after a short
-- countdown. Full PvP/KotH design pending clearer client requirements.
Config.BreachDurationMs = 6000    -- hold-E breach time per car
Config.BreachRange      = 3.5     -- CLIENT: must be this close to a loot car to breach
Config.BreachServerRadius = 200.0 -- SERVER: coarse anti-cheat radius from the train (train is long — client gates the precise car distance)

Config.Hold = {
    durationSec = 10, -- countdown after a successful breach before the breacher is paid
    tickSec     = 1,
}

-- reward paid to the player who breached the loot car
Config.Reward = {
    cashMin = 300, cashMax = 600, currency = 0,
    items = {
        { name = 'loot_watch',   amount = {1, 2}, chance = 55 },
        { name = 'loot_gold_tooth', amount = 1,      chance = 40 },
        { name = 'mat_diamond', amount = 1,    chance = 20 },
    },
}

-- ── Ranges / keys ───────────────────────────────────────────────────────────
Config.InteractRange = 2.5
Config.KEY_E  = 0x17BEC168
Config.HoldMs = 900

-- ── Server-authoritative state machine ──────────────────────────────────────
Config.States = {
    IDLE            = 'IDLE',
    RESERVED        = 'RESERVED',          -- intel bought, ambush assigned, waiting for buyer to arrive
    TRAIN_EN_ROUTE  = 'TRAIN_EN_ROUTE',    -- buyer entered ambush zone; train spawned + approaching
    PVE             = 'PVE',               -- guard waves being cleared
    BREACHING       = 'BREACHING',         -- (STAGE 2) train stopped, breach cars
    HOLD            = 'HOLD',              -- (STAGE 2) KotH capture-bar
    COMPLETE        = 'COMPLETE',
    FAILED          = 'FAILED',
    CLEANUP         = 'CLEANUP',
}

Config.EnRouteTimeoutSec = 900 -- if buyer never reaches the ambush, auto-fail the reservation

-- Hard ceiling from the moment the train spawns (TRAIN_EN_ROUTE) until the heist
-- must be fully resolved (breach + hold done). Covers death/disconnect/AFK
-- without needing per-player death/respawn tracking — the server has a revive
-- system, so a stuck/dead owner just eats into this clock instead of jamming
-- the whole heist (and its cooldown) forever.
Config.TrainClearTimeoutMin = 20
