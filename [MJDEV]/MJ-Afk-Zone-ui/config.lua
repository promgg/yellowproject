Config = {}
-- ███╗░░░███╗░░░░░██╗██████╗░███████╗██╗░░░██╗
-- ████╗░████║░░░░░██║██╔══██╗██╔════╝██║░░░██║
-- ██╔████╔██║░░░░░██║██║░░██║█████╗░░╚██╗░██╔╝
-- ██║╚██╔╝██║██╗░░██║██║░░██║██╔══╝░░░╚████╔╝░
-- ██║░╚═╝░██║╚█████╔╝██████╔╝███████╗░░╚██╔╝░░
-- ╚═╝░░░░░╚═╝░╚════╝░╚═════╝░╚══════╝░░░╚═╝░░░
-- Discord: https://discord.gg/gHRNMDQKzb 


-- ตั้งค่าจริงผ่าน convar ใน server.cfg: set mj_afkzone_discord_webhook "https://discord.com/api/webhooks/..."
Config.DiscordWebhookUrl = GetConvar("mj_afkzone_discord_webhook", "")

-- กำหนดปุ่มกด (Key Codes) ที่ใช้ในระบบ
Config.Keys = {
    startAFK  = 0x760A9C6F,   -- ปุ่ม G เพื่อเริ่ม AFK (ต้องอยู่ในมิติพักผ่อนแล้ว)
    cancelAFK = 0x8CC9CD42,   -- ปุ่ม X เพื่อยกเลิก AFK
    npc       = 0xCEFD9220,   -- ปุ่ม E คุยกับ NPC เพื่อสลับเข้า/ออกมิติพักผ่อน
}

-- ═══════════════════════════════════════════════════════════════════════
--  NPC บาร์เทนเดอร์ — ประตูเข้ามิติพักผ่อน
--
--  ⚠️ ต้องเรียก SetRandomOutfitVariation หลัง CreatePed ทุกครั้ง ไม่งั้น ped โผล่มาล่องหน
--     (ped RDR2 หลายรุ่นไม่มีชุดติดมา ต้องสุ่มให้เอง — pattern เดียวกับ lp_fasttravel)
-- ═══════════════════════════════════════════════════════════════════════
Config.NPC = {
    model        = 'u_f_m_vhtbartender_01',
    spawnRange   = 60.0,  -- เข้าใกล้กว่านี้ = สร้าง ped
    despawnRange = 80.0,  -- ไกลกว่านี้ = เก็บทิ้ง (ต้องมากกว่า spawnRange กัน ped กะพริบตรงขอบ)
    promptRange  = 2.5,   -- ระยะที่ข้อความ [E] ขึ้น
    holdMs       = 800,
}

-- กำหนดรูปภาพ / ไอคอนที่ใช้ใน UI (ใส่ URL หรือ path ไฟล์ได้)
Config.UI = {
    afkIcon = "nui://MJ-Afk-Zone-ui/html/image/afk_icon.png",          -- ไอคอนแสดงสถานะ AFK
}

-- ═══════════════════════════════════════════════════════════════════════
--  โซน AFK — ตอนนี้ผูกกับ saloon ใน lp_interior ทั้งหมด ไม่ใช่วงกลมกลางแจ้งแบบเดิม
--
--  flow: เดินเข้า saloon (lp_interior ย้ายมิติให้เอง) -> กด E ที่ NPC เพื่อเข้ามิติพักผ่อน
--        -> ค้าง G เพื่อเริ่ม AFK -> ครบ 15 นาทีได้รางวัล
--        เดินออกนอกร้าน = ออกจาก AFK + กลับมิติหลักอัตโนมัติ
--
--  ⚠️ `zoneKey` ต้องตรงกับ `key` ใน lp_interior/config.lua เป๊ะๆ
--     ระบบใช้ค่านี้จับคู่ว่าผู้เล่นอยู่มิติ AFK ของร้านไหน ทั้งฝั่ง client และตอน server ตรวจก่อนจ่าย
-- ═══════════════════════════════════════════════════════════════════════
Config.AFKZones = {
    ["valentine"] = {
        label    = "Saloon Valentine",
        zoneKey  = "saloon_valentine",
        npc      = { coords = vector3(-313.4084, 806.3278, 119.0306), heading = -75.4375 },
        duration = 900,  -- วินาทีที่ต้อง AFK ครบถึงได้รางวัล (15 นาที)
        rewards = {
            { item = "afk_coin", label = "เหรียญ AFK", count = 5, image = "nui://vorp_inventory/html/img/items/afk_coin.png" },
        }
    },

    ["annesburg"] = {
        label    = "Saloon Annesburg",
        zoneKey  = "saloon_annesburg",
        npc      = { coords = vector3(2965.7114, 1352.4677, 44.9080), heading = 74.7305 },
        duration = 900,
        rewards = {
            { item = "afk_coin", label = "เหรียญ AFK", count = 5, image = "nui://vorp_inventory/html/img/items/afk_coin.png" },
        }
    },

    ["rhodes"] = {
        label    = "Saloon Rhodes",
        zoneKey  = "saloon_rhodes",
        npc      = { coords = vector3(1340.1719, -1374.7789, 80.5307), heading = 93.5357 },
        duration = 900,
        rewards = {
            { item = "afk_coin", label = "เหรียญ AFK", count = 5, image = "nui://vorp_inventory/html/img/items/afk_coin.png" },
        }
    }
}

-- ระยะผ่อนผันที่ server ใช้ตรวจซ้ำว่าผู้เล่นอยู่ใกล้ NPC จริงตอนจ่ายรางวัล (เมตร)
-- เผื่อไว้กว้างพอให้เดินไปนอนมุมไหนของร้านก็ได้ แต่ไม่กว้างจนยิง event จากนอกเมืองแล้วผ่าน
Config.RewardDistance = 40.0

-- ตารางค้นหา: zoneKey ของ lp_interior -> ชื่อโซนในไฟล์นี้ (สร้างครั้งเดียวตอนโหลด)
Config.ZoneByInteriorKey = {}
for zoneName, data in pairs(Config.AFKZones) do
    if data.zoneKey then
        Config.ZoneByInteriorKey[data.zoneKey] = zoneName
    end
end

