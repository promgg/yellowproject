-- lp_robbery / config.lua
-- Port of devchacha-robbery (RSG-Core) to VORPCore + lp_ stack.
-- Server is the single authority for every state transition (see server/main.lua) —
-- this file only holds data: locations, timers, rewards. No secrets here.

Config = {}

Config.Debug = true -- gate for dbg() prints (server) — set false in production

-- ────────────────────────────────────────────────────────────────────────────
--  Item — single item used for BOTH store safes and bank vaults.
--  Consumed on the *request* step regardless of skill-check pass/fail.
-- ────────────────────────────────────────────────────────────────────────────
Config.Item = 'small_bomb' -- ระเบิดลูกเล็ก

-- ────────────────────────────────────────────────────────────────────────────
--  Police
-- ────────────────────────────────────────────────────────────────────────────
Config.Police = {
    RequiredForStore = 0, -- min. online police required to start a store robbery
    RequiredForBank  = 0, -- min. online police required to start a bank robbery
    Jobs = { 'police' },  -- jobs that receive the alert (this project only has 'police')
}

-- ────────────────────────────────────────────────────────────────────────────
--  Timers
-- ────────────────────────────────────────────────────────────────────────────
Config.RobberyDuration     = 2  -- minutes — store safe unlock wait after planting
Config.BankRobberyDuration = 2  -- minutes — bank vault cooling wait after the blast
Config.BankFuseTime        = 15 -- seconds — fuse between planting and the bank explosion
Config.PendingTTL          = 30 -- seconds — server-side pending-request expiry (anti-replay)

-- นาที — หลังปล้น+เก็บของจุดหนึ่งแล้ว จุดนั้นจะกลับมางัดได้อีกครั้งเองเมื่อผ่านไปกี่นาที
-- (auto-reset ใน memory; restart resource ก็ล้างหมดเช่นกัน) ตอนติด cooldown จะโชว์เวลานับถอยหลังที่จุด
Config.RelootCooldown      = 30

-- ────────────────────────────────────────────────────────────────────────────
--  Interaction ranges (server re-validates both of these — never trusts client)
-- ────────────────────────────────────────────────────────────────────────────
Config.Range        = 3.0 -- meters — must be this close to plant / confirm / loot
Config.DisplayRange = 5.0 -- meters — countdown/status text only shows within this range

Config.KEY_E   = 0x17BEC168 -- E (hold-to-interact)
Config.HoldMs  = 900        -- ms to hold E before the action starts

-- Progress bar durations (ms)
Config.PlantDuration = { store = 5000, bank = 7000 }
Config.LootDuration  = { store = 5000, bank = 7000 }

-- ────────────────────────────────────────────────────────────────────────────
--  Hand props (attached during the lp_progbar phases)
--  lp_progbar owns spawn/attach/cleanup (สร้าง + AttachEntityToEntity + ลบให้เอง
--  ครบทุกทาง: จบ/ยกเลิก/ตาย/resource stop). ที่นี่เก็บแค่ data.
--  bone = ชื่อ bone (client จะแปลงเป็น index ด้วย GetEntityBoneIndexByName ตอนเรียก)
--  coords/rotation = offset ในมือ — ค่าเริ่มต้นด้านล่างเป็นค่าตั้งต้น อาจต้องขยับ
--  ในเกมเล็กน้อยให้เข้ามือพอดี (ปรับตัวเลขตรงนี้ได้เลย ไม่ต้องแตะโค้ด)
-- ────────────────────────────────────────────────────────────────────────────
Config.Props = {
    -- วางระเบิด (ร้าน + ธนาคาร) — มัดไดนาไมต์ในมือขวา
    plant = {
        model    = 'p_dynamite01x',
        bone     = 'SKEL_R_Hand',
        coords   = { x = 0.0,  y = 0.0,  z = 0.0 },
        rotation = { x = 0.0,  y = 0.0,  z = 0.0 },
    },
    -- เก็บของ/งัด (ร้าน + ธนาคาร) — เหล็กงัดในมือขวา
    loot = {
        model    = 'p_lockpick01x',
        bone     = 'SKEL_R_Hand',
        coords   = { x = 0.0,  y = 0.0,  z = 0.0 },
        rotation = { x = 0.0,  y = 0.0,  z = 0.0 },
    },
}

-- ────────────────────────────────────────────────────────────────────────────
--  Rewards — server computes cash/items, client never sends amounts
-- ────────────────────────────────────────────────────────────────────────────
Config.Rewards = {
    Store = {
        minCash = 100, maxCash = 300,
        items = {
            { name = 'loot_ring',       amount = 1, chance = 60 },
            { name = 'loot_watch',      amount = 1, chance = 40 },
            { name = 'loot_earring',    amount = 1, chance = 35 },
            { name = 'goldring',        amount = 1, chance = 25 },
            { name = 'loot_gold_tooth', amount = 1, chance = 20 },
        },
    },
    BankVault = {
        minCash = 500, maxCash = 2000,
        items = {
            { name = 'goldbar',                                amount = {1, 2}, chance = 70 },
            { name = 'mat_diamond',                             amount = {1, 2}, chance = 40 },
            { name = 'provision_diamond_ring',                  amount = 1,      chance = 30 },
            { name = 'provision_jewelry_box',                   amount = 1,      chance = 25 },
            { name = 'provision_jewelry_gld_pearl_necklace',    amount = 1,      chance = 20 },
            { name = 'provision_ring_platinum',                 amount = 1,      chance = 15 },
            { name = 'buff_cross_gold',                         amount = 1,      chance = 8  },
        },
    },
}

-- ────────────────────────────────────────────────────────────────────────────
--  Explosion FX (bank vault blast)
-- ────────────────────────────────────────────────────────────────────────────
Config.Explosion = {
    type        = 29, -- Dynamite
    radius      = 10.0,
    shake       = 1.0,
    cameraShake = 'LARGE_EXPLOSION_SHAKE',
}

Config.PoliceAlertFormat = 'แจ้งเตือน: มีการปล้นที่ %s!'

-- ────────────────────────────────────────────────────────────────────────────
--  Store locations (7) — coords = the register interaction point.
--  Copied verbatim from devchacha-robbery/config.lua (registers[1].coords).
-- ────────────────────────────────────────────────────────────────────────────
Config.Stores = {
    -- ['ValentineGeneral'] = {
    --     label  = 'Valentine General Store',
    --     coords = vector3(-324.24, 804.08, 117.98),
    -- },
    -- ['RhodesGeneral'] = {
    --     label  = 'Rhodes General Store',
    --     coords = vector3(1330.34, -1293.58, 77.02),
    -- },
    -- ['SaintDenisGeneral'] = {
    --     label  = 'Saint Denis General Store',
    --     coords = vector3(2828.26, -1320.1, 46.8),
    -- },
    ['StrawberryGeneral'] = {
        label  = 'Strawberry General Store',
        coords = vector3(-1789.33, -387.55, 160.33),
    },
    -- ['BlackwaterGeneral'] = {
    --     label  = 'Blackwater General Store',
    --     coords = vector3(-785.49, -1322.16, 43.88),
    -- },
    -- ['ArmadilloGeneral'] = {
    --     label  = 'Armadillo General Store',
    --     coords = vector3(-3687.3, -2622.49, -13.43),
    -- },
    -- ['TumbleweedGeneral'] = {
    --     label  = 'Tumbleweed General Store',
    --     coords = vector3(-5486.36, -2937.69, -0.4),
    -- },
}

-- ────────────────────────────────────────────────────────────────────────────
--  Bank locations (5) — each has 1+ vaults; vaultId is the array index.
--  Copied verbatim from devchacha-robbery/config.lua.
-- ────────────────────────────────────────────────────────────────────────────
Config.Banks = {
    ['ValentineBank'] = {
        label  = 'Valentine Bank',
        vaults = {
            { coords = vector3(-309.00, 763.63, 118.70) },
        },
    },
    ['RhodesBank'] = {
        label  = 'Rhodes Bank',
        vaults = {
            { coords = vector3(1287.42, -1314.50, 77.04) },
        },
    },
    ['BlackwaterBank'] = {
        label  = 'Blackwater Bank',
        vaults = {
            { coords = vector3(-820.08, -1273.85, 43.65) },
        },
    },
    ['SaintDenisBank'] = {
        label  = 'Saint Denis Bank',
        vaults = {
            { coords = vector3(2644.49, -1306.44, 52.25) },
        },
    },
    ['ArmadilloBank'] = {
        label  = 'Armadillo Bank',
        vaults = {
            { coords = vector3(-3665.95, -2632.33, -13.59) },
        },
    },
}
