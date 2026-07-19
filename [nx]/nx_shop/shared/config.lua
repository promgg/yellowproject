Config = {}

Config.OpenKey = 0xCEFD9220 -- E
Config.ItemImagePath = 'nui://vorp_inventory/html/img/items/'
Config.BlackMoneyItem = 'black_money'
Config.MaxCartQuantityPerItem = 100
Config.ServerDistancePadding = 2.0

Config.Text = {
    Prompt = 'Open Shop',
    Closed = 'ร้านค้าปิดอยู่',
    NotAllowed = 'คุณไม่มีสิทธิ์ใช้ร้านนี้',
    TooFar = 'คุณอยู่ไกลร้านเกินไป',
    InvalidCart = 'รายการสินค้าไม่ถูกต้อง',
    CannotCarry = 'กระเป๋าเต็มหรือรับของไม่ได้',
    NoMoney = 'เงินไม่พอ',
    NoBlackMoney = 'Black money ไม่พอ',
    BankUnavailable = 'ไม่พบบัญชีธนาคาร',
    Purchased = 'ซื้อสินค้าเรียบร้อย',
    Busy = 'กำลังทำรายการ กรุณารอสักครู่'
}

-- ============================================================
-- NPC / Blip : ปรับ model หรือ sprite ได้ตามใจ
-- (ถ้า model ไม่ valid client จะ print เตือนแล้วข้าม NPC จุดนั้น
--  โดย blip กับ prompt ยังทำงานปกติ)
-- ============================================================
local Npc = {
    general = 's_m_m_unibutchers_01',
    gun     = 'u_m_m_valgunsmith_01',
    doctor  = 'u_m_m_valdoctor_01'
}

local BlipSprite = {
    general = 1475879922,  -- ไอคอนร้านค้า
    gun     = -145868367,  -- blip_shop_gunsmith
    doctor  = -695368421   -- blip_supplies_health
}

-- ============================================================
-- รายการสินค้า (ใช้ร่วมกันทุกสาขาของแต่ละประเภทร้าน)
-- ชื่อ item อ้างอิงจาก rdr_items_insert.sql (+ ammo จาก DB จริง)
-- ============================================================

-- ---------- General Store ----------
local generalCategories = {
    { id = 'all', label = 'ALL' },
    { id = 'farming', label = 'ทำฟาร์ม' },
    { id = 'work_tools', label = 'เครื่องมือทำมาหากิน' },
    { id = 'food', label = 'อาหาร' },
    { id = 'drinks', label = 'เครื่องดื่ม' },
    { id = 'horse', label = 'อาหารม้า' },
    { id = 'fishing', label = 'ตกปลา' }
}

local generalItems = {
    -- ทำฟาร์ม
    { id = 'tool_shovel', item = 'tool_shovel', label = 'พลั่วพรวนดิน', category = 'farming', price = 10, currency = 'cash', max = 1 },
    { id = 'tool_bucket', item = 'tool_bucket', label = 'ถังน้ำ', category = 'farming', price = 5, currency = 'cash', max = 10 },
    { id = 'compost', item = 'compost', label = 'ปุ๋ย', category = 'farming', price = 1, currency = 'cash', max = 10 },
    { id = 'seed_tobacco_plant', item = 'seed_tobacco_plant', label = 'เมล็ดยาสูบ', category = 'farming', price = 1, currency = 'cash', max = 10 },
    { id = 'seed_cotton', item = 'seed_cotton', label = 'เมล็ดฝ้าย', category = 'farming', price = 1, currency = 'cash', max = 10 },
    { id = 'seed_barley', item = 'seed_barley', label = 'เมล็ดข้าวบาร์เลย์', category = 'farming', price = 1, currency = 'cash', max = 10 },
    { id = 'seed_opium', item = 'seed_opium', label = 'เมล็ดฝิ่น', category = 'farming', price = 1, currency = 'cash', max = 10 },
    { id = 'seed_Ginseng', item = 'seed_Ginseng', label = 'เมล็ดโสม', category = 'farming', price = 1, currency = 'cash', max = 10 },
    { id = 'seed_mushroom', item = 'seed_mushroom', label = 'เมล็ดเห็ดป่า', category = 'farming', price = 1, currency = 'cash', max = 10 },
    { id = 'seed_yarrow', item = 'seed_yarrow', label = 'เมล็ดยาร์โรว์', category = 'farming', price = 1, currency = 'cash', max = 10 },
    { id = 'seed_carrot', item = 'seed_carrot', label = 'เมล็ดแครอท', category = 'farming', price = 1, currency = 'cash', max = 10 },
    { id = 'seed_corn', item = 'seed_corn', label = 'เมล็ดข้าวโพด', category = 'farming', price = 1, currency = 'cash', max = 10 },
    { id = 'seed_sugarcane', item = 'seed_sugarcane', label = 'เมล็ดอ้อย', category = 'farming', price = 1, currency = 'cash', max = 10 },
    { id = 'seed_orange', item = 'seed_orange', label = 'เมล็ดส้ม', category = 'farming', price = 1, currency = 'cash', max = 10 },
    { id = 'seed_berry', item = 'seed_berry', label = 'เมล็ดเบอรี่', category = 'farming', price = 1, currency = 'cash', max = 10 },

    -- เครื่องมือทำมาหากิน
    { id = 'tool_pickaxe', item = 'tool_pickaxe', label = 'ที่ขุดเหมือง', category = 'work_tools', price = 5, currency = 'cash', max = 10 },
    { id = 'tool_axe', item = 'tool_axe', label = 'ขวานตัดไม้', category = 'work_tools', price = 5, currency = 'cash', max = 10 },
    { id = 'job_fishing_rod', item = 'job_fishing_rod', label = 'เบ็ดตกปลา', category = 'work_tools', price = 200, currency = 'cash', max = 1 },
    { id = 'job_fishing_bait', item = 'job_fishing_bait', label = 'เหยื่อตกปลา', category = 'work_tools', price = 2, currency = 'cash', max = 20 },

    -- อาหาร
    { id = 'food_bread', item = 'food_bread', label = 'ขนมปัง', category = 'food', price = 5, currency = 'cash', max = 10 },
    { id = 'food_sandwich', item = 'food_sandwich', label = 'แซนวิส', category = 'food', price = 10, currency = 'cash', max = 10 },
    { id = 'food_canned_beans', item = 'food_canned_beans', label = 'ถั่วกระป๋อง', category = 'food', price = 15, currency = 'cash', max = 10 },
    { id = 'cigarette', item = 'cigarette', label = 'บุหรี่', category = 'food', price = 25, currency = 'cash', max = 10 },

    -- เครื่องดื่ม
    { id = 'water', item = 'water', label = 'น้ำดื่ม', category = 'drinks', price = 5, currency = 'cash', max = 10 },
    { id = 'food_coffee', item = 'food_coffee', label = 'กาแฟ', category = 'drinks', price = 5, currency = 'cash', max = 10 },
    { id = 'food_beer', item = 'food_beer', label = 'เบียร์', category = 'drinks', price = 5, currency = 'cash', max = 10 },
    { id = 'food_vodka', item = 'food_vodka', label = 'วิสกี้', category = 'drinks', price = 5, currency = 'cash', max = 10 },
    { id = 'food_brandy', item = 'food_brandy', label = 'บรั่นดี', category = 'drinks', price = 5, currency = 'cash', max = 10 },

    -- อาหารม้า
    { id = 'hr_grass', item = 'hr_grass', label = 'หญ้าม้า', category = 'horse', price = 5, currency = 'cash', max = 10 },
    { id = 'hr_brush', item = 'hr_brush', label = 'แปลงขัดม้า', category = 'horse', price = 10, currency = 'cash', max = 10 },
    { id = 'hr_medicine', item = 'hr_medicine', label = 'ยารักษาม้า', category = 'horse', price = 50, currency = 'cash', max = 10 },

    -- ── ตกปลา (lp_fishing) ────────────────────────────────────────────────
    -- เบ็ดเป็น "อาวุธจริง" (weapon = true) เพราะมินิเกมตกปลาของเกมต้องการ WEAPON_FISHINGROD
    -- ไม่ใช่แค่ไอเทมในกระเป๋า — ดู [LP]/lp_fishing/config/config.lua : Config.RodWeapon
    { id = 'fishing_rod', item = 'WEAPON_FISHINGROD', weapon = true, label = 'เบ็ดตกปลา', category = 'fishing', price = 350, currency = 'cash', max = 1, image = 'weapon_fishingrod.png' },

    -- เหยื่อ 14 ชนิดของเกม — ชื่อไอเทม = ชื่อ prop ตรงๆ (ดู lp_fishing/config/baits.lua)
    -- เหยื่อคุมว่าปลาชนิดไหนจะมากิน (BaitsPerFish) เหยื่อแพง = ล่อปลาใหญ่/หายากได้
    { id = 'bait_bread',        item = 'p_baitBread01x',        label = 'เหยื่อ: ขนมปัง', category = 'fishing', price = 3, currency = 'cash', max = 50 },
    { id = 'bait_corn',         item = 'p_baitCorn01x',         label = 'เหยื่อ: ข้าวโพด', category = 'fishing', price = 3, currency = 'cash', max = 50 },
    { id = 'bait_cheese',       item = 'p_baitCheese01x',       label = 'เหยื่อ: ชีส', category = 'fishing', price = 5, currency = 'cash', max = 50 },
    { id = 'bait_worm',         item = 'p_baitWorm01x',         label = 'เหยื่อ: ไส้เดือน', category = 'fishing', price = 8, currency = 'cash', max = 50 },
    { id = 'bait_cricket',      item = 'p_baitCricket01x',      label = 'เหยื่อ: จิ้งหรีด', category = 'fishing', price = 10, currency = 'cash', max = 50 },
    { id = 'bait_crawdad',      item = 'p_crawdad01x',          label = 'เหยื่อ: กุ้งเครย์ฟิช', category = 'fishing', price = 15, currency = 'cash', max = 50 },
    { id = 'bait_dragonfly',    item = 'p_finishedragonfly01x', label = 'เหยื่อ: แมลงปอ', category = 'fishing', price = 20, currency = 'cash', max = 50 },
    { id = 'bait_crawd_lure',   item = 'p_finishdcrawd01x',     label = 'เหยื่อปลอม: กุ้ง', category = 'fishing', price = 25, currency = 'cash', max = 50 },
    { id = 'bait_fish_lure',    item = 'p_FinisdFishlure01x',   label = 'เหยื่อปลอม: ปลา', category = 'fishing', price = 30, currency = 'cash', max = 50 },
    { id = 'bait_spinner_v4',   item = 'p_lgoc_spinner_v4',     label = 'เหยื่อสปินเนอร์ (เงิน)', category = 'fishing', price = 40, currency = 'cash', max = 50 },
    { id = 'bait_spinner_v6',   item = 'p_lgoc_spinner_v6',     label = 'เหยื่อสปินเนอร์ (ทอง)', category = 'fishing', price = 50, currency = 'cash', max = 50 },

    -- เหยื่อ legendary — ขายไว้ให้ครบชุด แต่ปลา legendary ยังไม่เปิดใช้ (เฟส 2)
    -- ตอนนี้ล่อได้แค่ปลาธรรมดาเหมือนเหยื่อปกติ ปรับราคา/ซ่อนได้ถ้ายังไม่อยากให้ซื้อ
    { id = 'bait_dragonfly_leg', item = 'p_finishedragonflylegendary01x', label = 'เหยื่อพิเศษ: แมลงปอ', category = 'fishing', price = 120, currency = 'cash', max = 20 },
    { id = 'bait_fish_lure_leg', item = 'p_finisdfishlurelegendary01x',   label = 'เหยื่อพิเศษ: ปลา', category = 'fishing', price = 120, currency = 'cash', max = 20 },
    { id = 'bait_crawd_leg',     item = 'p_finishdcrawdlegendary01x',     label = 'เหยื่อพิเศษ: กุ้ง', category = 'fishing', price = 120, currency = 'cash', max = 20 },

}

-- ---------- ร้านปืน (Gunsmith) ----------
-- อาวุธ (melee/revolver/rifle/bow) เป็นอาวุธจริง: item = ชื่อ weapon hash ตรงกับ
-- [VORP]/vorp_inventory/config/weapons.lua (SharedData.Weapons) + weapon = true
-- → server (nx_shop/server/server.lua giveOrder/canCarryOrder) จะสาขาไปใช้
-- exports.vorp_inventory:createWeapon / canCarryWeapons แทน addItem/canCarryItem โดยอัตโนมัติ
-- (ammo/misc ยังเป็น item ปกติเหมือนเดิม — จ่ายด้วย addItem)
local gunCategories = {
    { id = 'all', label = 'ALL' },
    { id = 'misc', label = 'Misc' },
    { id = 'melee', label = 'Melee' },
    { id = 'revolver', label = 'Revolver' },
    { id = 'rifle', label = 'Rifle' },
    { id = 'bow', label = 'Bow' },
    { id = 'gunoil', label = 'Gun Oil' },
    { id = 'ammo', label = 'กระสุน' }
}

local gunItems = {
    -- Misc — เป็นอาวุธจริงเหมือนกัน (อยู่ใน vorp_inventory notweapons whitelist ไม่นับ cap จำนวนปืน)
    { id = 'tool_binoculars', item = 'WEAPON_KIT_BINOCULARS', weapon = true, label = 'Binoculars (กล้องส่องทางไกล)', category = 'misc', price = 800, currency = 'cash', max = 10, image = 'weapon_kit_binoculars.png' },
    { id = 'tool_lantern', item = 'WEAPON_MELEE_DAVY_LANTERN', weapon = true, label = 'Davy Lantern (ตะเกียง)', category = 'misc', price = 200, currency = 'cash', max = 10, image = 'weapon_melee_davy_lantern.png' },
    { id = 'tool_lasso', item = 'WEAPON_LASSO', weapon = true, label = 'Lasso (เชือก)', category = 'misc', price = 150, currency = 'cash', max = 10, image = 'weapon_lasso.png' },

    -- Melee
    { id = 'weapon_knife', item = 'WEAPON_MELEE_KNIFE', weapon = true, label = 'Knife', category = 'melee', price = 250, currency = 'cash', max = 10, image = 'weapon_melee_knife.png' },
    { id = 'weapon_rustic_knife', item = 'WEAPON_MELEE_KNIFE_RUSTIC', weapon = true, label = 'Rustic Knife', category = 'melee', price = 450, currency = 'cash', max = 10, image = 'weapon_melee_knife_rustic.png' },

    -- Revolver
    { id = 'weapon_cattleman_revolver', item = 'WEAPON_REVOLVER_CATTLEMAN', weapon = true, label = 'Cattleman Revolver', category = 'revolver', price = 1500, currency = 'cash', max = 10, image = 'weapon_revolver_cattleman.png' },

    -- Rifle
    { id = 'weapon_varmint_rifle', item = 'WEAPON_RIFLE_VARMINT', weapon = true, label = 'Varmint Rifle', category = 'rifle', price = 4500, currency = 'cash', max = 10, image = 'weapon_rifle_varmint.png' },

    -- Bow
    { id = 'weapon_bow_small', item = 'WEAPON_BOW', weapon = true, label = 'Bow (ธนูเล็ก)', category = 'bow', price = 4000, currency = 'cash', max = 10, image = 'weapon_bow.png' },

    -- Gun Oil
    { id = 'oil_gun', item = 'oil_gun', label = 'Gun Oil', category = 'gunoil', price = 100, currency = 'cash', max = 10 },

    -- กระสุน (จำกัด 10)
    { id = 'ammoshotgunnormal', item = 'ammoshotgunnormal', label = 'Shotgun Ammo', category = 'ammo', price = 10, currency = 'cash', max = 10 },
    { id = 'ammorevolvernormal', item = 'ammorevolvernormal', label = 'Revolver Ammo', category = 'ammo', price = 10, currency = 'cash', max = 10 },
    { id = 'ammoriflenormal', item = 'ammoriflenormal', label = 'Rifle Ammo', category = 'ammo', price = 10, currency = 'cash', max = 10 },
    { id = 'ammovarmint', item = 'ammovarmint', label = 'Varmint Ammo', category = 'ammo', price = 10, currency = 'cash', max = 10 },
    { id = 'ammopistolnormal', item = 'ammopistolnormal', label = 'Pistol Ammo', category = 'ammo', price = 10, currency = 'cash', max = 10 },
    { id = 'ammorepeaternormal', item = 'ammorepeaternormal', label = 'Repeater Ammo', category = 'ammo', price = 10, currency = 'cash', max = 10 },
    { id = 'ammoarrownormal', item = 'ammoarrownormal', label = 'Arrow Ammo', category = 'ammo', price = 10, currency = 'cash', max = 10 },
    { id = 'ammotomahawk', item = 'ammotomahawk', label = 'Tomahawk Ammo', category = 'ammo', price = 10, currency = 'cash', max = 10 }
}

-- ---------- ร้านยา (Doctor) ----------
local doctorCategories = {
    { id = 'all', label = 'ALL' }
}

local doctorItems = {
    { id = 'bandage_s', item = 'bandage_s', label = 'ผ้าพันแผลเล็ก (+เลือด 15%)', category = 'all', price = 10, currency = 'cash', max = 10 },
    { id = 'bandage_xl', item = 'bandage_xl', label = 'ผ้าพันแผลใหญ่ (+เลือด 30%)', category = 'all', price = 25, currency = 'cash', max = 10 },
    { id = 'painkiller', item = 'painkiller', label = 'ยาแก้ปวด (+เลือด 80%)', category = 'all', price = 80, currency = 'cash', max = 10 },
    { id = 'stamina', item = 'stamina', label = 'ยาชูกำลัง (+สเตมิน่า 90%)', category = 'all', price = 60, currency = 'cash', max = 10 }
}

-- payment เริ่มต้นของร้านใหม่ทั้งหมด: เงินสดเท่านั้น, ไม่มี VAT
local defaultPayment = {
    allowCash = true,
    allowBank = false,
    vatPercent = 0
}

Config.Stores = {
    -- ================= General Store =================
    general_vlt = { -- Valentine
        enabled = true,
        title = 'ร้านค้า',
        subtitle = 'VALENTINE GENERAL STORE',
        promptName = 'General Store',
        position = vector3(-324.1397, 804.4375, 117.8816),
        heading = 217.3094,
        openDistance = 3.0,
        hours = { enabled = false, open = 7, close = 22 },
        blip = { enabled = true, name = 'ร้านค้า Valentine', sprite = BlipSprite.general },
        npc = { enabled = true, model = Npc.general, position = vector4(-324.2652, 804.0890, 117.9316, 285.8474), spawnDistance = 35.0 },
        jobs = {},
        payment = defaultPayment,
        categories = generalCategories,
        items = generalItems
    },

    general_rho = { -- Rhodes
        enabled = true,
        title = 'ร้านค้า',
        subtitle = 'RHODES GENERAL STORE',
        promptName = 'General Store',
        position = vector3(1330.2391, -1293.4142, 78.2563),
        heading = 62.4696,
        openDistance = 3.0,
        hours = { enabled = false, open = 7, close = 22 },
        blip = { enabled = true, name = 'ร้านค้า Rhodes', sprite = BlipSprite.general },
        npc = { enabled = true, model = Npc.general, position = vector4(1330.1707, -1293.5758, 77.0713, 63.0219), spawnDistance = 35.0 },
        jobs = {},
        payment = defaultPayment,
        categories = generalCategories,
        items = generalItems
    },

    general_anb = { -- Annesburg
        enabled = true,
        title = 'ร้านค้า',
        subtitle = 'ANNESBURG GENERAL STORE',
        promptName = 'General Store',
        position = vector3(2924.8984, 1365.2983, 45.2362),
        heading = 238.2687,
        openDistance = 3.0,
        hours = { enabled = false, open = 7, close = 22 },
        blip = { enabled = true, name = 'ร้านค้า Annesburg', sprite = BlipSprite.general },
        npc = { enabled = true, model = Npc.general, position = vector4(2924.8984, 1365.2983, 45.2362, 346.5224), spawnDistance = 35.0 },
        jobs = {},
        payment = defaultPayment,
        categories = generalCategories,
        items = generalItems
    },

    general_emr = { -- Emerald Ranch
        enabled = true,
        title = 'ร้านค้า',
        subtitle = 'EMERALD RANCH GENERAL STORE',
        promptName = 'General Store',
        position = vector3(1420.3792, 379.5956, 90.3204),
        heading = 328.6034,
        openDistance = 3.0,
        hours = { enabled = false, open = 7, close = 22 },
        blip = { enabled = true, name = 'ร้านค้า Emerald Ranch', sprite = BlipSprite.general },
        npc = { enabled = true, model = Npc.general, position = vector4(1420.3076, 381.3323, 90.3808, 163.9103), spawnDistance = 35.0 },
        jobs = {},
        payment = defaultPayment,
        categories = generalCategories,
        items = generalItems
    },

    -- general_bw = { -- Blackwater (คอมเมนต์ไว้ตามที่ตกลง)
    --     enabled = true,
    --     title = 'ร้านค้า',
    --     subtitle = 'BLACKWATER GENERAL STORE',
    --     promptName = 'General Store',
    --     position = vector3(-784.738, -1321.73, 42.884),
    --     heading = 179.63,
    --     openDistance = 5.0,
    --     hours = { enabled = false, open = 7, close = 22 },
    --     blip = { enabled = true, name = 'ร้านค้า Blackwater', sprite = BlipSprite.general },
    --     npc = { enabled = true, model = Npc.general, position = vector4(-784.738, -1321.73, 42.884, 179.63), spawnDistance = 35.0 },
    --     jobs = {},
    --     payment = defaultPayment,
    --     categories = generalCategories,
    --     items = generalItems
    -- },

    -- ================= ร้านปืน (Gunsmith) =================
    gun_vlt = { -- Valentine
        enabled = true,
        title = 'ร้านปืน',
        subtitle = 'VALENTINE GUNSMITH',
        promptName = 'Gunsmith',
        position = vector3(-281.1246, 778.8676, 119.5040),
        heading = 359.5377,
        openDistance = 3.0,
        hours = { enabled = false, open = 7, close = 22 },
        blip = { enabled = true, name = 'ร้านปืน Valentine', sprite = BlipSprite.gun },
        npc = { enabled = true, model = Npc.gun, position = vector4(-280.2029, 778.8726, 119.5540, 357.1845), spawnDistance = 35.0 },
        jobs = {},
        payment = defaultPayment,
        categories = gunCategories,
        items = gunItems
    },

    gun_rho = { -- Rhodes
        enabled = true,
        title = 'ร้านปืน',
        subtitle = 'RHODES GUNSMITH',
        promptName = 'Gunsmith',
        position = vector3(1323.2031, -1323.2544, 78.8197),
        heading = 344.6354,
        openDistance = 3.0,
        hours = { enabled = false, open = 7, close = 22 },
        blip = { enabled = true, name = 'ร้านปืน Rhodes', sprite = BlipSprite.gun },
        npc = { enabled = true, model = Npc.gun, position = vector4(1323.3407, -1323.4094, 77.9393, 338.6010), spawnDistance = 35.0 },
        jobs = {},
        payment = defaultPayment,
        categories = gunCategories,
        items = gunItems
    },

    gun_anb = { -- Annesburg
        enabled = true,
        title = 'ร้านปืน',
        subtitle = 'ANNESBURG GUNSMITH',
        promptName = 'Gunsmith',
        position = vector3(2948.0452, 1318.7841, 46.5781),
        heading = 71.7778,
        openDistance = 3.0,
        hours = { enabled = false, open = 7, close = 22 },
        blip = { enabled = true, name = 'ร้านปืน Annesburg', sprite = BlipSprite.gun },
        npc = { enabled = true, model = Npc.gun, position = vector4(2948.1646, 1318.6077, 44.8703, 70.6519), spawnDistance = 35.0 },
        jobs = {},
        payment = defaultPayment,
        categories = gunCategories,
        items = gunItems
    },

    -- ================= ร้านยา (Doctor) =================
    doctor_vlt = { -- Valentine
        enabled = true,
        title = 'ร้านยา',
        subtitle = 'VALENTINE DOCTOR',
        promptName = 'Doctor',
        position = vector3(-288.2027, 805.0736, 119.3859),
        heading = 282.0851,
        openDistance = 3.0,
        hours = { enabled = false, open = 7, close = 22 },
        blip = { enabled = true, name = 'ร้านยา Valentine', sprite = BlipSprite.doctor },
        npc = { enabled = true, model = Npc.doctor, position = vector4(-288.2027, 805.0736, 119.3859, 282.0851), spawnDistance = 35.0 },
        jobs = {},
        payment = defaultPayment,
        categories = doctorCategories,
        items = doctorItems
    },

    doctor_rho = { -- Rhodes
        enabled = true,
        title = 'ร้านยา',
        subtitle = 'RHODES DOCTOR',
        promptName = 'Doctor',
        position = vector3(1369.7628, -1310.8749, 77.9377),
        heading = 142.9065,
        openDistance = 3.0,
        hours = { enabled = false, open = 7, close = 22 },
        blip = { enabled = true, name = 'ร้านยา Rhodes', sprite = BlipSprite.doctor },
        npc = { enabled = true, model = Npc.doctor, position = vector4(1369.0542, -1310.7334, 77.9905, 139.1162), spawnDistance = 35.0 },
        jobs = {},
        payment = defaultPayment,
        categories = doctorCategories,
        items = doctorItems
    },

    doctor_anb = { -- Annesburg
        enabled = true,
        title = 'ร้านยา',
        subtitle = 'ANNESBURG DOCTOR',
        promptName = 'Doctor',
        position = vector3(2924.5388, 1353.8348, 44.8833),
        heading = 270.7908,
        openDistance = 3.0,
        hours = { enabled = false, open = 7, close = 22 },
        blip = { enabled = true, name = 'ร้านยา Annesburg', sprite = BlipSprite.doctor },
        npc = { enabled = true, model = Npc.doctor, position = vector4(2924.5388, 1353.8348, 44.8833, 156.3039), spawnDistance = 35.0 },
        jobs = {},
        payment = defaultPayment,
        categories = doctorCategories,
        items = doctorItems
    }
}
