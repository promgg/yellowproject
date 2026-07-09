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
--  outfit     : list of {componentId, drawableId, textureId, paletteId}
--               Use -1 on any field to skip that component
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
        outfit = {
            -- { componentId, drawableId, textureId, paletteId }
            { 11, 5,  0, 0 },   -- upper body / shirt
            { 4,  3,  0, 0 },   -- lower body / pants
            { 6,  2,  0, 0 },   -- feet / boots
            { 0,  0,  0, 0 },   -- head (hat handled via prop)
        },
        outfitProps = {
            -- { propId, drawableId, textureId }
            { 0, 8, 0 },    -- hat
        },
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
        outfit = {
            { 11, 20, 0, 0 },
            { 4,  15, 0, 0 },
            { 6,  8,  0, 0 },
            { 0,  0,  0, 0 },
        },
        outfitProps = {
            { 0, 12, 0 },
        },
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
        outfit = {
            { 11, 12, 0, 0 },
            { 4,  8,  0, 0 },
            { 6,  5,  0, 0 },
            { 0,  0,  0, 0 },
        },
        outfitProps = {
            { 0, 4, 0 },
        },
    },
}

-- ─────────────────────────────────────────────────────────────
--  QUICK LOOKUP: Config.CitiesById[cityId] = cityData
--  Built at runtime in shared/sh_utils.lua
-- ─────────────────────────────────────────────────────────────
Config.CitiesById = {}
