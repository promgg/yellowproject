-- ███╗░░░███╗░░░░░██╗██████╗░███████╗██╗░░░██╗
-- ████╗░████║░░░░░██║██╔══██╗██╔════╝██║░░░██║
-- ██╔████╔██║░░░░░██║██║░░██║█████╗░░╚██╗░██╔╝
-- ██║╚██╔╝██║██╗░░██║██║░░██║██╔══╝░░░╚████╔╝░
-- ██║░╚═╝░██║╚█████╔╝██████╔╝███████╗░░╚██╔╝░░
-- ╚═╝░░░░░╚═╝░╚════╝░╚═════╝░╚══════╝░░░╚═╝░░░
-- Discord: https://discord.gg/gHRNMDQKzb
--
-- MJ-Airdrop | VORP RedM RDR3
-- - Hold-to-loot + progress bar
-- - Cancel loot on damage / shot / death / move away

Config = {}

-- === Discord Notifications ===
-- ตั้งค่าจริงผ่าน convar ใน server.cfg: set mj_airdrop_discord_webhook "https://discord.com/api/webhooks/..."
Config["DiscordWebhook"] = GetConvar("mj_airdrop_discord_webhook", "")
Config["DiscordBotName"] = "Airdrop Alert"
Config["DiscordAvatar"] = "https://cdn.discordapp.com/attachments/1419418766042730669/1420401036224495837/MJ SHOP.png?ex=696d884c&is=696c36cc&hm=9066f1de93b4a3a34fe0937605ab73aeb15e1176698b2221ff48bca78f7819ec&"
Config["NotifyLoot"] = true
Config["NotifyClaim"] = true

-- === Timing / Misc ===
Config["AutoTime"] = true
Config["TimeAirdrop"] = {"13:00", "18:00", "20:30", "21:00", "21:30", "22:00", "22:30", "06:00"} -- HH:MM
Config['Command'] = 'ap'                       -- คำสั่งแอดมินเรียกอีเวนต์
Config["Prop"] = "mp008_p_mp_valuables02x"    -- โมเดลวัตถุของกล่อง airdrop

-- === Airdrop Box FX (PTFX) ===
Config["Ptfx"] = {
    Enabled = true,
    Asset = "SCR_ADV_SOK",
    FxName = "scr_adv_sok_torchsmoke",
    Scale = 1.0,
    Color = { r = 255, g = 120, b = 0 },
    Duration = 0, -- seconds; 0 = loop while crate exists
    GroundSnap = true,
    ZOffset = 0.0
}


-- === Timers (milliseconds) ===
Config["TimeToUnlock"] = 10 * 60 * 1000        -- วอร์มอัปก่อนเปิดได้
Config["TimeToRemove"] = 30 * 60 * 1000        -- เวลาก่อนลบกล่อง

-- 2 phase แบบ nx_event: phase 1 = lp_textui:TextUIHold (จับ/grip ลอยเหนือกล่อง)
-- -> ขอ lock จาก server -> phase 2 = lp_progbar (แถบเปิดกล่อง + ท่าอนิเมชั่น)
Config["LootGripHoldTime"] = 800              -- ms, phase 1: lp_textui:TextUIHold
Config["TimeToPickingAirdrop"] = 40 * 1000     -- ms, phase 2: lp_progbar (ปรับได้)
Config["LabelToPickingAirdrop"] = "กำลังเปิดแอร์ดรอป"

-- lockpick minigame ก่อนเข้า phase 2 (lp_progbar) — พลาดได้ ล็อกกล่องยังอยู่กับผู้เล่นคนเดิม
-- ลองใหม่ได้ทันที ไม่มีพีนัลตี่ (ตรงกับ lp_robbery — ผลลัพธ์เป็นแค่ UX gate ฝั่ง client,
-- server ยังคุม loot/lock authoritative เหมือนเดิมทุกจุด)
Config["LockpickEnabled"]    = true
Config["LockpickPins"]       = 3
Config["LockpickDifficulty"] = 3

-- === Loot behaviour ===

-- ใช้ Prompt แบบ Native (RDR2) พร้อมวงกลมกดค้าง
-- ถ้าต้องการ “ข้อความกด G” กลางล่าง + แถบ process ให้ปิด Native prompt แล้วเปิด Progress UI
Config['UseNativeLootPrompt'] = false
-- ถ้าอยากได้แถบ Progress NUI (แนะนำ: true เมื่อปิด Native prompt)
Config['ShowLootProgressUI'] = true
-- ข้อความบน Prompt
Config['NativePromptText'] = 'เก็บ Airdrop'

-- Loot/Claim key (Native Prompt)
-- 0x760A9C6F = INPUT_INTERACT_OPTION1 (G)
-- 0xCEFD9220 = INPUT_CONTEXT (E)
Config["LootKey"] = 0xCEFD9220                 -- INPUT_CONTEXT (E)
Config["LootDistance"] = 2.0                   -- ระยะที่เริ่มเปิดได้
Config["CancelLootOnDamage"] = true            -- โดนยิง/โดนตี/โดนดาเมจ -> ยกเลิก
Config["CancelLootOnMoveAway"] = true          -- เดินหนี -> ยกเลิก

-- === Gameplay ===
Config["Radius"] = 100.0

-- === Airdrop Points and Rewards ===
Config["Airdrop"] = {
    [1] = {
        ['Label'] = "Airdrop",
        ['MaxPlayer'] = 10, -- บังคับจริงที่ server (SV:ZonePresence) — ไม่มีระบบเมืองในรีซอร์สนี้ จึงเป็น cap รวมทั้งโซน ไม่ใช่ต่อเมืองเหมือน lp_airdropteam
        ['MainBlip'] = {
            sprite = 615597833,
            scale = 1.0,
            color = 26,
            text = 'Airdrop'
        },
        ['Coords'] = {
            {x = -1207.56, y = -1628.48, z = 81.88}
        },
        Item = {
            {
                Money = {500},
                Percent = 100
            },
            {
                Item = "blueprint_low",
                Count = {1, 1},
                Percent = 100
            },
            {
                -- ของงานดำ 7 ชิ้น น้ำหนักเท่ากันทุกชิ้น สุ่มไม่ซ้ำกัน 3-5 ชิ้น
                Pool = {
                    "loot_necklace", "loot_ring", "loot_watch", "loot_chinese_coin",
                    "loot_earring", "loot_brooch", "loot_silver_tooth",
                },
                Count = {3, 5},
                Percent = 100
            },
        },
    },
}

-- =========================
-- Zone Lock (หลังหมดเวลาเปิด / TimeToUnlock == 0)
-- - คนนอกห้ามเข้าวง
-- - คนในห้ามออกวง (ออกแล้วห้ามกลับเข้า + โดนลดเลือดจนตาย)
-- =========================
Config["ZoneLockEnabled"] = true
Config["ZoneLockDeniedTitle"] = "คุณไม่มีสิทธิ์เข้าร่วม"
Config["ZoneLockDeniedSub"] = ""
Config["ZoneLockEjectBuffer"] = 1.5

Config["ZoneLeaveDamageEvery"] = 1000   -- ms
Config["ZoneLeaveDamage"] = 10
Config["ZoneLeaveNoReturn"] = true
