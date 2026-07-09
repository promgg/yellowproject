Config = {}

Config.defaultlang = "de_lang"
Config.Debug = true

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


