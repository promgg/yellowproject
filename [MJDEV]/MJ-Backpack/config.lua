Config = {}

Config.defaultlang = "de_lang"
Config.Debug = true

-- ===== คีย์ลัดเปิดกระเป๋า: กด Alt ค้าง + G =====
-- ใช้วิธีจับปุ่มแบบเดียวกับ vorp_inventory (RegisterRawKeymap + virtual key code)
-- ไม่แตะ control ของเกม → Alt+G ไม่ชนปุ่มอื่น และเปิดได้ทุกเมื่อโดยไม่ต้องเปิดกระเป๋าไปกดไอเทม
Config.OpenKey = {
    enabled    = true,   -- false = ปิดคีย์ลัด (ใช้วิธีกดไอเทมในกระเป๋าแบบเดิมได้ปกติ)
    modifierVK = 0x12,   -- ปุ่ม modifier (0x12 = Alt / 0x11 = Ctrl / 0x10 = Shift)
    keyVK      = 0x47,   -- ปุ่มหลัก (0x47 = G) — เปลี่ยนได้ เช่น 0x42 = B
}

-- Webhook Settings

-- ✅ ตั้งค่าแจ้งเตือน
Config.Logging = {
    EnableLogging = false, -- ✅ เปิด (true) / ปิด (false) การแจ้งเตือน
    EnableConsoleLog = false, -- ✅ เปิด (true) / ปิด (false) การแจ้งเตือนใน Console
    EnableDiscordLog = false, -- ✅ เปิด (true) / ปิด (false) การแจ้งเตือนใน Discord
    DiscordWebhook = "YOUR_DISCORD_WEBHOOK_URL", -- 🔥 ใส่ลิงก์ Webhook ตรงนี้
}


Config.Backpacks = {
    {
        BackpackName = 'Backpack 60',
        BuyItem = 'backpack_60',
        BackpackItem = 'Backpack60',   
        Model = 'p_ambpack01x',
        Inventory = 60
    },
    -- {
    --     BackpackName = 'Backpack 100',
    --     BuyItem = 'Backpack_100',
    --     BackpackItem = 'Backpack100',
    --     Model = 'p_bag01x',
    --     Inventory = 100
    -- },
    -- {
    --     BackpackName = 'Backpack 150',
    --     BuyItem = 'Backpack_150',
    --     BackpackItem = 'Backpack150',
    --     Model = 'p_bag02x',
    --     Inventory = 150
    -- }
}


