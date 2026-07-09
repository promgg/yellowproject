Config = Config or {}

-- ─── หมวดหมู่ไอเทม ────────────────────────────────────────────────────────────
-- (v1: ไม่รองรับหมวด 'weapon' — VORP weapon เป็น object มี serial/durability เฉพาะตัว
--  ไม่ใช่ stack ธรรมดา ต้องออกแบบระบบแยกต่างหาก)
Config.Categories = {
    { id = 'general',  label = 'ไอเทมทั่วไป', icon = 'fa-box'      },
    { id = 'food',     label = 'อาหาร',        icon = 'fa-utensils' },
    { id = 'vehicle',  label = 'ยานพาหนะ',     icon = 'fa-car'      },
    { id = 'material', label = 'วัตถุดิบ',     icon = 'fa-cubes'    },
}

-- ─── ไอเทมที่ขายได้เฉพาะบาง job ────────────────────────────────────────────────
-- key = item_name, jobs = รายชื่อ job ที่อนุญาต (ตรงกับ Character.job ของ VORPCore)
Config.RestrictedItems = {
    -- ['police_badge'] = { jobs = { 'police', 'sheriff' } },
}

-- ─── ราคาขั้นต่ำ / สูงสุด และหมวดหมู่ต่อไอเทม ─────────────────────────────────
-- money = เงินสด (currency type 0), gold = ทอง (currency type 1)
-- category = id จาก Config.Categories (ถ้าไม่ระบุ ใช้ 'general')
Config.ItemPriceConfig = {
    -- ['bread'] = {
    --     category = 'food',
    --     money    = { min = 1, max = 500 },
    --     gold     = { min = 1, max = 50  },
    -- },
}

-- ค่า default เมื่อไม่กำหนดใน ItemPriceConfig
Config.DefaultPriceConfig = {
    money = { min = 1, max = 9999999 },
    gold  = { min = 1, max = 999999  },
}

-- ─── สกุลเงินที่อนุญาต ────────────────────────────────────────────────────────
-- money → VORP currency type 0 (dollars), gold → VORP currency type 1
Config.AllowedCurrencies = {
    money = { enabled = true, label = 'เงินสด', color = '#4ade80', currencyType = 0 },
    gold  = { enabled = true, label = 'ทอง',    color = '#f0ca78', currencyType = 1 },
}
