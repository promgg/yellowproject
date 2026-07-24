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
Config.Debug             = false    -- set true to see zone debug polys (+ เปิดคำสั่ง /nxcapture)
Config.ShowTerritoryHUD  = false     -- false = ปิดป้ายชื่อเมือง (จุดแดง + ชื่อเมือง) ที่โผล่ตอนเดินเข้า/ออกโซนเมือง

-- ─────────────────────────────────────────────────────────────
--  ADMIN — ย้ายเมือง / เปลี่ยนเชื้อสายของผู้เล่น
--  ตัว UI อยู่ใน MJ-Admin (แทบ "เมือง / เชื้อสาย" ในหน้าจัดการผู้เล่น)
--  ที่นี่เป็นแค่ฝั่ง logic — เปิดเป็น server export ให้ MJ-Admin เรียก (ดู server/sv_admin.lua)
--
--  สิทธิ์แอดมินตรวจที่ MJ-Admin (Config.Perms[group].CanSetJob) ไม่ได้ตรวจซ้ำที่นี่
--  เพราะ export ข้าม resource เรียกได้จากฝั่ง server เท่านั้น — client ปลอมมาไม่ได้
--
--  ⚠️ ทำได้เฉพาะ "ผู้เล่นที่ออนไลน์อยู่" เพราะการหัก/แจกบัตรต้องใช้ source ผ่าน
--     vorp_inventory และการเปลี่ยนอาชีพต้องใช้ character object — ทั้งคู่ไม่มีสำหรับคนออฟไลน์
-- ─────────────────────────────────────────────────────────────
Config.Admin = {
    -- ย้ายเมืองข้ามโควตาได้ไหม (true = แอดมินย้ายเข้าเมืองที่เต็มแล้วได้)
    -- ตัวนับ slot ยังถูกอัปเดตตามจริงทั้งสองเมืองไม่ว่าตั้งค่านี้เป็นอะไร
    bypassCityFull = true,
}

-- ─────────────────────────────────────────────────────────────
--  CITIES
--  spawnPoint : where the player teleports after selecting
--  color      : {r,g,b,a} used for territory minimap blips (0-255)
--  badgeItem  : item name in DB for this city's badge
--  zones      : polygon points {x,y} that define city territory
--  minZ/maxZ  : Z-axis range for PolyZone
--  outfitPieces : ชุดยูนิฟอร์มประจำเมือง "เต็มตัว" — [หมวด] = { male = tag, female = tag }
--               tag = MetaPed { drawable, albedo, normal, material, palette, tint0, tint1, tint2 }
--               ชื่อหมวดต้องตรงกับ Config.ComponentCategories ของ vorp_character
--               (Boots/Pant/Shirt/NeckTies/Vest/Coat/Gunbelt/Holster/Glove/Hat)
--
--               ลำดับที่เขียนในตาราง = ลำดับที่ใส่จริง (ชั้นใน -> ชั้นนอก) ให้ชิ้นที่ทับได้
--               ถูก apply ทีหลัง เช่น Coat ต้องมาหลัง Shirt/Vest
--
--               วิธีเก็บค่า: ตั้ง Config.Debug = true → ไปแต่งชุดที่อยากได้ให้ครบในร้านตัดเสื้อ
--               → พิมพ์ /nxcapture ในเกม (ไม่ต้องระบุหมวด = ดึงทุกชิ้นที่ใส่อยู่)
--               → ก๊อปบรรทัด male/female ของแต่ละหมวดมาวางทับ ทำทั้งตัวชาย/หญิง
--
--               ⚠️ อย่าใส่ bodies_upper / bodies_lower ที่ /nxcapture ปรินต์มาด้วย —
--               สองอันนั้นคือ "ลำตัวผู้เล่น" ไม่ใช่เสื้อผ้า ถ้าใส่จะไปทับหุ่นของผู้เล่น
--               และถอดคืนไม่ได้ (ไม่มีใน Config.ComponentCategories ของ vorp_character
--               → RemoveClothingTag return ทันที)
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
        outfitPieces = {
            Boots = {
                male   = { drawable = 570901230, albedo = 156330831, normal = -1244093686, material = 1835793308, palette = 0, tint0 = 0, tint1 = 0, tint2 = 0 },
                female = { drawable = 1739826358, albedo = 2098923495, normal = -1450802617, material = -660553634, palette = 0, tint0 = 0, tint1 = 0, tint2 = 0 },
            },
            Pant = {
                male   = { drawable = 49171585, albedo = 997122237, normal = -1978740444, material = -5372764, palette = 1064202495, tint0 = 56, tint1 = 56, tint2 = 56 },
                female = { drawable = 809337770, albedo = 32929181, normal = 209177305, material = 812512749, palette = 1064202495, tint0 = 56, tint1 = 56, tint2 = 56 },
            },
            Shirt = {
                male   = { drawable = 1670239909, albedo = -1413470364, normal = 1820672085, material = 89808908, palette = -1436165981, tint0 = 21, tint1 = 21, tint2 = 21 },
                female = { drawable = 2081749793, albedo = 1968030311, normal = 1568868614, material = 39011893, palette = -783849117, tint0 = 0, tint1 = 0, tint2 = 0 },
            },
            NeckTies = {
                male   = { drawable = -2132161912, albedo = -1390082636, normal = -1141160052, material = -608196087, palette = 1064202495, tint0 = 35, tint1 = 52, tint2 = 37 },
                female = { drawable = -309105399, albedo = -1390082636, normal = -1141160052, material = -608196087, palette = 1064202495, tint0 = 35, tint1 = 37, tint2 = 53 },
            },
            Vest = {
                male   = { drawable = -207285285, albedo = 1917849421, normal = -485057230, material = -20232835, palette = 1064202495, tint0 = 56, tint1 = 35, tint2 = 35 },
                female = { drawable = 1839388868, albedo = 1917849421, normal = -485057230, material = -20232835, palette = 1064202495, tint0 = 56, tint1 = 35, tint2 = 35 },
            },
            Coat = {
                male   = { drawable = 1918612039, albedo = -1423795424, normal = 497751307, material = -814987834, palette = 1064202495, tint0 = 56, tint1 = 35, tint2 = 35 },
                female = { drawable = -145015698, albedo = -1423795424, normal = 497751307, material = -814987834, palette = 1064202495, tint0 = 56, tint1 = 35, tint2 = 35 },
            },
            Gunbelt = {
                male   = { drawable = -969725370, albedo = -2031034190, normal = -2017747600, material = 1650298362, palette = 1064202495, tint0 = 56, tint1 = 35, tint2 = 35 },
                female = { drawable = 1799053413, albedo = -2031034190, normal = -2017747600, material = 1650298362, palette = 1064202495, tint0 = 56, tint1 = 35, tint2 = 35 },
            },
            Holster = {
                male   = { drawable = 529903196, albedo = -2031034190, normal = -2017747600, material = 1650298362, palette = 1064202495, tint0 = 56, tint1 = 35, tint2 = 35 },
                female = { drawable = -115903381, albedo = -2031034190, normal = -2017747600, material = 1650298362, palette = 1064202495, tint0 = 56, tint1 = 35, tint2 = 35 },
            },
            Glove = {
                male   = { drawable = -1051085845, albedo = 1025495494, normal = -2033404262, material = -1863347056, palette = 1064202495, tint0 = 35, tint1 = 35, tint2 = 35 },
                female = { drawable = -1065644097, albedo = 1025495494, normal = -2033404262, material = -1863347056, palette = 1064202495, tint0 = 35, tint1 = 35, tint2 = 35 },
            },
            Hat = {
                male   = { drawable = 129650281, albedo = -1192852743, normal = -1271924982, material = -1721060075, palette = 1064202495, tint0 = 56, tint1 = 35, tint2 = 35 },
                female = { drawable = 129650281, albedo = -1192852743, normal = -1271924982, material = -1721060075, palette = 1064202495, tint0 = 56, tint1 = 35, tint2 = 35 },
            },
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
        outfitPieces = {
            Boots = {
                male   = { drawable = 570901230, albedo = 156330831, normal = -1244093686, material = 1835793308, palette = 0, tint0 = 0, tint1 = 0, tint2 = 0 },
                female = { drawable = 1739826358, albedo = 2098923495, normal = -1450802617, material = -660553634, palette = 0, tint0 = 0, tint1 = 0, tint2 = 0 },
            },
            Pant = {
                male   = { drawable = 49171585, albedo = 997122237, normal = -1978740444, material = -5372764, palette = 1064202495, tint0 = 56, tint1 = 56, tint2 = 56 },
                female = { drawable = 809337770, albedo = 32929181, normal = 209177305, material = 812512749, palette = 1064202495, tint0 = 56, tint1 = 56, tint2 = 56 },
            },
            Shirt = {
                male   = { drawable = 1670239909, albedo = -1413470364, normal = 1820672085, material = 89808908, palette = -1436165981, tint0 = 21, tint1 = 21, tint2 = 21 },
                female = { drawable = 2081749793, albedo = 1968030311, normal = 1568868614, material = 39011893, palette = -783849117, tint0 = 0, tint1 = 0, tint2 = 0 },
            },
            NeckTies = {
                male   = { drawable = -2132161912, albedo = -1390082636, normal = -1141160052, material = -608196087, palette = 1064202495, tint0 = 51, tint1 = 56, tint2 = 46 },
                female = { drawable = -309105399, albedo = -1390082636, normal = -1141160052, material = -608196087, palette = 1064202495, tint0 = 51, tint1 = 46, tint2 = 54 },
            },
            Vest = {
                male   = { drawable = -207285285, albedo = 1917849421, normal = -485057230, material = -20232835, palette = 1064202495, tint0 = 56, tint1 = 50, tint2 = 51 },
                female = { drawable = 1839388868, albedo = 1917849421, normal = -485057230, material = -20232835, palette = 1064202495, tint0 = 56, tint1 = 50, tint2 = 51 },
            },
            Coat = {
                male   = { drawable = 1918612039, albedo = -1423795424, normal = 497751307, material = -814987834, palette = 1064202495, tint0 = 56, tint1 = 50, tint2 = 51 },
                female = { drawable = -145015698, albedo = -1423795424, normal = 497751307, material = -814987834, palette = 1064202495, tint0 = 56, tint1 = 50, tint2 = 51 },
            },
            Gunbelt = {
                male   = { drawable = -969725370, albedo = -2031034190, normal = -2017747600, material = 1650298362, palette = 1064202495, tint0 = 56, tint1 = 51, tint2 = 51 },
                female = { drawable = 1799053413, albedo = -2031034190, normal = -2017747600, material = 1650298362, palette = 1064202495, tint0 = 56, tint1 = 51, tint2 = 51 },
            },
            Holster = {
                male   = { drawable = 529903196, albedo = -2031034190, normal = -2017747600, material = 1650298362, palette = 1064202495, tint0 = 56, tint1 = 51, tint2 = 51 },
                female = { drawable = -115903381, albedo = -2031034190, normal = -2017747600, material = 1650298362, palette = 1064202495, tint0 = 56, tint1 = 51, tint2 = 51 },
            },
            Glove = {
                male   = { drawable = 346821689, albedo = -1090463359, normal = -98301946, material = -175495124, palette = 1064202495, tint0 = 51, tint1 = 51, tint2 = 51 },
                female = { drawable = -1065644097, albedo = 1025495494, normal = -2033404262, material = -1863347056, palette = 1064202495, tint0 = 51, tint1 = 51, tint2 = 51 },
            },
            Hat = {
                male   = { drawable = 129650281, albedo = -1192852743, normal = -1271924982, material = -1721060075, palette = 1064202495, tint0 = 56, tint1 = 51, tint2 = 51 },
                female = { drawable = 129650281, albedo = -1192852743, normal = -1271924982, material = -1721060075, palette = 1064202495, tint0 = 56, tint1 = 51, tint2 = 51 },
            },
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
        outfitPieces = {
            Boots = {
                male   = { drawable = 570901230, albedo = 156330831, normal = -1244093686, material = 1835793308, palette = 0, tint0 = 0, tint1 = 0, tint2 = 0 },
                female = { drawable = 1739826358, albedo = 2098923495, normal = -1450802617, material = -660553634, palette = 0, tint0 = 0, tint1 = 0, tint2 = 0 },
            },
            Pant = {
                male   = { drawable = 49171585, albedo = 997122237, normal = -1978740444, material = -5372764, palette = 1064202495, tint0 = 56, tint1 = 56, tint2 = 56 },
                female = { drawable = 809337770, albedo = 32929181, normal = 209177305, material = 812512749, palette = 1064202495, tint0 = 56, tint1 = 56, tint2 = 56 },
            },
            Shirt = {
                male   = { drawable = 1670239909, albedo = -1413470364, normal = 1820672085, material = 89808908, palette = -1436165981, tint0 = 21, tint1 = 21, tint2 = 21 },
                female = { drawable = 2081749793, albedo = 1968030311, normal = 1568868614, material = 39011893, palette = -783849117, tint0 = 0, tint1 = 0, tint2 = 0 },
            },
            NeckTies = {
                male   = { drawable = -2132161912, albedo = -1390082636, normal = -1141160052, material = -608196087, palette = 1064202495, tint0 = 0, tint1 = 52, tint2 = 0 },
                female = { drawable = -309105399, albedo = -1390082636, normal = -1141160052, material = -608196087, palette = 1064202495, tint0 = 56, tint1 = 0, tint2 = 0 },
            },
            Vest = {
                male   = { drawable = -207285285, albedo = 1917849421, normal = -485057230, material = -20232835, palette = 1064202495, tint0 = 56, tint1 = 0, tint2 = 0 },
                female = { drawable = 1839388868, albedo = 1917849421, normal = -485057230, material = -20232835, palette = 1064202495, tint0 = 56, tint1 = 0, tint2 = 0 },
            },
            Coat = {
                male   = { drawable = 1918612039, albedo = -1423795424, normal = 497751307, material = -814987834, palette = 1064202495, tint0 = 56, tint1 = 0, tint2 = 0 },
                female = { drawable = -145015698, albedo = -1423795424, normal = 497751307, material = -814987834, palette = 1064202495, tint0 = 56, tint1 = 0, tint2 = 0 },
            },
            Gunbelt = {
                male   = { drawable = -969725370, albedo = -2031034190, normal = -2017747600, material = 1650298362, palette = 1064202495, tint0 = 56, tint1 = 0, tint2 = 0 },
                female = { drawable = 1799053413, albedo = -2031034190, normal = -2017747600, material = 1650298362, palette = 1064202495, tint0 = 56, tint1 = 0, tint2 = 0 },
            },
            Holster = {
                male   = { drawable = 529903196, albedo = -2031034190, normal = -2017747600, material = 1650298362, palette = 1064202495, tint0 = 56, tint1 = 0, tint2 = 0 },
                female = { drawable = -115903381, albedo = -2031034190, normal = -2017747600, material = 1650298362, palette = 1064202495, tint0 = 56, tint1 = 0, tint2 = 0 },
            },
            Glove = {
                male   = { drawable = -1051085845, albedo = 1025495494, normal = -2033404262, material = -1863347056, palette = 1064202495, tint0 = 0, tint1 = 0, tint2 = 0 },
                female = { drawable = -1065644097, albedo = 1025495494, normal = -2033404262, material = -1863347056, palette = 1064202495, tint0 = 0, tint1 = 0, tint2 = 0 },
            },
            Hat = {
                male   = { drawable = 129650281, albedo = -1192852743, normal = -1271924982, material = -1721060075, palette = 1064202495, tint0 = 56, tint1 = 0, tint2 = 0 },
                female = { drawable = 129650281, albedo = -1192852743, normal = -1271924982, material = -1721060075, palette = 1064202495, tint0 = 56, tint1 = 0, tint2 = 0 },
            },
        },
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
