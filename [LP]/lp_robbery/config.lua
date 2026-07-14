-- lp_robbery / config.lua
-- Port of devchacha-robbery (RSG-Core) to VORPCore + lp_ stack.
-- Server is the single authority for every state transition (see server/main.lua) —
-- this file only holds data: locations, timers, rewards. No secrets here.

Config = {}

Config.Debug = true -- gate for dbg() prints (server) — set false in production

-- ────────────────────────────────────────────────────────────────────────────
--  Item — bank vault only. Stores no longer need a bomb (lockpick-only, see
--  Config.Lockpick below) — consumed on the bank *request* step regardless of
--  the later skill-check result.
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
Config.BankRobberyDuration = 2  -- minutes — bank vault cooling wait after the blast
Config.BankFuseTime        = 15 -- seconds — fuse between planting and the bank explosion
Config.PendingTTL          = 30 -- seconds — server-side pending-request expiry (anti-replay, bank only now)

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

-- ────────────────────────────────────────────────────────────────────────────
--  เครื่องคิดเงินจริงในร้าน — โมเดลนี้หาได้จาก prop-placer dev tool ในเกม (ยืนที่
--  ร้านจริงแล้วเล็ง object ที่เคาน์เตอร์). client ใช้หา entity จริงที่อยู่ใกล้ ๆ จุด
--  Config.Stores[..].coords ตอนจะ interact เพื่อให้ตัวละครหันหน้าเข้า "เครื่องคิดเงินจริง"
--  พอดี แทนที่จะหันตามพิกัดที่เล็งไว้คร่าว ๆ (กันเคสพิกัด store.coords คลาดเคลื่อนจาก
--  ตัว object จริงในโลกไม่กี่เมตร) — ถ้าหาไม่เจอ (โมเดลผิด/ไม่มีในร้านนั้น) fallback
--  กลับไปใช้ store.coords แบบเดิม
-- ────────────────────────────────────────────────────────────────────────────
Config.RegisterModel        = 'p_register03x'
Config.RegisterSearchRadius = 2.5 -- เมตร — รัศมีหา object รอบจุด store.coords

-- Progress bar durations (ms)
Config.PlantDuration = 7000            -- bank only now — stores skip the bomb-plant phase entirely
Config.LootDuration  = { store = 5000, bank = 7000 }

-- ────────────────────────────────────────────────────────────────────────────
--  Hand props (attached during the lp_progbar phases)
--  lp_progbar owns spawn/attach/cleanup (สร้าง + AttachEntityToEntity + ลบให้เอง
--  ครบทุกทาง: จบ/ยกเลิก/ตาย/resource stop). ที่นี่เก็บแค่ data.
--  bone = ชื่อ bone (client แปลงเป็น index ด้วย GetEntityBoneIndexByName) — ใช้กับ
--  prop ส่วนใหญ่. boneId = เลข bone ID ดิบ (client ใช้ GetPedBoneIndex แทน) — ใช้เมื่อ
--  ตัวอ้างอิงต้นทางระบุมาเป็นเลข ID ไม่ใช่ชื่อ (ใส่ได้แค่อย่างใดอย่างหนึ่ง)
--  coords/rotation = offset ในมือ — ค่าด้านล่างอ้างอิงจากสคริปต์ VORP/RSG จริงที่ใช้
--  prop + anim ตัวเดียวกันกับเรา (ดู comment แต่ละอัน) ไม่ใช่ placeholder แล้ว แต่ยัง
--  ควรเช็คในเกมอีกที เพราะโมเดล prop เราอาจต่างจากต้นฉบับเล็กน้อย
-- ────────────────────────────────────────────────────────────────────────────
Config.Props = {
    -- วางระเบิด (ธนาคารเท่านั้นแล้ว — ร้านไม่ใช้ระเบิดอีกต่อไป) — ระหว่างท่า
    -- WORLD_HUMAN_CROUCH_INSPECT (นั่งยองก้มมองพื้น). อ้างอิงจาก Mushy_BankRobbery
    -- (VORP bank-robbery script จริงที่ใช้ p_dynamite01x + anim ตัวนี้เป๊ะ) — boneId
    -- ดิบ ไม่ใช่ bone name.
    plant = {
        model    = 'p_dynamite01x',
        boneId   = 54565,
        coords   = { x = 0.06, y = 0.0,  z = 0.06 },
        rotation = { x = 90.0, y = 0.0,  z = 0.0 },
    },
    -- เก็บของ/งัด (ร้าน + ธนาคาร) — ระหว่างท่า script_common@jail_cell@unlock@key/action
    -- (มือหยิบจับของชิ้นเล็กระหว่างนิ้ว ไม่ใช่กำในฝ่ามือ) อ้างอิงจาก rsg-doorlock
    -- (RSG-Core) ที่ใช้ anim dict เดียวกันเป๊ะกับที่นี่ — ต่างกันแค่ prop model
    -- (ต้นฉบับใช้กุญแจ P_KEY02X เราใช้ p_lockpick01x)
    loot = {
        model    = 'p_lockpick01x',
        bone     = 'SKEL_R_Finger12',
        coords   = { x = 0.02,  y = 0.0120, z = -0.0085 },
        rotation = { x = 0.024, y = -160.0, z = 200.0 },
    },
}

-- ────────────────────────────────────────────────────────────────────────────
--  Lockpick minigame — gates the ONE-STEP store loot (walk up -> lockpick ->
--  reward, no bomb/plant/wait at all). Client-side UX gate only; server never
--  trusts the result — it just decides whether the client bothers to fire
--  sv:lootStore, same trust model as Spacebar() on the bank plant step below.
--  Fail = no penalty, no state change, player can hold-E and retry immediately.
--  Bank stays on the bomb-plant-fuse-explosion flow (small_bomb, no lockpick) —
--  EnabledForBank/Bank are unused unless that changes later.
-- ────────────────────────────────────────────────────────────────────────────
Config.Lockpick = {
    EnabledForStore = true,
    EnabledForBank  = false,
    Store = { pins = 3, difficulty = 3 },
    Bank  = { pins = 3, difficulty = 3 }, -- unused while EnabledForBank = false
}

-- ────────────────────────────────────────────────────────────────────────────
--  Rewards — server computes cash/items, client never sends amounts
-- ────────────────────────────────────────────────────────────────────────────
Config.Rewards = {
    Store = {
        minCash = 2000, maxCash = 2000,
        -- ของงานดำ 7 ชิ้น น้ำหนักเท่ากันทุกชิ้น สุ่มไม่ซ้ำกัน 3-5 ชิ้น (แทนระบบ items/chance เดิมทั้งหมด)
        pool = {
            'loot_necklace', 'loot_ring', 'loot_watch', 'loot_chinese_coin',
            'loot_earring', 'loot_brooch', 'loot_silver_tooth',
        },
        poolCount = { 3, 5 },
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
