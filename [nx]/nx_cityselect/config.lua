Config = {}

-- ─────────────────────────────────────────────────────────────
--  GENERAL SETTINGS
-- ─────────────────────────────────────────────────────────────
Config.MaxPlayersPerCity = 20       -- max registered citizens per city per cycle
Config.SpawnFreezeTime   = 3000     -- ms to wait after spawn before showing UI
Config.OutfitFadeTime    = 500      -- ms for fade-to-black when changing outfit
Config.Debug             = false    -- set true to see zone debug polys

-- ─────────────────────────────────────────────────────────────
--  CITIES
--  spawnPoint : where the player teleports after selecting
--  color      : {r,g,b,a} used for territory minimap blips (0-255)
--  badgeItem  : item name in DB for this city's badge
--  zones      : polygon points {x,y} that define city territory
--  minZ/maxZ  : Z-axis range for PolyZone
--  shirtTag   : RDR2 MetaPed shirt tag { drawable, albedo, normal, material, palette, tint0, tint1, tint2 }
--               captured live via GetMetaPedData("Shirt", ped) — NOT a GTA5-style
--               component/drawable/texture/palette index, RDR2 clothing uses asset hashes
-- ─────────────────────────────────────────────────────────────
Config.Cities = {
    {
        id          = "valentine",
        name        = "Valentine",
        label       = "เมืองวาเลนไทน์",
        description = "เมืองปศุสัตว์แห่งนิวแฮนโนเวอร์ ศูนย์กลางการค้าและความเจริญ",
        color       = { r = 200, g = 60,  b = 60,  a = 40 },
        spawnPoint  = { x = -170.7112, y = 623.6540, z = 114.0321, heading = 228.4342 },
        badgeItem   = "badge_valentine",
        zones       = {
            vector2(-480.0,  940.0),
            vector2(-130.0,  940.0),
            vector2(-130.0,  600.0),
            vector2(-480.0,  600.0),
        },
        minZ   = 90.0,
        maxZ   = 160.0,
        shirtTag = { drawable = -677619227, albedo = -1749786428, normal = -551064659, material = 547019181, palette = 1064202495, tint0 = 0, tint1 = 0, tint2 = 0 },
        outfitProps = {},
    },
    {
        id          = "rhodes",
        name        = "Rhodes",
        label       = "เมืองโรดส์",
        description = "เมืองทางใต้แห่งเลมอยน์ ดินแดนของเกียรติยศและกฎหมาย",
        color       = { r = 60,  g = 180, b = 80,  a = 40 },
        spawnPoint  = { x = 1221.5322, y = -1302.0590, z = 76.8985, heading = 135.7318 },
        badgeItem   = "badge_rhodes",
        zones       = {
            vector2(1080.0, -1120.0),
            vector2(1420.0, -1120.0),
            vector2(1420.0, -1480.0),
            vector2(1080.0, -1480.0),
        },
        minZ   = 55.0,
        maxZ   = 110.0,
        shirtTag = { drawable = -677619227, albedo = -1749786428, normal = -551064659, material = 547019181, palette = -113397560, tint0 = 183, tint1 = 47, tint2 = 208 },
        outfitProps = {},
    },
    {
        id          = "annesburg",
        name        = "Annesburg",
        label       = "เมืองแอนเนสบูร์ก",
        description = "เมืองเหมืองถ่านหินทางตะวันออกของนิวแฮนโนเวอร์ ริม Roanoke Ridge",
        color       = { r = 50,  g = 100, b = 200, a = 40 },
        spawnPoint  = { x = 2926.5059, y = 1285.3009, z = 44.6548, heading = 68.1800 },
        badgeItem   = "badge_annesburg",
        zones       = {
            vector2(2800.0, 1490.0),
            vector2(3050.0, 1490.0),
            vector2(3050.0, 1130.0),
            vector2(2800.0, 1130.0),
        },
        minZ   = 20.0,
        maxZ   = 90.0,
        shirtTag = { drawable = -631954077, albedo = -1749786428, normal = -551064659, material = 547019181, palette = -113397560, tint0 = 139, tint1 = 18, tint2 = 15 },
        outfitProps = {},
    },
}

-- ─────────────────────────────────────────────────────────────
--  HERITAGES
--  Permanent crafting-lineage choice, shown right after city
--  selection. Job id must match the jobList keys nx_crafting
--  checks against (see [nx]/nx_crafting/config_sv.lua).
-- ─────────────────────────────────────────────────────────────
Config.Heritages = {
    {
        id          = "white",
        name        = "ผู้ตั้งถิ่นฐาน",
        label       = "White Settler",
        description = "สายช่างฝีมือของผู้ตั้งถิ่นฐานผิวขาว ปลดล็อกสูตรคราฟต์อาวุธปืน (Revolver / Carbine / Rifle) ที่แท่นตีเหล็ก",
    },
    {
        id          = "native",
        name        = "ชนพื้นเมือง",
        label       = "Native American",
        description = "สายช่างฝีมือของชนพื้นเมืองอเมริกัน ปลดล็อกสูตรคราฟต์อาวุธดั้งเดิม (ขวาน / ธนู / ลูกศรไฟ) ที่แท่นตีเหล็ก",
    },
}

-- ─────────────────────────────────────────────────────────────
--  QUICK LOOKUP: Config.CitiesById[cityId] = cityData
--  Built at runtime in shared/sh_utils.lua
-- ─────────────────────────────────────────────────────────────
Config.CitiesById = {}
Config.HeritagesById = {}
