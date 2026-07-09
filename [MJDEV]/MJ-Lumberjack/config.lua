Config = {}

Lang = "English"

Config.Axe = "hatchet"            -- Item you want to use as an axe, same DB

-- false = ซื้อขวานครั้งเดียวใช้ได้ตลอด ไม่มีวันหัก/พัง (แค่เช็คว่ามีขวานไหมก่อนตัด)
-- true  = เปิดระบบ durability ลดทุกครั้งที่ฟัน แล้วมีโอกาสหักตอน durability ต่ำกว่า 20
Config.AxeDurability = false

Config.KEY_E   = 0x17BEC168  -- E (เริ่มตัดไม้)
Config.KEY_X   = 0x8CC9CD42  -- X (ยกเลิก)

-- ระยะกด E ตัดไม้จริง (marker/scan หาไกลกว่านี้ได้เพื่อนำทาง แต่ hint+E ใช้รัศมีนี้เท่านั้น กันเห็น hint แต่กดไม่ติด)
Config.ChopRange = 2.0

-- กด E ครั้งเดียว ตัวละครเล่นท่าตัดไม้วนไปจนกว่าหลอดโหลดจะเต็ม แล้วสุ่มไอเทม 1 ครั้ง (ไม่ต้องกด LMB ฟาดซ้ำอีกต่อไป)
Config.ChopDuration = 30      -- วินาที ต่อ 1 รอบตัดไม้ (หลอดโหลดเต็ม = จบรอบ)

-- Lower number is harder
Config.minDifficulty = 3800

Config.maxDifficulty = 2000
---------------------------

Config.lumberZone = {
    {
        Name = "Valentine Wood",
        Coords = vector3(-35.1681, 1220.1086, 172.7858), -- heading 198.7815
        Radius = 50.0,
        Blips = {
            Color = "COLOR_RED",
            Style = "BLIP_STYLE_CHALLENGE_OBJECTIVE",
            Sprite = "blip_event_appleseed"
        }
    },
    {
        Name = "Annesburg Wood",
        Coords = vector3(3024.0906, 1766.6837, 83.6999), -- heading 152.3525
        Radius = 50.0,
        Blips = {
            Color = "COLOR_RED",
            Style = "BLIP_STYLE_CHALLENGE_OBJECTIVE",
            Sprite = "blip_event_appleseed"
        }
    },
    {
        Name = "Rhodes Wood",
        Coords = vector3(684.0459, -1250.6858, 44.1388), -- heading 123.0712
        Radius = 50.0,
        Blips = {
            Color = "COLOR_RED",
            Style = "BLIP_STYLE_CHALLENGE_OBJECTIVE",
            Sprite = "blip_event_appleseed"
        }
    },
    -- {
    --     Name = "Blackwater Wood",
    --     Coords = vector3(-262.9927, 84.8365, 60.0155), -- -262.9927, 84.8365, 60.0155, 124.7684
    --     Radius = 100.0,
    --     Blips = {
    --         Color = "COLOR_RED",
    --         Style = "BLIP_STYLE_CHALLENGE_OBJECTIVE",
    --         Sprite = "blip_event_appleseed"
    --     }
    -- }
}


Config.TownRestrictions = {
    { name = 'Annesburg',  chop_allowed = true },  -- มีจุดตัดไม้จริงใน Config.lumberZone แล้ว
    { name = 'Armadillo',  chop_allowed = false },
    { name = 'Blackwater', chop_allowed = false },
    { name = 'Lagras',     chop_allowed = false },
    { name = 'Rhodes',     chop_allowed = true },  -- มีจุดตัดไม้จริงใน Config.lumberZone แล้ว
    { name = 'StDenis',    chop_allowed = false },
    { name = 'Strawberry', chop_allowed = false },
    { name = 'Tumbleweed', chop_allowed = false },
    { name = 'Valentine',  chop_allowed = true },  -- มีจุดตัดไม้จริงใน Config.lumberZone แล้ว
    { name = 'Vanhorn',    chop_allowed = false },
}

-- chance เป็น % ตรงๆ (รวมกันในลิสต์ไม่เกิน 100) ที่เหลือจาก 100 = โอกาสไม่ได้ของ
-- server.lua สุ่ม roll 1-100 แล้วไล่เรียง cumulative ตามลำดับด้านล่าง
Config.Items = {
    { name = "met_log",   label = "ท่อนไม้",   chance = 10, amount = 1 },
    { name = "met_resin", label = "ยางไม้",    chance = 10, amount = 1 },
    { name = "met_bark",  label = "เปลือกไม้",  chance = 30, amount = 1 },
    { name = "met_stick", label = "กิ่งไม้",    chance = 50, amount = 1 },
    -- รวม 100% พอดี ไม่มีโอกาส "ไม่ได้ของ" อีกต่อไป
}

Config.Trees = {
    --Birch
    "p_tree_birch_03",
    "p_tree_birch_03b",
    "p_tree_birch_03_lg",
    "p_tree_birch_03_md",
    "p_tree_birch_03_md_a",
    "p_tree_birch_04",
    "p_tree_birch_04_lg",
    "p_tree_birch_multistem",
    "p_tree_birch_tall_sap",
    "p_tree_poplar_01",
    "p_tree_poplar_02",
    "p_tree_riv_poplar_01",
    "p_tree_riv_poplar_02",
    "p_tree_willow_01",
    "p_tree_willow_02",
    "rdr2_tree_gimlet",
    "rdr2_tree_riverbirch",
    "rdr_nrml_branch_aa_sim",
    "p_tree_birch_01_sapling",
    "p_tree_birch_02_sapling",
    "p_tree_birch_03_sapling",
    "rdr2_tree_rata01",
    "rdr2_tree_rata02",
    --Cedars
    "p_sap_fir_aa_sim",
    "p_sap_fir_ab_sim",
    "p_sap_fir_ac_sim",
    "p_sap_fir_snow_aa_sim",
    "p_sap_fir_snow_ab_sim",
    "p_sap_fir_snow_ac_sim",
    "p_tree_cedar_03b_snow",
    "p_tree_cedar_03b_snow_deep",
    "p_tree_cedar_decor_01",
    "p_tree_cedar_decor_02",
    "p_tree_cedar_s_deep_02_c",
    "p_tree_douglasfir_01",
    "p_tree_douglasfir_02",
    "p_tree_douglasfir_03",
    "p_tree_douglasfir_04",
    "p_tree_douglasfir_05",
    "p_tree_douglasfir_snow_01",
    "p_tree_douglasfir_snow_01a",
    "p_tree_douglasfir_snow_02",
    "p_tree_douglasfir_snow_03",
    "p_tree_douglasfir_snow_03a",
    "p_tree_douglasfir_snow_03b",
    "p_tree_douglasfir_snow_03c",
    "p_tree_douglasfir_snow_03d",
    "p_tree_douglasfir_snow_04",
    "p_tree_douglasfir_snow_04a",
    "p_tree_douglasfir_snow_05",
    "p_tree_douglasfir_snow_05a",
    "p_tree_lodgepole_01",
    "p_tree_lodgepole_02",
    "p_tree_lodgepole_02_bv",
    "p_tree_lodgepole_02_bv_l",
    "p_tree_lodgepole_02_bv_s",
    "p_tree_lodgepole_03",
    "p_tree_lodgepole_04",
    "p_tree_lodgepole_05",
    "p_tree_lodgepole_06",
    "p_tree_lodgepole_07",
    "p_tree_lodgepole_07a",
    "p_tree_lodgepole_roots_01",
    "p_tree_lodgepole_snow_01",
    "p_tree_lodgepole_snow_01a",
    "p_tree_lodgepole_snow_02",
    "p_tree_lodgepole_snow_02a",
    "p_tree_lodgepole_snow_02b",
    "p_tree_lodgepole_snow_03",
    "p_tree_lodgepole_snow_04",
    "p_tree_longleafpine_01",
    "p_tree_longleafpine_02",
    "p_tree_longleafpine_03",
    "p_tree_longleafpine_04",
    "p_tree_pine_burnt_01",
    "p_tree_pine_burnt_01a",
    "p_tree_pine_burnt_02",
    "p_tree_pine_burnt_02a",
    "p_tree_pine_burnt_log_aa",
    "p_tree_pine_burnt_log_ab",
    "p_tree_pine_ponderosa_01",
    "p_tree_pine_ponderosa_02",
    "p_tree_pine_ponderosa_03",
    "p_tree_pine_ponderosa_04",
    "p_tree_pine_ponderosa_05",
    "p_tree_pine_ponderosa_06",
    "p_tree_pine_ponderosa_07",
    "p_tree_ponderosa_sap_01",
    "p_tree_ponderosa_sap_02",
    "p_tree_ponderosa_sap_03",
    "p_tree_whitepine_01",
    "p_tree_whitepine_02",
    "p_tree_whitepine_03",
    "p_tree_whitepine_04",
    "p_tree_whitepine_05",
    "p_tree_whitepine_06",
    "p_tree_whitepine_07",
    "p_tree_whitepine_08",
    "p_tree_whitepine_09",
    "p_tree_whitepine_10",
    "p_tree_whitepine_sap_01",
    "p_tree_whitepine_sap_02",
    "p_tree_whitepine_sap_03",
    "rdr_pine_branch_aa_sim",
    "rdr_pine_branch_ab_sim",
    "rdr2_tree_utahjuniper",
    --Dead
    "p_tree_engoak_dead",
    "p_tree_fallen_pine_01",
    "p_tree_fallen_pine_01bc",
    "p_tree_fallen_pine_02",
    "p_tree_lightning_01",
    "p_tree_lightning_02",
    "p_tree_lightning_03",
    "p_tree_lightning_04",
    "p_tree_maple_03_dead",
    "p_tree_pine_dead_01",
    "p_tree_pine_dead_02",
    "p_tree_riodel_01",
    "p_tree_rusolive_dead",
    "p_tree_rusolive_dead001",
    "p_tree_w_r_cedar_dead",
    "p_tree_w_r_cedar_dead_01",
    "p_tree_w_r_cedar_dead_02",
    "p_tree_mesquite_01",
    "p_tree_mesquite_01_dead",
    --Maples
    "p_tree_maple_dead_s_01",
    "p_tree_maple_02",
    "p_tree_maple_03",
    "p_tree_maple_03_lg",
    "p_tree_maple_03_lg_m",
    "p_tree_maple_03_lg_os",
    "p_tree_maple_03_md",
    "p_tree_maple_03_md_bv",
    "p_tree_maple_03_md_bv_l",
    "p_tree_maple_03_md_bv_s",
    "p_tree_maple_03_os",
    "p_tree_maple_04_md",
    "p_tree_maple_04_md_m",
    "p_tree_maple_05_lg",
    "p_tree_maple_05_lg_ch",
    "p_tree_maple_05_lg_ch2",
    "p_tree_maple_05_lg_m",
    "p_tree_maple_bent_01",
    "p_tree_maple_bent_02",
    "p_tree_maple_bent_03",
    "p_tree_maple_s_01",
    "p_tree_maple_s_02",
    "p_tree_maple_s_03",
    "p_tree_maple_s_04",
    "p_tree_mapleroot_01",
    "p_tree_mapleroot_02",
    "p_tree_riv_maple_01",
    "p_tree_riv_maple_04",
    "p_sap_maple_aa_sim",
    "p_sap_maple_ab_sim",
    "p_sap_maple_ac_sim",
    "p_sap_maple_ad_sim",
    "p_sap_maple_ba_sim",
    "p_sap_maple_bb_sim",
    "p_sap_maple_bc_sim",
    --Oaks
    "p_tree_angel_oak",
    "p_tree_blue_oak_01",
    "p_tree_cottonwood_01",
    "p_tree_cottonwood_02",
    "p_tree_cottonwood_03",
    "p_tree_cottonwood_04",
    "p_tree_engoak_01",
    "p_tree_engoak_01_lg",
    "p_tree_engoak_02",
    "p_tree_engoak_moss_01",
    "p_tree_engoak_moss_01_os",
    "p_tree_engoak_nbx_01",
    "p_tree_hangingtree_moss",
    "p_tree_hangingtreebranch",
    "p_tree_hangingtreeoak01",
    "p_tree_jacada_01",
    "p_tree_liveoak_01",
    "p_tree_liveoak_moss_01",
    "p_tree_oak_01",
    "p_tree_oak_braith_03",
    "p_tree_poor_joe_oak",
    "p_tree_white_oak_01",
    "p_tree_white_oak_01_ch",
    "p_tree_white_oak_02",
    "rdr2_tree_beech",
    "rdr2_tree_brokentree",
    "rdr2_tree_sycamore",
    --Palms
    "p_tree_bamboo_01",
    "p_tree_bamboo_01_crt",
    "p_tree_banana_01_crt",
    "p_tree_banana_01_md_crt",
    "p_tree_banana_01_lg",
    "p_tree_banana_dead_01_lg",
    "p_tree_banyan_01",
    "p_tree_magnolia_01",
    "p_tree_magnolia_02",
    "p_tree_magnolia_02_lg",
    "p_tree_magnolia_02_lg_os",
    "p_tree_magnolia_02_md",
    "p_tree_magnolia_02_vine",
    "p_tree_magnolia_03",
    "p_tree_magnolia_03_crt",
    "p_tree_magnolia_04",
    "p_tree_mangrove_02",
    "p_tree_mangrove_03",
    "p_tree_palm_fan_03a",
    "p_tree_palm_fan_04b",
    "p_tree_palm_fan_06",
    "p_tree_palm_fan_bea_03b",
    "p_tree_palm_fan_low_ba",
    "p_tree_palm_s_01a",
    "p_tree_palm_s_01d",
    "p_tree_palm_s_01e",
    "p_tree_palm_s_01f",
    "p_sap_magnolia_aa_sim",
    --Tall Trees
    "p_tree_log_redwood_01",
    "p_tree_redwood_05",
    "p_tree_redwood_05_lg",
    "p_tree_redwood_05_md",
    "p_tree_redwood_05_mf",
    "p_tree_redwood_05_sm",
    --Trees
    "p_tree_apple_01",
    "p_tree_burntstump_01",
    "p_tree_burntstump_03",
    "p_tree_hickory_01",
    "p_tree_hickory_02",
    "p_tree_pine_newburnt_01",
    "p_tree_pine_newburnt_02",
    "p_tree_pine_newburnt_03",
    "p_tree_pine_newburnt_04",
    "p_tree_pine_newburnt_log_01",
    "p_tree_pine_newburnt_log_02",
    --Swamp
    "p_tree_baldcypress_01_dead",
    "p_tree_baldcypress_01a",
    "p_tree_baldcypress_01a_os",
    "p_tree_baldcypress_02",
    "p_tree_baldcypress_02_os",
    "p_tree_baldcypress_02_sm_a",
    "p_tree_baldcypress_03",
    "p_tree_baldcypress_03_dead",
    "p_tree_baldcypress_03_script",
    "p_tree_baldcypress_04_dead",
    "p_tree_baldcypress_04_sm_a",
    "p_tree_baldcypress_04a",
    "p_tree_baldcypress_05",
    "p_tree_baldcypress_05_sm_a",
    "p_tree_baldcypress_06a",
    "p_tree_baldcypress_06b",
    "p_tree_baldcypress_05a",
    "p_tree_baldcypress_07",
    "p_tree_baldcypress_grave",
    "p_tree_baldcypress_knees_01",
    "p_tree_baldcypress_knees_02",
    "p_tree_branch_01_swamp",
    "p_tree_branch_02_swamp",
    "p_tree_log_01_swamp",
    "p_tree_log_01_swamp_sim",
    "p_tree_stump_01_swamp",
    "p_tree_stump_02_swamp",
    "p_sap_cypress_aa_sim",
    "p_sap_cypress_ab_sim",
}
