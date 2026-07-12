Config = {}

-- ═══════════════════════════════════════════════════════════════════════
-- lp_gunsmith — visual weapon component customization with camera preview
-- Persistence model: components are written into vorp_inventory's own
-- `loadout` DB table (columns `components` + `comps`, both JSON arrays of
-- component hash-name strings). vorp_inventory already re-applies every
-- entry in `loadout.components` automatically whenever a weapon is
-- equipped (see [VORP]/vorp_inventory/client/models/WeaponClass.lua
-- Weapon:loadComponents(), fed from server/services/itemsDatabase.lua
-- loadAllWeapons() which decodes the `components` column). We do NOT
-- modify vorp_inventory — we only read/write its `loadout` table exactly
-- like its own InventoryAPI.registerWeapon()/getcomps() already do.
-- ═══════════════════════════════════════════════════════════════════════

-- ── Stations ─────────────────────────────────────────────────────────────
-- Same 3 towns nx_shop sells the customizable starter weapons in.
-- `anchor` = this station's own private "preview void" spot where the floating
-- weapon spawns and the camera looks (independent of where the player stands).
-- Set each one yourself to an empty out-of-the-way spot near that station.
Config.Stations = {
    { label = 'ช่างปืน Valentine',  coords = vector3(-276.2224, 778.8934, 119.5040), anchor = vector3(-276.2224, 778.8934, 119.7040) },
    { label = 'ช่างปืน Rhodes',     coords = vector3(1326.1441, -1322.0596, 77.8891), anchor = vector3(1326.441, -1322.0596, 78.0891) },
    { label = 'ช่างปืน Annesburg',  coords = vector3(2949.9631, 1316.7965, 44.8203), anchor = vector3(2949.9631, 1316.7965, 45.1203) },
}

-- Client-side prompt/interact radius. Server adds ServerDistancePadding on
-- top of this when re-checking (latency/interpolation tolerance) — same
-- pattern nx_shop uses for its own isNearStore() check.
Config.InteractDistance = 2.5
Config.ServerDistancePadding = 1.5
Config.HoldMs = 900 -- ms — how long [E] must be held (lp_textui:TextUIHold) to open the station

-- ── Pricing / rate limit ────────────────────────────────────────────────
Config.ComponentPrice = 35.0   -- flat cash price per component application
Config.RemoveComponentPrice = 15.0 -- price to strip a slot back to bare/no component
-- min ms between accepted apply/remove requests per player. Kept LOW because
-- picks are now rapid (no per-pick progress bar) and the client requestBusy guard
-- + server `processing` flag already serialize legit requests one-at-a-time — this
-- only exists to throttle a script spamming the event directly.
Config.RateLimitMs = 300

-- ── Apply progress bar ──────────────────────────────────────────────────
-- Shown once, right when a component choice is submitted (not during live
-- preview/highlight) — mirrors the original devchacha-gunsmith's
-- lib.progressBar("Applying Components...") using this project's own
-- lp_progbar instead of ox_lib.
Config.ApplyProgress = {
    duration = 3000,
    label = 'กำลังปรับแต่งอาวุธ...',
    -- animation played on the player WHILE the apply bar runs (lp_progbar handles it).
    -- animDict/anim: a looping working pose; flags 1 = loop. Swap for any RDR3 anim dict.
    animation = {
        animDict = 'amb_work@world_human_hammering@male_a@idle_a',
        anim     = 'idle_a',
        flags    = 1,
    },
}

-- ── Camera preview ──────────────────────────────────────────────────────
-- The weapon spawns as a floating object at the current station's own `anchor`
-- (NOT at the player's position) and the camera is placed relative to that
-- anchor, so the framing is identical for everyone and never depends on where
-- the player is standing. Each player gets their own parallel lane
-- (anchor.x + serverId*laneSpacing) so two people at the same station never
-- overlap even if the object ends up networked. While previewing, the player's
-- own ped is frozen + made invincible (they're visually "away" at the void).
Config.Camera = {
    laneSpacing = 0.0,         -- metres between each player's preview slot at a station
    distBack    = 1.0,        -- camera distance from the gun (raise if long guns get cropped)
    distSide    = 0.0,
    distUp      = 0.08,
    fov         = 40.0,
    turntableDegPerSec = 35.0, -- gun spins in place, no manual rotate input (keeps menu keys free)
}

Config.Text = {
    NotNearStation = 'ต้องอยู่ใกล้โต๊ะช่างปืนก่อน',
    NoWeapon = 'ไม่มีอาวุธที่ปรับแต่งได้',
    NotOwned = 'อาวุธนี้ไม่ใช่ของคุณ',
    NoMoney = 'เงินสดไม่พอ',
    Busy = 'กำลังดำเนินการอยู่ กรุณารอสักครู่',
    AlreadyEquipped = 'ติดตั้งชิ้นส่วนนี้อยู่แล้ว',
    Applied = 'ปรับแต่งอาวุธเรียบร้อย',
    Removed = 'ถอดชิ้นส่วนเรียบร้อย',
    InvalidComponent = 'ชิ้นส่วนนี้ใช้กับอาวุธนี้ไม่ได้',
    Error = 'เกิดข้อผิดพลาด กรุณาลองใหม่',
}

-- ── Component catalog ────────────────────────────────────────────────────
-- Ported from the RSG "devchacha-gunsmith" resource's Config.SpecificComponents
-- (github.com/Devchacha01/devchacha-gunsmith) — these are plain RDR3 native
-- component hash-name constants, framework-agnostic. Only weapons that are
-- actually sold by nx_shop or produced by nx_crafting Tier 1-10 AND that
-- genuinely have RDR3 component slots are included; melee/thrown/bow
-- weapons in this project's catalog (hatchet, machete, tomahawk, base bow)
-- have no RDR3 component slots and were intentionally left out.
Config.Components = {
    -- nx_shop starter weapons
    ['WEAPON_REVOLVER_CATTLEMAN'] = {
        BARREL = {
            'COMPONENT_REVOLVER_CATTLEMAN_BARREL_SHORT',
            'COMPONENT_REVOLVER_CATTLEMAN_BARREL_LONG',
            'COMPONENT_REVOLVER_CATTLEMAN_BARREL_LEGENDARY',
        },
        GRIP = {
            'COMPONENT_REVOLVER_CATTLEMAN_GRIP',
            'COMPONENT_REVOLVER_CATTLEMAN_GRIP_PEARL',
            'COMPONENT_REVOLVER_CATTLEMAN_GRIP_EBONY',
            'COMPONENT_REVOLVER_CATTLEMAN_GRIP_IRONWOOD',
            'COMPONENT_REVOLVER_CATTLEMAN_GRIP_GOOD_HONOR',
            'COMPONENT_REVOLVER_CATTLEMAN_GRIP_BURLED',
            'COMPONENT_REVOLVER_CATTLEMAN_GRIP_LEGENDARY',
        },
        SIGHT = {
            'COMPONENT_REVOLVER_CATTLEMAN_SIGHT_NARROW',
            'COMPONENT_REVOLVER_CATTLEMAN_SIGHT_WIDE',
        },
    },
    ['WEAPON_RIFLE_VARMINT'] = {
        GRIP = {
            'COMPONENT_RIFLE_VARMINT_GRIP',
            'COMPONENT_RIFLE_VARMINT_GRIP_ENGRAVED',
            'COMPONENT_RIFLE_VARMINT_GRIP_IRONWOOD',
            'COMPONENT_RIFLE_VARMINT_GRIP_NATURALIST',
            'COMPONENT_RIFLE_VARMINT_GRIP_BURLED',
        },
        SIGHT = {
            'COMPONENT_REPEATER_PUMPACTION_SIGHT_NARROW',
            'COMPONENT_REPEATER_PUMPACTION_SIGHT_WIDE',
            'COMPONENT_RIFLE_VARMINT_SIGHT_NATURALIST',
        },
        CLIP = {
            'COMPONENT_RIFLE_VARMINT_CLIP',
            'COMPONENT_RIFLE_VARMINT_CLIP_ENGRAVED',
            'COMPONENT_RIFLE_VARMINT_CLIP_IRONWOOD',
            'COMPONENT_RIFLE_VARMINT_CLIP_NATURALIST',
            'COMPONENT_RIFLE_VARMINT_CLIP_BURLED',
        },
        WRAP = {
            'COMPONENT_RIFLE_VARMINT_WRAP1',
            'COMPONENT_RIFLE_VARMINT_WRAP2',
            'COMPONENT_RIFLE_VARMINT_WRAP3',
            'COMPONENT_RIFLE_VARMINT_WRAP4',
            'COMPONENT_RIFLE_VARMINT_WRAP5',
            'COMPONENT_RIFLE_VARMINT_WRAP6',
        },
        SCOPE = {
            'COMPONENT_RIFLE_SCOPE02',
            'COMPONENT_RIFLE_SCOPE03',
        },
    },
    ['WEAPON_MELEE_KNIFE'] = {
        GRIP = {
            'COMPONENT_MELEE_KNIFE02_GRIP',
            'COMPONENT_MELEE_KNIFE13_GRIP',
        },
    },

    -- nx_crafting Tier weapons (Phase 1 — see config_sv.lua Category [9]-[18])
    ['WEAPON_PISTOL_MAUSER'] = {
        BARREL = {
            'COMPONENT_PISTOL_MAUSER_BARREL_SHORT',
            'COMPONENT_PISTOL_MAUSER_BARREL_LONG',
            'COMPONENT_PISTOL_MAUSER_BARREL_AZTEC',
        },
        GRIP = {
            'COMPONENT_PISTOL_MAUSER_GRIP',
            'COMPONENT_PISTOL_MAUSER_GRIP_PEARL',
            'COMPONENT_PISTOL_MAUSER_GRIP_EBONY',
            'COMPONENT_PISTOL_MAUSER_GRIP_IRONWOOD',
            'COMPONENT_PISTOL_MAUSER_GRIP_BURLED',
            'COMPONENT_PISTOL_MAUSER_GRIP_AZTEC',
        },
        SIGHT = {
            'COMPONENT_PISTOL_MAUSER_SIGHT_NARROW',
            'COMPONENT_PISTOL_MAUSER_SIGHT_WIDE',
        },
        CLIP = {
            'COMPONENT_PISTOL_MAUSER_CLIP',
            'COMPONENT_PISTOL_MAUSER_CLIP_EMPTY',
        },
    },
    ['WEAPON_REVOLVER_SCHOFIELD'] = {
        BARREL = {
            'COMPONENT_REVOLVER_SCHOFIELD_BARREL_SHORT',
            'COMPONENT_REVOLVER_SCHOFIELD_BARREL_LONG',
            'COMPONENT_REVOLVER_SCHOFIELD_BARREL_BOUNTY',
        },
        GRIP = {
            'COMPONENT_REVOLVER_SCHOFIELD_GRIP',
            'COMPONENT_REVOLVER_SCHOFIELD_GRIP_PEARL',
            'COMPONENT_REVOLVER_SCHOFIELD_GRIP_IRONWOOD',
            'COMPONENT_REVOLVER_SCHOFIELD_GRIP_EBONY',
            'COMPONENT_REVOLVER_SCHOFIELD_GRIP_BOUNTY',
            'COMPONENT_REVOLVER_SCHOFIELD_GRIP_BURLED',
        },
        SIGHT = {
            'COMPONENT_REVOLVER_SCHOFIELD_SIGHT_NARROW',
            'COMPONENT_REVOLVER_SCHOFIELD_SIGHT_WIDE',
            'COMPONENT_REVOLVER_SCHOFIELD_SIGHT_BOUNTY',
        },
    },
    ['WEAPON_REPEATER_CARBINE'] = {
        GRIP = {
            'COMPONENT_REPEATER_CARBINE_GRIP',
            'COMPONENT_REPEATER_CARBINE_GRIP_IRONWOOD',
            'COMPONENT_REPEATER_CARBINE_GRIP_ENGRAVED',
            'COMPONENT_REPEATER_CARBINE_GRIP_BURLED',
        },
        SIGHT = {
            'COMPONENT_REPEATER_CARBINE_SIGHT_NARROW',
            'COMPONENT_REPEATER_CARBINE_SIGHT_WIDE',
        },
        CLIP = {
            'COMPONENT_REPEATER_CARBINE_CLIP',
        },
        TUBE = {
            'COMPONENT_REPEATER_CARBINE_TUBE',
        },
        WRAP = {
            'COMPONENT_REPEATER_CARBINE_WRAP1',
            'COMPONENT_REPEATER_CARBINE_WRAP2',
            'COMPONENT_REPEATER_CARBINE_WRAP3',
            'COMPONENT_REPEATER_CARBINE_WRAP4',
            'COMPONENT_REPEATER_CARBINE_WRAP5',
            'COMPONENT_REPEATER_CARBINE_WRAP6',
        },
    },
    ['WEAPON_REPEATER_HENRY'] = {
        GRIP = {
            'COMPONENT_REPEATER_HENRY_GRIP',
            'COMPONENT_REPEATER_HENRY_GRIP_IRONWOOD',
            'COMPONENT_REPEATER_HENRY_GRIP_ENGRAVED',
            'COMPONENT_REPEATER_HENRY_GRIP_BURLED',
        },
        SIGHT = {
            'COMPONENT_REPEATER_HENRY_SIGHT_NARROW',
            'COMPONENT_REPEATER_HENRY_SIGHT_WIDE',
        },
        WRAP = {
            'COMPONENT_REPEATER_HENRY_WRAP1',
            'COMPONENT_REPEATER_HENRY_WRAP2',
            'COMPONENT_REPEATER_HENRY_WRAP3',
            'COMPONENT_REPEATER_HENRY_WRAP4',
            'COMPONENT_REPEATER_HENRY_WRAP5',
            'COMPONENT_REPEATER_HENRY_WRAP6',
        },
    },
    ['WEAPON_PISTOL_SEMIAUTO'] = {
        BARREL = {
            'COMPONENT_PISTOL_SEMIAUTO_BARREL_SHORT',
            'COMPONENT_PISTOL_SEMIAUTO_BARREL_LONG',
        },
        GRIP = {
            'COMPONENT_PISTOL_SEMIAUTO_GRIP',
            'COMPONENT_PISTOL_SEMIAUTO_GRIP_PEARL',
            'COMPONENT_PISTOL_SEMIAUTO_GRIP_IRONWOOD',
            'COMPONENT_PISTOL_SEMIAUTO_GRIP_EBONY',
            'COMPONENT_PISTOL_SEMIAUTO_GRIP_BURLED',
        },
        SIGHT = {
            'COMPONENT_PISTOL_SEMIAUTO_SIGHT_NARROW',
            'COMPONENT_PISTOL_SEMIAUTO_SIGHT_WIDE',
        },
        CLIP = {
            'COMPONENT_PISTOL_SEMIAUTO_CLIP',
        },
    },
    ['WEAPON_REPEATER_WINCHESTER'] = {
        GRIP = {
            'COMPONENT_REPEATER_WINCHESTER_GRIP',
            'COMPONENT_REPEATER_WINCHESTER_GRIP_IRONWOOD',
            'COMPONENT_REPEATER_WINCHESTER_GRIP_ENGRAVED',
            'COMPONENT_REPEATER_WINCHESTER_GRIP_COLLECTOR',
            'COMPONENT_REPEATER_WINCHESTER_GRIP_BURLED',
        },
        SIGHT = {
            'COMPONENT_REPEATER_WINCHESTER_SIGHT_NARROW',
            'COMPONENT_REPEATER_WINCHESTER_SIGHT_WIDE',
        },
        WRAP = {
            'COMPONENT_REPEATER_WINCHESTER_WRAP1',
            'COMPONENT_REPEATER_WINCHESTER_WRAP2',
            'COMPONENT_REPEATER_WINCHESTER_WRAP3',
            'COMPONENT_REPEATER_WINCHESTER_WRAP4',
            'COMPONENT_REPEATER_WINCHESTER_WRAP5',
            'COMPONENT_REPEATER_WINCHESTER_WRAP6',
            'COMPONENT_REPEATER_WINCHESTER_WRAP_COLLECTOR',
        },
    },
    ['WEAPON_REVOLVER_NAVY'] = {
        BARREL = {
            'COMPONENT_REVOLVER_NAVY_BARREL_SHORT',
            'COMPONENT_REVOLVER_NAVY_BARREL_LONG',
            'COMPONENT_REVOLVER_NAVY_BARREL_CROSSOVER',
        },
        GRIP = {
            'COMPONENT_REVOLVER_NAVY_GRIP',
            'COMPONENT_REVOLVER_NAVY_GRIP_IRONWOOD',
            'COMPONENT_REVOLVER_NAVY_GRIP_PEARL',
            'COMPONENT_REVOLVER_NAVY_GRIP_EBONY',
            'COMPONENT_REVOLVER_NAVY_GRIP_CROSSOVER',
        },
        SIGHT = {
            'COMPONENT_REVOLVER_NAVY_SIGHT_NARROW',
            'COMPONENT_REVOLVER_NAVY_SIGHT_WIDE',
            'COMPONENT_REVOLVER_NAVY_SIGHT_CROSSOVER',
        },
    },
    ['WEAPON_SHOTGUN_DOUBLEBARREL'] = {
        BARREL = {
            'COMPONENT_SHOTGUN_DOUBLEBARREL_BARREL_SHORT',
            'COMPONENT_SHOTGUN_DOUBLEBARREL_BARREL_LONG',
            'COMPONENT_SHOTGUN_DOUBLEBARREL_BARREL_KRAMPUS',
        },
        GRIP = {
            'COMPONENT_SHOTGUN_DOUBLEBARREL_GRIP',
            'COMPONENT_SHOTGUN_DOUBLEBARREL_GRIP_IRONWOOD',
            'COMPONENT_SHOTGUN_DOUBLEBARREL_GRIP_ENGRAVED',
            'COMPONENT_SHOTGUN_DOUBLEBARREL_GRIP_BURLED',
        },
        SIGHT = {
            'COMPONENT_SHOTGUN_DOUBLEBARREL_SIGHT_NARROW',
            'COMPONENT_SHOTGUN_DOUBLEBARREL_SIGHT_WIDE',
        },
        WRAP = {
            'COMPONENT_SHOTGUN_DOUBLEBARREL_WRAP1',
            'COMPONENT_SHOTGUN_DOUBLEBARREL_WRAP2',
            'COMPONENT_SHOTGUN_DOUBLEBARREL_WRAP3',
            'COMPONENT_SHOTGUN_DOUBLEBARREL_WRAP4',
            'COMPONENT_SHOTGUN_DOUBLEBARREL_WRAP5',
            'COMPONENT_SHOTGUN_DOUBLEBARREL_WRAP6',
        },
        MAG = {
            'COMPONENT_SHOTGUN_DOUBLEBARREL_MAG',
            'COMPONENT_SHOTGUN_DOUBLEBARREL_MAG_IRONWOOD',
            'COMPONENT_SHOTGUN_DOUBLEBARREL_MAG_ENGRAVED',
            'COMPONENT_SHOTGUN_DOUBLEBARREL_MAG_EXOTIC',
            'COMPONENT_SHOTGUN_DOUBLEBARREL_MAG_KRAMPUS',
            'COMPONENT_SHOTGUN_DOUBLEBARREL_MAG_BURLED',
        },
    },
    ['WEAPON_RIFLE_SPRINGFIELD'] = {
        GRIP = {
            'COMPONENT_RIFLE_SPRINGFIELD_GRIP',
            'COMPONENT_RIFLE_SPRINGFIELD_GRIP_IRONWOOD',
            'COMPONENT_RIFLE_SPRINGFIELD_GRIP_ENGRAVED',
            'COMPONENT_RIFLE_SPRINGFIELD_GRIP_BURLED',
        },
        SIGHT = {
            'COMPONENT_RIFLE_SPRINGFIELD_SIGHT_NARROW',
            'COMPONENT_RIFLE_SPRINGFIELD_SIGHT_WIDE',
        },
        WRAP = {
            'COMPONENT_RIFLE_SPRINGFIELD_WRAP1',
            'COMPONENT_RIFLE_SPRINGFIELD_WRAP2',
            'COMPONENT_RIFLE_SPRINGFIELD_WRAP3',
            'COMPONENT_RIFLE_SPRINGFIELD_WRAP4',
            'COMPONENT_RIFLE_SPRINGFIELD_WRAP5',
            'COMPONENT_RIFLE_SPRINGFIELD_WRAP6',
        },
        SCOPE = {
            'COMPONENT_RIFLE_SCOPE02',
            'COMPONENT_RIFLE_SCOPE03',
        },
    },
    ['WEAPON_PISTOL_VOLCANIC'] = {
        BARREL = {
            'COMPONENT_PISTOL_VOLCANIC_BARREL_SHORT',
            'COMPONENT_PISTOL_VOLCANIC_BARREL_LONG',
            'COMPONENT_PISTOL_VOLCANIC_BARREL_COLLECTOR',
        },
        GRIP = {
            'COMPONENT_PISTOL_VOLCANIC_GRIP',
            'COMPONENT_PISTOL_VOLCANIC_GRIP_PEARL',
            'COMPONENT_PISTOL_VOLCANIC_GRIP_EBONY',
            'COMPONENT_PISTOL_VOLCANIC_GRIP_IRONWOOD',
            'COMPONENT_PISTOL_VOLCANIC_GRIP_COLLECTOR',
            'COMPONENT_PISTOL_VOLCANIC_GRIP_BURLED',
        },
        SIGHT = {
            'COMPONENT_PISTOL_VOLCANIC_SIGHT_NARROW',
            'COMPONENT_PISTOL_VOLCANIC_SIGHT_WIDE',
            'COMPONENT_PISTOL_VOLCANIC_SIGHT_COLLECTOR',
        },
    },
    ['WEAPON_REVOLVER_LEMAT'] = {
        BARREL = {
            'COMPONENT_REVOLVER_LEMAT_BARREL_SHORT',
            'COMPONENT_REVOLVER_LEMAT_BARREL_LONG',
        },
        GRIP = {
            'COMPONENT_REVOLVER_LEMAT_GRIP',
            'COMPONENT_REVOLVER_LEMAT_GRIP_PEARL',
            'COMPONENT_REVOLVER_LEMAT_GRIP_EBONY',
            'COMPONENT_REVOLVER_LEMAT_GRIP_IRONWOOD',
        },
        SIGHT = {
            'COMPONENT_REVOLVER_LEMAT_SIGHT_NARROW',
            'COMPONENT_REVOLVER_LEMAT_SIGHT_WIDE',
        },
    },
    ['WEAPON_SHOTGUN_REPEATING'] = {
        BARREL = {
            'COMPONENT_SHOTGUN_REPEATING_BARREL_SHORT',
            'COMPONENT_SHOTGUN_REPEATING_BARREL_LONG',
        },
        GRIP = {
            'COMPONENT_SHOTGUN_REPEATING01_GRIP',
            'COMPONENT_SHOTGUN_REPEATING01_GRIP_IRONWOOD',
            'COMPONENT_SHOTGUN_REPEATING01_GRIP_ENGRAVED',
            'COMPONENT_SHOTGUN_REPEATING_GRIP_BURLED',
        },
        SIGHT = {
            'COMPONENT_SHOTGUN_REPEATING_SIGHT_NARROW',
            'COMPONENT_SHOTGUN_REPEATING_SIGHT_WIDE',
        },
        WRAP = {
            'COMPONENT_SHOTGUN_REPEATING01_WRAP1',
            'COMPONENT_SHOTGUN_REPEATING01_WRAP2',
            'COMPONENT_SHOTGUN_REPEATING_WRAP3',
            'COMPONENT_SHOTGUN_REPEATING_WRAP4',
            'COMPONENT_SHOTGUN_REPEATING_WRAP5',
            'COMPONENT_SHOTGUN_REPEATING_WRAP6',
        },
    },
    ['WEAPON_PISTOL_M1899'] = {
        BARREL = {
            'COMPONENT_PISTOL_M1899_BARREL_SHORT',
            'COMPONENT_PISTOL_M1899_BARREL_LONG',
        },
        CLIP = {
            'COMPONENT_PISTOL_M1899_CLIP',
        },
        GRIP = {
            'COMPONENT_PISTOL_M1899_GRIP',
            'COMPONENT_PISTOL_M1899_GRIP_IRONWOOD',
            'COMPONENT_PISTOL_M1899_GRIP_PEARL',
            'COMPONENT_PISTOL_M1899_GRIP_EBONY',
        },
        SIGHT = {
            'COMPONENT_PISTOL_M1899_SIGHT_NARROW',
            'COMPONENT_PISTOL_M1899_SIGHT_WIDE',
        },
    },
    ['WEAPON_REPEATER_EVANS'] = {
        GRIP = {
            'COMPONENT_REPEATER_EVANS_GRIP',
            'COMPONENT_REPEATER_EVANS_GRIP_IRONWOOD',
            'COMPONENT_REPEATER_EVANS_GRIP_ENGRAVED',
            'COMPONENT_REPEATER_EVANS_GRIP_BURLED',
            'COMPONENT_REPEATER_EVANS_GRIP_WINTER',
        },
        SIGHT = {
            'COMPONENT_REPEATER_EVANS_SIGHT_NARROW',
            'COMPONENT_REPEATER_EVANS_SIGHT_WIDE',
        },
        WRAP = {
            'COMPONENT_REPEATER_EVANS_WRAP',
            'COMPONENT_REPEATER_EVANS_WRAP2',
            'COMPONENT_REPEATER_EVANS_WRAP3',
            'COMPONENT_REPEATER_EVANS_WRAP4',
            'COMPONENT_REPEATER_EVANS_WRAP5',
            'COMPONENT_REPEATER_EVANS_WRAP6',
            'COMPONENT_REPEATER_EVANS_WRAP_WINTER',
        },
    },
    ['WEAPON_RIFLE_BOLTACTION'] = {
        GRIP = {
            'COMPONENT_RIFLE_BOLTACTION_GRIP',
            'COMPONENT_RIFLE_BOLTACTION_GRIP_IRONWOOD',
            'COMPONENT_RIFLE_BOLTACTION_GRIP_ENGRAVED',
            'COMPONENT_RIFLE_BOLTACTION_GRIP_BOUNTY',
            'COMPONENT_RIFLE_BOLTACTION_GRIP_BURLED',
        },
        SIGHT = {
            'COMPONENT_RIFLE_BOLTACTION_SIGHT_WIDE',
            'COMPONENT_RIFLE_BOLTACTION_SIGHT_NARROW',
        },
        WRAP = {
            'COMPONENT_RIFLE_BOLTACTION_WRAP',
            'COMPONENT_RIFLE_BOLTACTION_WRAP2',
            'COMPONENT_RIFLE_BOLTACTION_WRAP3',
            'COMPONENT_RIFLE_BOLTACTION_WRAP4',
            'COMPONENT_RIFLE_BOLTACTION_WRAP5',
            'COMPONENT_RIFLE_BOLTACTION_WRAP6',
        },
        SCOPE = {
            'COMPONENT_RIFLE_SCOPE02',
            'COMPONENT_RIFLE_SCOPE03',
        },
    },
    ['WEAPON_SNIPERRIFLE_ROLLINGBLOCK'] = {
        GRIP = {
            'COMPONENT_SNIPERRIFLE_ROLLINGBLOCK_GRIP',
            'COMPONENT_SNIPERRIFLE_ROLLINGBLOCK_GRIP_EXOTIC',
            'COMPONENT_SNIPERRIFLE_ROLLINGBLOCK_GRIP_IRONWOOD',
            'COMPONENT_SNIPERRIFLE_ROLLINGBLOCK_GRIP_ENGRAVED',
            'COMPONENT_SNIPERRIFLE_ROLLINGBLOCK_GRIP_REAPER',
            'COMPONENT_SNIPERRIFLE_ROLLINGBLOCK_GRIP_BURLED',
        },
        SIGHT = {
            'COMPONENT_RIFLE_ROLLINGBLOCK_SIGHT_NARROW',
            'COMPONENT_RIFLE_ROLLINGBLOCK_SIGHT_WIDE',
        },
        WRAP = {
            'COMPONENT_RIFLE_ROLLINGBLOCK_WRAP1',
            'COMPONENT_RIFLE_ROLLINGBLOCK_WRAP2',
            'COMPONENT_RIFLE_ROLLINGBLOCK_WRAP3',
            'COMPONENT_RIFLE_ROLLINGBLOCK_WRAP4',
            'COMPONENT_RIFLE_ROLLINGBLOCK_WRAP5',
            'COMPONENT_RIFLE_ROLLINGBLOCK_WRAP6',
        },
        SCOPE = {
            'COMPONENT_RIFLE_SCOPE02',
            'COMPONENT_RIFLE_SCOPE03',
        },
    },
    ['WEAPON_SHOTGUN_PUMP'] = {
        BARREL = {
            'COMPONENT_SHOTGUN_PUMP_BARREL_SHORT',
            'COMPONENT_SHOTGUN_PUMP_BARREL_LONG',
            'COMPONENT_SHOTGUN_PUMP_BARREL_HALLOWEEN',
        },
        GRIP = {
            'COMPONENT_SHOTGUN_PUMP_GRIP',
            'COMPONENT_SHOTGUN_PUMP_GRIP_IRONWOOD',
            'COMPONENT_SHOTGUN_PUMP_GRIP_ENGRAVED',
            'COMPONENT_SHOTGUN_PUMP_GRIP_TRADER',
            'COMPONENT_SHOTGUN_PUMP_GRIP_BURLED',
            'COMPONENT_SHOTGUN_PUMP_GRIP_HALLOWEEN',
        },
        SIGHT = {
            'COMPONENT_SHOTGUN_PUMP_SIGHT_NARROW',
            'COMPONENT_SHOTGUN_PUMP_SIGHT_WIDE',
        },
        CLIP = {
            'COMPONENT_SHOTGUN_PUMP_CLIP',
            'COMPONENT_SHOTGUN_PUMP_CLIP_IRONWOOD',
            'COMPONENT_SHOTGUN_PUMP_CLIP_ENGRAVED',
            'COMPONENT_SHOTGUN_PUMP_CLIP_TRADER',
            'COMPONENT_SHOTGUN_PUMP_CLIP_BURLED',
            'COMPONENT_SHOTGUN_PUMP_CLIP_HALLOWEEN',
        },
        WRAP = {
            'COMPONENT_SHOTGUN_PUMP_WRAP1',
            'COMPONENT_SHOTGUN_PUMP_WRAP2',
            'COMPONENT_SHOTGUN_PUMP_WRAP3',
            'COMPONENT_SHOTGUN_PUMP_WRAP4',
            'COMPONENT_SHOTGUN_PUMP_WRAP5',
            'COMPONENT_SHOTGUN_PUMP_WRAP6',
        },
    },
    ['WEAPON_SHOTGUN_SAWEDOFF'] = {
        GRIP = {
            'COMPONENT_SHOTGUN_SAWEDOFF_GRIP',
            'COMPONENT_SHOTGUN_SAWEDOFF_GRIP_IRONWOOD',
            'COMPONENT_SHOTGUN_SAWEDOFF_GRIP_EBONY',
            'COMPONENT_SHOTGUN_SAWEDOFF_GRIP_MOONSHINER',
            'COMPONENT_SHOTGUN_SAWEDOFF_GRIP_BURLED',
        },
        SIGHT = {
            'COMPONENT_SHOTGUN_SAWED_SIGHT_NARROW',
            'COMPONENT_SHOTGUN_SAWED_SIGHT_WIDE',
            'COMPONENT_SHOTGUN_SAWED_SIGHT_MOONSHINER',
        },
        WRAP = {
            'COMPONENT_SHOTGUN_SAWEDOFF_WRAP1',
            'COMPONENT_SHOTGUN_SAWEDOFF_WRAP2',
            'COMPONENT_SHOTGUN_SAWEDOFF_WRAP3',
            'COMPONENT_SHOTGUN_SAWEDOFF_WRAP4',
            'COMPONENT_SHOTGUN_SAWEDOFF_WRAP5',
        },
        STOCK = {
            'COMPONENT_SHOTGUN_SAWEDOFF_STOCK',
            'COMPONENT_SHOTGUN_SAWEDOFF_STOCK_IRONWOOD',
            'COMPONENT_SHOTGUN_SAWEDOFF_STOCK_EBONY',
            'COMPONENT_SHOTGUN_SAWEDOFF_STOCK_MOONSHINER',
            'COMPONENT_SHOTGUN_SAWEDOFF_STOCK_BURLED',
        },
    },
    ['WEAPON_SHOTGUN_SEMIAUTO'] = {
        BARREL = {
            'COMPONENT_SHOTGUN_SEMIAUTO_BARREL_SHORT',
            'COMPONENT_SHOTGUN_SEMIAUTO_BARREL_LONG',
        },
        GRIP = {
            'COMPONENT_SHOTGUN_SEMIAUTO_GRIP',
            'COMPONENT_SHOTGUN_SEMIAUTO_GRIP_IRONWOOD',
            'COMPONENT_SHOTGUN_SEMIAUTO_GRIP_ENGRAVED',
            'COMPONENT_SHOTGUN_SEMIAUTO_GRIP_BURLED',
        },
        SIGHT = {
            'COMPONENT_SHOTGUN_SEMIAUTO_SIGHT_NARROW',
            'COMPONENT_SHOTGUN_SEMIAUTO_SIGHT_WIDE',
        },
        WRAP = {
            'COMPONENT_SHOTGUN_SEMIAUTO_WRAP1',
            'COMPONENT_SHOTGUN_SEMIAUTO_WRAP2',
            'COMPONENT_SHOTGUN_SEMIAUTO_WRAP3',
            'COMPONENT_SHOTGUN_SEMIAUTO_WRAP4',
            'COMPONENT_SHOTGUN_SEMIAUTO_WRAP5',
            'COMPONENT_SHOTGUN_SEMIAUTO_WRAP6',
        },
    },
}

-- Friendly Thai labels for slot keys (menu display only)
Config.SlotLabels = {
    BARREL = 'ลำกล้อง',
    GRIP = 'ด้ามจับ',
    SIGHT = 'ศูนย์เล็ง',
    CLIP = 'แม็กกาซีน',
    TUBE = 'ท่อกระสุน',
    WRAP = 'ผ้าพันด้าม',
    SCOPE = 'กล้องส่อง',
    MAG = 'แม็กกาซีน',
    STOCK = 'พานท้าย',
}

-- Structural slots the weapon can't render without (removing e.g. the barrel
-- leaves a broken, muzzle-less gun). These get no "remove" option, and when a
-- weapon is rebuilt on the ped, any essential slot the player left empty falls
-- back to its first (default) component so the gun is never "naked".
-- Matches the original devchacha-gunsmith essential-category list.
Config.EssentialSlots = {
    BARREL   = true,
    GRIP     = true,
    CYLINDER = true,
    FRAME    = true,
    CLIP     = true,
    MAG      = true,
    STOCK    = true,
}
