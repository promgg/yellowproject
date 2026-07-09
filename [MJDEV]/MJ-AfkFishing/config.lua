Config = {}

Config.FishingTime     = 60     -- วินาทีต่อรอบ AFK
Config.MiniGameTime    = 30     -- วินาทีต่อรอบ minigame (ก่อนแท่งจับโชว์)
Config.EnableAFK     = false      -- true = เปิดโหมด AFK, false = มินิเกมส์อย่างเดียว

Config.BaitItem      = "fishbait"
Config.BaitPerCatch  = 1

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
Config.FishingRewards = {
    -- ── Small / Common ($5) ──────────────────────────────────────────────
    { item = "a_c_fishbluegil_01_sm",        chance = 70, amount = 1 }, -- ตกได้ทุกที่
    { item = "a_c_fishperch_01_sm",           chance = 68, amount = 1 }, -- ตกได้ทุกที่
    { item = "a_c_fishrockbass_01_sm",        chance = 66, amount = 1 }, -- ตกได้ทุกที่
    { item = "a_c_fishchainpickerel_01_sm",   chance = 64, amount = 1,
        zones = { { type = Config.ZoneType.RIVER, name = "WATER_DAKOTARIVER" } } },
    { item = "a_c_fishredfinpickerel_01_sm",  chance = 62, amount = 1,
        zones = {
            { type = Config.ZoneType.RIVER, name = "WATER_LOWERMONTANARIVER" },
            { type = Config.ZoneType.CREEK, name = "WATER_STILLWATERCREEK" },
        } },
    { item = "a_c_fishbullheadcat_01_sm",     chance = 60, amount = 1,
        zones = { { type = Config.ZoneType.SWAMP, name = "BAYOUNWA" } } },

    -- ── Medium / Common ($9) & Uncommon ($12-13) ─────────────────────────
    { item = "a_c_fishlargemouthbass_01_ms",  chance = 45, amount = 1,
        zones = { { type = Config.ZoneType.SWAMP, name = "BAYOUNWA" } } },
    { item = "a_c_fishsmallmouthbass_01_ms",  chance = 43, amount = 1,
        zones = { { type = Config.ZoneType.LAKE, name = "WATER_OWANJILA" } } },
    { item = "a_c_fishsalmonsockeye_01_ms",   chance = 35, amount = 1,
        zones = { { type = Config.ZoneType.LAKE, name = "WATER_OCREAGHSRUN" } } },
    { item = "a_c_fishrainbowtrout_01_ms",    chance = 33, amount = 1, -- Steelhead Trout
        zones = { { type = Config.ZoneType.SWAMP, name = "BAYOUNWA" } } },

    -- ── Large / Rare ($18-22) & Very Rare ($24-28) ───────────────────────
    { item = "a_c_fishchannelcatfish_01_lg",  chance = 22, amount = 1,
        zones = { { type = Config.ZoneType.SWAMP, name = "BAYOUNWA" } } },
    { item = "a_c_fishlongnosegar_01_lg",     chance = 20, amount = 1,
        zones = { { type = Config.ZoneType.SWAMP, name = "BAYOUNWA" } } },
    { item = "a_c_fishlakesturgeon_01_lg",    chance = 18, amount = 1,
        zones = { { type = Config.ZoneType.SWAMP, name = "BAYOUNWA" } } },
    { item = "a_c_fishmuskie_01_lg",          chance = 12, amount = 1, -- Van Horn Trading Post อยู่ริม Lannahechee River
        zones = { { type = Config.ZoneType.RIVER, name = "WATER_LANNAHECHEERIVER" } } },
    { item = "a_c_fishnorthernpike_01_lg",    chance = 10, amount = 1, -- O'Creagh's Run (Grizzlies ตอนเหนือ)
        zones = { { type = Config.ZoneType.LAKE, name = "WATER_OCREAGHSRUN" } } },

    -- ── Legendary ($33/$40/$50) ───────────────────────────────────────────
    -- ใช้โซนเดียวกับปลาสายพันธุ์ปกติ (แม่น้ำ/ทะเลสาบเดียวกัน แค่หายากกว่ามาก)
    -- icon = ไอเทมปกติที่ยังไม่มีโมเดล/ไอคอนแยกของตัวเอง ให้ client.lua ใช้รูปนี้แทน
    { item = "legendary_bluegill",        chance = 6, amount = 1, icon = "a_c_fishbluegil_01_sm" },
    { item = "legendary_perch",           chance = 5, amount = 1, icon = "a_c_fishperch_01_sm" },
    { item = "legendary_rockbass",        chance = 5, amount = 1, icon = "a_c_fishrockbass_01_sm" },
    { item = "legendary_chainpickerel",   chance = 4, amount = 1, icon = "a_c_fishchainpickerel_01_sm",
        zones = { { type = Config.ZoneType.RIVER, name = "WATER_DAKOTARIVER" } } },
    { item = "legendary_redfinpickerel",  chance = 4, amount = 1, icon = "a_c_fishredfinpickerel_01_sm",
        zones = {
            { type = Config.ZoneType.RIVER, name = "WATER_LOWERMONTANARIVER" },
            { type = Config.ZoneType.CREEK, name = "WATER_STILLWATERCREEK" },
        } },
    { item = "legendary_bullheadcat",     chance = 3, amount = 1, icon = "a_c_fishbullheadcat_01_sm",
        zones = { { type = Config.ZoneType.SWAMP, name = "BAYOUNWA" } } },

    { item = "legendary_largemouthbass",  chance = 3, amount = 1, icon = "a_c_fishlargemouthbass_01_ms",
        zones = { { type = Config.ZoneType.SWAMP, name = "BAYOUNWA" } } },
    { item = "legendary_smallmouthbass",  chance = 3, amount = 1, icon = "a_c_fishsmallmouthbass_01_ms",
        zones = { { type = Config.ZoneType.LAKE, name = "WATER_OWANJILA" } } },
    { item = "legendary_sockeyesalmon",   chance = 2, amount = 1, icon = "a_c_fishsalmonsockeye_01_ms",
        zones = { { type = Config.ZoneType.LAKE, name = "WATER_OCREAGHSRUN" } } },
    { item = "legendary_steelheadtrout",  chance = 2, amount = 1, icon = "a_c_fishrainbowtrout_01_ms",
        zones = { { type = Config.ZoneType.SWAMP, name = "BAYOUNWA" } } },

    { item = "legendary_channelcatfish",  chance = 2, amount = 1, icon = "a_c_fishchannelcatfish_01_lg",
        zones = { { type = Config.ZoneType.SWAMP, name = "BAYOUNWA" } } },
    { item = "legendary_longnosegar",     chance = 2, amount = 1, icon = "a_c_fishlongnosegar_01_lg",
        zones = { { type = Config.ZoneType.SWAMP, name = "BAYOUNWA" } } },
    { item = "legendary_lakesturgeon",    chance = 1, amount = 1, icon = "a_c_fishlakesturgeon_01_lg",
        zones = { { type = Config.ZoneType.SWAMP, name = "BAYOUNWA" } } },
    { item = "legendary_muskie",          chance = 1, amount = 1, icon = "a_c_fishmuskie_01_lg", -- Van Horn Trading Post ริม Lannahechee River
        zones = { { type = Config.ZoneType.RIVER, name = "WATER_LANNAHECHEERIVER" } } },
    { item = "legendary_northernpike",    chance = 1, amount = 1, icon = "a_c_fishnorthernpike_01_lg", -- O'Creagh's Run
        zones = { { type = Config.ZoneType.LAKE, name = "WATER_OCREAGHSRUN" } } },
}
