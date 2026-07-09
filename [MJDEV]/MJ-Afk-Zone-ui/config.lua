Config = {}
-- ███╗░░░███╗░░░░░██╗██████╗░███████╗██╗░░░██╗
-- ████╗░████║░░░░░██║██╔══██╗██╔════╝██║░░░██║
-- ██╔████╔██║░░░░░██║██║░░██║█████╗░░╚██╗░██╔╝
-- ██║╚██╔╝██║██╗░░██║██║░░██║██╔══╝░░░╚████╔╝░
-- ██║░╚═╝░██║╚█████╔╝██████╔╝███████╗░░╚██╔╝░░
-- ╚═╝░░░░░╚═╝░╚════╝░╚═════╝░╚══════╝░░░╚═╝░░░
-- Discord: https://discord.gg/gHRNMDQKzb 


Config.DiscordWebhookUrl = "https://ptb.discord.com/api/webhooks/1381011854234615879/AxUTEj2wGHTCk6nixj0jDgMNKuch2FcAFYPv-XCSx580T7cylOiq8cKtM6Hoio_uY_AR"  -- <-- ใส่ Webhook URL ของคุณที่นี่

-- กำหนดปุ่มกด (Key Codes) ที่ใช้ในระบบ
Config.Keys = {
    startAFK = 0x760A9C6F,    -- ปุ่ม G (0x760A9C6F) เพื่อเริ่ม AFK
    cancelAFK = 0x8CC9CD42,   -- ปุ่ม X (0x8CC9CD42) เพื่อยกเลิก AFK
    openReward = 0xD8F73058   -- ปุ่ม U (0xD8F73058) เพื่อเปิดหน้าต่างรางวัล
}

-- กำหนดรูปภาพ / ไอคอนที่ใช้ใน UI (ใส่ URL หรือ path ไฟล์ได้)
Config.UI = {
    afkIcon = "nui://MJ-Afk-Zone-ui/html/image/afk_icon.png",          -- ไอคอนแสดงสถานะ AFK
}

-- โซน AFK หลายตำแหน่ง โดยใช้ชื่อกำกับแต่ละจุด
Config.AFKZones = {
    ["valentine"] = {
        label = "Valentine Rest Area",
        coords = vector3(-435.36, 509.8, 97.92),
        radius = 50.0,
        duration = 600,  -- seconds required
        rewards = {
            { item = "large_meat", label = "Large meat", count = 5, image = "nui://vorp_inventory/html/img/items/apple.png" },
            -- { item = "money", label = "Money", count = 10, image = "nui://vorp_inventory/html/img/items/money.png" }
        }
    },

    ["strawberry"] = {
        label = "Strawberry Rest Area",
        coords = vector3(-1810.0, -350.0, 165.0),
        radius = 30.0,
        duration = 600,
        rewards = {
            { item = "large_meat", label = "Large meat", count = 1, image = "nui://vorp_inventory/html/img/items/goldbar.png" },
            { item = "cooked_meat", label = "Cooked Meat", count = 2, image = "nui://vorp_inventory/html/img/items/meat.png" }
        }
    },

    ["rhodes"] = {
        label = "Rhodes Rest Area",
        coords = vector3(1345.0, -1375.0, 80.0),
        radius = 20.0,
        duration = 900,
        rewards = {
            { item = "weapon_bow", label = "Bow", count = 1, image = "nui://vorp_inventory/html/img/items/bow.png" },
            { item = "arrow", label = "Arrow", count = 10, image = "nui://vorp_inventory/html/img/items/arrow.png" }
        }
    }
}

