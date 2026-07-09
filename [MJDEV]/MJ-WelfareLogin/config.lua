-- © 2026 MJDev | All rights reserved | Discord: discord.gg/gHRNMDQKzb
-- ห้ามนำไปจำหน่าย/แจกจ่าย/เผยแพร่ หรือแก้ไขเพื่อเผยแพร่ โดยไม่ได้รับอนุญาตเป็นลายลักษณ์อักษร

Config = {}

Config.ResourceName = 'MJ-WelfareLogin'
Config.Debug = false

Config.DailyResetHour = 4 -- รีเซ็ตความคืบหน้ารายวันตอน 04:00
Config.AutoSaveIntervalSeconds = 60
Config.ProgressSyncIntervalSeconds = 30
Config.UIRefreshIntervalSeconds = 15
Config.OpenControl = 0x760A9C6F -- G / INPUT_INTERACT_OPTION1
Config.PromptText = 'Open Welfare Office'
Config.OpenDistance = 2.0
Config.NpcSpawnDistance = 80.0

Config.Npc = {
    enabled = true,
    model = 'u_m_m_sdtrapper_01',
    coords = vector4(-337.04, 757.84, 116.84, 126.8),
    scenario = nil,
    invincible = true,
    frozen = true
}


Config.Npc3DText = {
    enabled = true,
    title = 'City Welfare Claim Point',
    subtitle = 'ONLINE WELFARE POINT',
    promptLine = 'Press G to Open Menu',
    offsetZ = 1.15,
    drawDistance = 5.0,
    scale = 0.1,
    color = { 255, 232, 188, 230 },
    useBackground = true
}

Config.UI = {
    title = 'Online Welfare Rewards',
    subtitle = 'Claim hourly rewards and city welfare benefits',
    accent = '#d0ab73',
    success = '#45df8a',
    warning = '#ffca6a',
    danger = '#ff7b7b'
}

Config.Locale = {
    promptReady = 'Press G to open City Welfare',
    uiOpened = 'City Welfare opened',
    uiClosed = 'City Welfare closed',
    autoOn = 'Auto reward claim enabled',
    autoOff = 'Auto reward claim disabled',
    claimSuccess = 'Reward claimed successfully',
    claimLocked = 'You have not been online long enough yet',
    claimAlready = 'This reward has already been claimed',
    inventoryFull = 'Not enough inventory space to claim this reward',
    invalidTier = 'Invalid reward tier',
    renamed = 'Do not rename this script. Please use the name MJ-WelfareLogin',
    autoFailCarry = 'Auto claim failed: not enough inventory space',
    resetToday = 'The daily welfare system has been reset'
}

Config.InventoryDisplay = {
    enabled = true, -- ดึงชื่อ/รูปจาก vorp_inventory อัตโนมัติ
    resource = 'vorp_inventory',
    imageFolder = 'html/img/items',
    imageExtensions = { 'png', 'webp', 'jpg', 'jpeg' },
    fallbackImage = 'img/rewards/placeholder.svg'
}

-- หมายเหตุ:
-- reward.type รองรับ: item, currency
-- currency รองรับ: money, gold, rol
-- cardTitle/image เป็นค่า fallback เท่านั้น
-- ถ้าเปิด Config.InventoryDisplay.enabled ระบบจะดึง label จาก vorp_inventory:getServerItem(itemName)
-- และจะพยายามโหลดรูปจาก https://cfx-nui-vorp_inventory/html/img/items/<item>.<ext> ตามลำดับ extension ที่ตั้งไว้
Config.Rewards = {
    {
        id = 1,
        minutes = 30,
        cardTitle = 'ยารักษา',
        cardAmountText = 'x5',
        image = 'img/rewards/medicine.svg',
        rewards = {
            { type = 'item', name = 'consumable_medicine', label = 'Medicine', amount = 5 }
        }
    },
    {
        id = 2,
        minutes = 60,
        cardTitle = 'ขนมปัง',
        cardAmountText = 'x5',
        image = 'img/rewards/bread.svg',
        rewards = {
            { type = 'item', name = 'bread', label = 'Bread', amount = 5 }
        }
    },
    {
        id = 3,
        minutes = 120,
        cardTitle = 'สเต๊กพาย',
        cardAmountText = 'x1',
        image = 'img/rewards/steak.svg',
        rewards = {
            { type = 'item', name = 'consumable_steakpie', label = 'Steak Pie', amount = 1 }
        }
    },
    {
        id = 4,
        minutes = 180,
        cardTitle = 'สตูว์เนื้อ',
        cardAmountText = 'x1',
        image = 'img/rewards/stew.svg',
        rewards = {
            { type = 'item', name = 'consumable_meat_greavy', label = 'Meat Stew', amount = 1 }
        }
    },
    {
        id = 5,
        minutes = 240,
        cardTitle = 'ทองคำแท่ง',
        cardAmountText = 'x1',
        image = 'img/rewards/goldbar.svg',
        rewards = {
            { type = 'item', name = 'goldbar', label = 'GoldBar', amount = 1 }
        }
    },
    {
        id = 6,
        minutes = 300,
        cardTitle = 'คูปองออโต้ 3 วัน',
        cardAmountText = 'x1',
        image = 'img/rewards/coupon_blue.svg',
        rewards = {
            { type = 'item', name = 'auto_3day', label = 'Auto Coupon (3 Days)', amount = 1 }
        }
    }
}
