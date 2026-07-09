Config = {}

Config.FishingTime     = 60     -- วินาทีต่อรอบ AFK
Config.MiniGameTime    = 30     -- วินาทีต่อรอบ minigame (ก่อนแท่งจับโชว์)
Config.EnableAFK     = false      -- true = เปิดโหมด AFK, false = มินิเกมส์อย่างเดียว

Config.BaitItem      = "job_fishing_bait"
Config.BaitPerCatch  = 1

-- ต้องมีติดตัวถึงจะตกปลาได้ (เหมือน Config.Axe ของ MJ-Lumberjack) — เช็คว่ามี ไม่หักไม่หาย ไม่ถูกลบตอนตกปลา
Config.RodItem       = "job_fishing_rod"

-- Key hashes (ถ้า G ไม่ทำงานให้สแกนหา hash ด้วย key scan)
Config.KEY_E   = 0x17BEC168  -- E (interact)
Config.KEY_G   = 0x760A9C6F  -- G (AFK)
Config.KEY_X   = 0x8CC9CD42  -- X (cancel)

-- Minigame: ปลา chance <= รางวัล rare (เลือกจาก pool นี้เมื่อ hit)
Config.MiniRareChanceThreshold = 30

-- _GET_MAP_ZONE_AT_COORDS (0x43AD8FC02B429D33) "type" param - ใช้เช็คว่าผู้เล่นยืนอยู่ในน้ำประเภทไหน
-- ใช้ 2 ที่: (1) เป็นเกทหลักว่า "ยืนอยู่ริมน้ำหรือเปล่า" ทั่วทั้งแมพ (ไม่ผูกกับพิกัดตายตัวจุดเดียวอีกต่อไป)
--           (2) กรอง pool ปลาต่อชนิดตาม reward.zones ด้านล่าง
Config.ZoneType = {
    LAKE  = 2,
    RIVER = 3,
    SWAMP = 5,
    OCEAN = 6,
    CREEK = 7,
    POND  = 8,
}

-- reward.zones = nil  -> ตกได้ทุกที่ในโซนตกปลา (ปลาทั่วไป)
-- reward.zones = { {type=Config.ZoneType.LAKE, name="WATER_OWANJILA"}, ... } -> ต้องยืนอยู่ในโซนน้ำที่ตรงชื่อ (ตรวจผ่าน GetHashKey เทียบกับ _GET_MAP_ZONE_AT_COORDS)
-- หมายเหตุ: ชื่อโซนทั้งหมดอ้างอิงจาก wiki/ชื่อจริงในเกม ยังไม่เคย log ค่า hash ยืนยันกับพิกัดจริงในเซิร์ฟเวอร์นี้
--           ถ้าคราฟ/ตกแล้วปลาบางตัวไม่ขึ้นเลย ให้ log ค่าที่ _GET_MAP_ZONE_AT_COORDS คืนมาตอนยืนอยู่จุดนั้นจริงๆ เทียบดูอีกที
-- ── Item names migrated 2026-07-09: a_c_fish*/legendary_* -> fish_<species>_<size|legendary> ──
-- ของเดิมไม่มี label/ไอคอนแยกของตัวเองสำหรับกลุ่ม legendary_* (อาศัย icon= ยืมรูปจากปลาไซส์ปกติ)
-- ตอนนี้ทุกไอเทมมี label+ไอคอนของตัวเองแล้ว ผ่าน sql/fish_items.sql — ไม่ต้องพึ่ง icon= อีกต่อไป
Config.FishingRewards = {
    -- ── Small / Common ($5) ──────────────────────────────────────────────
    { item = "fish_bluegill_small",        chance = 70, amount = 1 }, -- ตกได้ทุกที่
    { item = "fish_perch_small",           chance = 68, amount = 1 }, -- ตกได้ทุกที่
    { item = "fish_rockbass_small",        chance = 66, amount = 1 }, -- ตกได้ทุกที่
    { item = "fish_chainpickerel_small",   chance = 64, amount = 1,
        zones = { { type = Config.ZoneType.RIVER, name = "WATER_DAKOTARIVER" } } },
    { item = "fish_redfinpickerel_small",  chance = 62, amount = 1,
        zones = {
            { type = Config.ZoneType.RIVER, name = "WATER_LOWERMONTANARIVER" },
            { type = Config.ZoneType.CREEK, name = "WATER_STILLWATERCREEK" },
        } },
    { item = "fish_bullheadcat_small",     chance = 60, amount = 1,
        zones = { { type = Config.ZoneType.SWAMP, name = "BAYOUNWA" } } },

    -- ── Medium / Common ($9) & Uncommon ($12-13) ─────────────────────────
    { item = "fish_largemouthbass_medium",  chance = 45, amount = 1,
        zones = { { type = Config.ZoneType.SWAMP, name = "BAYOUNWA" } } },
    { item = "fish_smallmouthbass_medium",  chance = 43, amount = 1,
        zones = { { type = Config.ZoneType.LAKE, name = "WATER_OWANJILA" } } },
    { item = "fish_salmonsockeye_medium",   chance = 35, amount = 1,
        zones = { { type = Config.ZoneType.LAKE, name = "WATER_OCREAGHSRUN" } } },
    { item = "fish_rainbowtrout_medium",    chance = 33, amount = 1, -- Steelhead Trout
        zones = { { type = Config.ZoneType.SWAMP, name = "BAYOUNWA" } } },

    -- ── Large / Rare ($18-22) & Very Rare ($24-28) ───────────────────────
    { item = "fish_channelcatfish_large",  chance = 22, amount = 1,
        zones = { { type = Config.ZoneType.SWAMP, name = "BAYOUNWA" } } },
    { item = "fish_longnosegar_large",     chance = 20, amount = 1,
        zones = { { type = Config.ZoneType.SWAMP, name = "BAYOUNWA" } } },
    { item = "fish_lakesturgeon_large",    chance = 18, amount = 1,
        zones = { { type = Config.ZoneType.SWAMP, name = "BAYOUNWA" } } },
    { item = "fish_muskie_large",          chance = 12, amount = 1, -- Van Horn Trading Post อยู่ริม Lannahechee River
        zones = { { type = Config.ZoneType.RIVER, name = "WATER_LANNAHECHEERIVER" } } },
    { item = "fish_northernpike_large",    chance = 10, amount = 1, -- O'Creagh's Run (Grizzlies ตอนเหนือ)
        zones = { { type = Config.ZoneType.LAKE, name = "WATER_OCREAGHSRUN" } } },

    -- ── Legendary ($33/$40/$50) ───────────────────────────────────────────
    -- ใช้โซนเดียวกับปลาสายพันธุ์ปกติ (แม่น้ำ/ทะเลสาบเดียวกัน แค่หายากกว่ามาก)
    { item = "fish_bluegill_legendary",        chance = 6, amount = 1 },
    { item = "fish_perch_legendary",           chance = 5, amount = 1 },
    { item = "fish_rockbass_legendary",        chance = 5, amount = 1 },
    { item = "fish_chainpickerel_legendary",   chance = 4, amount = 1,
        zones = { { type = Config.ZoneType.RIVER, name = "WATER_DAKOTARIVER" } } },
    { item = "fish_redfinpickerel_legendary",  chance = 4, amount = 1,
        zones = {
            { type = Config.ZoneType.RIVER, name = "WATER_LOWERMONTANARIVER" },
            { type = Config.ZoneType.CREEK, name = "WATER_STILLWATERCREEK" },
        } },
    { item = "fish_bullheadcat_legendary",     chance = 3, amount = 1,
        zones = { { type = Config.ZoneType.SWAMP, name = "BAYOUNWA" } } },

    { item = "fish_largemouthbass_legendary",  chance = 3, amount = 1,
        zones = { { type = Config.ZoneType.SWAMP, name = "BAYOUNWA" } } },
    { item = "fish_smallmouthbass_legendary",  chance = 3, amount = 1,
        zones = { { type = Config.ZoneType.LAKE, name = "WATER_OWANJILA" } } },
    { item = "fish_salmonsockeye_legendary",   chance = 2, amount = 1,
        zones = { { type = Config.ZoneType.LAKE, name = "WATER_OCREAGHSRUN" } } },
    { item = "fish_rainbowtrout_legendary",    chance = 2, amount = 1,
        zones = { { type = Config.ZoneType.SWAMP, name = "BAYOUNWA" } } },

    { item = "fish_channelcatfish_legendary",  chance = 2, amount = 1,
        zones = { { type = Config.ZoneType.SWAMP, name = "BAYOUNWA" } } },
    { item = "fish_longnosegar_legendary",     chance = 2, amount = 1,
        zones = { { type = Config.ZoneType.SWAMP, name = "BAYOUNWA" } } },
    { item = "fish_lakesturgeon_legendary",    chance = 1, amount = 1,
        zones = { { type = Config.ZoneType.SWAMP, name = "BAYOUNWA" } } },
    { item = "fish_muskie_legendary",          chance = 1, amount = 1, -- Van Horn Trading Post ริม Lannahechee River
        zones = { { type = Config.ZoneType.RIVER, name = "WATER_LANNAHECHEERIVER" } } },
    { item = "fish_northernpike_legendary",    chance = 1, amount = 1, -- O'Creagh's Run
        zones = { { type = Config.ZoneType.LAKE, name = "WATER_OCREAGHSRUN" } } },
}
