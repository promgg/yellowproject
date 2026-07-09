Config = {}

Config.OpenKey = 0x760A9C6F -- G
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
    general = 1475879922, -- ไอคอนร้านค้า
    gun     = 1475879922, -- TODO: เปลี่ยนเป็นไอคอนปืนถ้ามี
    doctor  = 1475879922  -- TODO: เปลี่ยนเป็นไอคอนหมอ/กากบาทถ้ามี
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
    { id = 'horse', label = 'อาหารม้า' }
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
    { id = 'jop_fishing_rod', item = 'jop_fishing_rod', label = 'เบ็ดตกปลา', category = 'work_tools', price = 200, currency = 'cash', max = 1 },
    { id = 'jop_fishing_bait', item = 'jop_fishing_bait', label = 'เหยื่อตกปลา', category = 'work_tools', price = 2, currency = 'cash', max = 20 },

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
    { id = 'hr_medicine', item = 'hr_medicine', label = 'ยารักษาม้า', category = 'horse', price = 50, currency = 'cash', max = 10 }
}

-- ---------- ร้านปืน (Gunsmith) ----------
-- หมายเหตุ: อาวุธใน DB นี้เป็น item ปกติ (item_standard) จ่ายด้วย addItem
--          จึงไม่ตั้ง weapon = true / max = 10 ทุกตัว
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
    -- Misc
    { id = 'tool_binoculars', item = 'tool_binoculars', label = 'Binoculars (กล้องส่องทางไกล)', category = 'misc', price = 800, currency = 'cash', max = 10 },
    { id = 'tool_lantern', item = 'tool_lantern', label = 'Davy Lantern (ตะเกียง)', category = 'misc', price = 200, currency = 'cash', max = 10 },
    { id = 'tool_lasso', item = 'tool_lasso', label = 'Lasso (เชือก)', category = 'misc', price = 150, currency = 'cash', max = 10 },

    -- Melee
    { id = 'weapon_knife', item = 'weapon_knife', label = 'Knife', category = 'melee', price = 250, currency = 'cash', max = 10 },
    { id = 'weapon_rustic_knife', item = 'weapon_rustic_knife', label = 'Rustic Knife', category = 'melee', price = 450, currency = 'cash', max = 10 },

    -- Revolver
    { id = 'weapon_cattleman_revolver', item = 'weapon_cattleman_revolver', label = 'Cattleman Revolver', category = 'revolver', price = 1500, currency = 'cash', max = 10 },

    -- Rifle
    { id = 'weapon_varmint_rifle', item = 'weapon_varmint_rifle', label = 'Varmint Rifle', category = 'rifle', price = 4500, currency = 'cash', max = 10 },

    -- Bow
    { id = 'weapon_bow_small', item = 'weapon_bow_small', label = 'Bow (ธนูเล็ก)', category = 'bow', price = 4000, currency = 'cash', max = 10 },

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
        openDistance = 5.0,
        hours = { enabled = false, open = 7, close = 22 },
        blip = { enabled = true, name = 'ร้านค้า Valentine', sprite = BlipSprite.general },
        npc = { enabled = true, model = Npc.general, position = vector4(-324.1397, 804.4375, 116.8816, -90.3094), spawnDistance = 35.0 },
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
        openDistance = 5.0,
        hours = { enabled = false, open = 7, close = 22 },
        blip = { enabled = true, name = 'ร้านค้า Rhodes', sprite = BlipSprite.general },
        npc = { enabled = true, model = Npc.general, position = vector4(1330.2391, -1293.4142, 76.2563, 62.4696), spawnDistance = 35.0 },
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
        position = vector3(2930.8000, 1362.4426, 45.1829),
        heading = 238.2687,
        openDistance = 5.0,
        hours = { enabled = false, open = 7, close = 22 },
        blip = { enabled = true, name = 'ร้านค้า Annesburg', sprite = BlipSprite.general },
        npc = { enabled = true, model = Npc.general, position = vector4(2930.8000, 1362.4426, 43.1829, 238.2687), spawnDistance = 35.0 },
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
        openDistance = 5.0,
        hours = { enabled = false, open = 7, close = 22 },
        blip = { enabled = true, name = 'ร้านค้า Emerald Ranch', sprite = BlipSprite.general },
        npc = { enabled = true, model = Npc.general, position = vector4(1420.3792, 379.5956, 88.3204, 328.6034), spawnDistance = 35.0 },
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
        openDistance = 5.0,
        hours = { enabled = false, open = 7, close = 22 },
        blip = { enabled = true, name = 'ร้านปืน Valentine', sprite = BlipSprite.gun },
        npc = { enabled = true, model = Npc.gun, position = vector4(-281.1246, 778.8676, 118.5040, 359.5377), spawnDistance = 35.0 },
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
        openDistance = 5.0,
        hours = { enabled = false, open = 7, close = 22 },
        blip = { enabled = true, name = 'ร้านปืน Rhodes', sprite = BlipSprite.gun },
        npc = { enabled = true, model = Npc.gun, position = vector4(1323.2031, -1323.2544, 78.8197, 344.6354), spawnDistance = 35.0 },
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
        openDistance = 5.0,
        hours = { enabled = false, open = 7, close = 22 },
        blip = { enabled = true, name = 'ร้านปืน Annesburg', sprite = BlipSprite.gun },
        npc = { enabled = true, model = Npc.gun, position = vector4(2948.0452, 1318.7841, 45.5781, 71.7778), spawnDistance = 35.0 },
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
        openDistance = 5.0,
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
        openDistance = 5.0,
        hours = { enabled = false, open = 7, close = 22 },
        blip = { enabled = true, name = 'ร้านยา Rhodes', sprite = BlipSprite.doctor },
        npc = { enabled = true, model = Npc.doctor, position = vector4(1369.7628, -1310.8749, 76.9377, 142.9065), spawnDistance = 35.0 },
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
        position = vector3(2926.7612, 1351.8997, 44.4271),
        heading = 270.7908,
        openDistance = 5.0,
        hours = { enabled = false, open = 7, close = 22 },
        blip = { enabled = true, name = 'ร้านยา Annesburg', sprite = BlipSprite.doctor },
        npc = { enabled = true, model = Npc.doctor, position = vector4(2926.7612, 1351.8997, 42.4271, 270.7908), spawnDistance = 35.0 },
        jobs = {},
        payment = defaultPayment,
        categories = doctorCategories,
        items = doctorItems
    }
}
