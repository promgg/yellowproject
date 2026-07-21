Config = {}

-- ─────────────────────────────────────────────────────────────
--  GENERAL SETTINGS
-- ─────────────────────────────────────────────────────────────
Config.MaxPlayersPerCity = 20       -- max registered citizens per city per cycle
Config.SpawnFreezeTime   = 3000     -- ms to wait after spawn before showing UI
-- ท่าจัดเสื้อตอนสลับ/ถอดโค้ท (แทนการเฟดจอดำ)
-- ท่า adjust_belt เป็น full-body จัดเข็มขัด/เสื้อ ยกจาก jo_radial_clotheswheel ที่ใช้กับหมวด coats
Config.OutfitAnim = {
    dict     = "script_respawn@one_shot@fullbody@generic@unarmed@stand_adjust_belt@a",
    anim     = "respawn_action",
    flag     = 24,
    duration = 1000,  -- ความยาวท่า (ms)
    swapAt   = 450,   -- สลับ/ถอดโค้ทตอนกี่ ms (รอให้มือขยับขึ้นก่อน ซ่อนจังหวะ swap)
}
-- หมวดเสื้อผ้าที่บัตรประจำเมืองจะเปลี่ยน — ค่าเดิมคือ "Shirt" แต่เสื้อเชิ้ตชั้นในโดนโค้ททับ
-- มองไม่เห็น จึงเปลี่ยนเป็น "Coat" ให้เห็นผลจริง (ชื่อหมวดต้องตรงกับ metaPedCategoryTags
-- ของ vorp_character เช่น Coat / Shirt / Vest / Hat)
Config.OutfitCategory    = "Coat"
Config.Debug             = false    -- set true to see zone debug polys
Config.ShowTerritoryHUD  = false     -- false = ปิดป้ายชื่อเมือง (จุดแดง + ชื่อเมือง) ที่โผล่ตอนเดินเข้า/ออกโซนเมือง

-- ─────────────────────────────────────────────────────────────
--  CITIES
--  spawnPoint : where the player teleports after selecting
--  color      : {r,g,b,a} used for territory minimap blips (0-255)
--  badgeItem  : item name in DB for this city's badge
--  zones      : polygon points {x,y} that define city territory
--  minZ/maxZ  : Z-axis range for PolyZone
--  outfitTag  : RDR2 MetaPed tag { drawable, albedo, normal, material, palette, tint0, tint1, tint2 }
--               ของหมวด Config.OutfitCategory (ตอนนี้ = "Coat")
--               วิธีเก็บค่า: ตั้ง Config.Debug = true → ใส่โค้ทที่อยากได้ในร้านตัดเสื้อ
--               (เช่น Irwin Coat variation 9) → พิมพ์ /nxcapture ในเกม → ก๊อปบรรทัด
--               outfitTag = {...} ที่ปรินต์ออกมา มาวางทับของเมืองนั้น
--               ⚠️ ค่าด้านล่างยังเป็น hash ของ "เสื้อเชิ้ต" เดิม ต้อง capture โค้ทใหม่มาแทน
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
        outfitTag = {
            male   = { drawable = -2039557141, albedo = 1054177455, normal = 1553188703, material = -1784791249, palette = 1669565057, tint0 = 19, tint1 = 6, tint2 = 108 },
            female = { drawable = -1023318859, albedo = 1054177455, normal = 1553188703, material = -1784791249, palette = 1669565057, tint0 = 19, tint1 = 6, tint2 = 108 },
        },
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
        outfitTag = {
            male   = { drawable = -2039557141, albedo = 1054177455, normal = 1553188703, material = -1784791249, palette = 864404955, tint0 = 77, tint1 = 248, tint2 = 249 },
            female = { drawable = -1023318859, albedo = 1054177455, normal = 1553188703, material = -1784791249, palette = 864404955, tint0 = 77, tint1 = 248, tint2 = 249 },
        },
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
        outfitTag = {
            male   = { drawable = -2039557141, albedo = 1054177455, normal = 1553188703, material = -1784791249, palette = -783849117, tint0 = 0, tint1 = 0, tint2 = 8 },
            female = { drawable = -1023318859, albedo = 1054177455, normal = 1553188703, material = -1784791249, palette = -783849117, tint0 = 0, tint1 = 0, tint2 = 8 },
        },
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
