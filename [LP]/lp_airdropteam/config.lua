
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
Config["TimeAirdrop"] = {"13:00", "18:00", "20:30", "21:00", "21:30", "22:00", "22:30", "01:00"} -- HH:MM
-- เปลี่ยนจาก 'ap' เป็น 'apteam' กันชนกับคำสั่งของ MJ-Airdrop ตัวเดิมถ้ารันคู่กันในเซิร์ฟเวอร์เดียวกัน
Config['Command'] = 'apteam'                   -- คำสั่งแอดมินเรียกอีเวนต์
Config["Prop"] = "mp008_p_mp_valuables02x"    -- โมเดลวัตถุของกล่อง airdrop

-- =========================
-- Team System (lp_airdropteam เฉพาะ)
-- แบ่งทีมตามเมืองที่ผู้เล่นสังกัดใน nx_cityselect (valentine/rhodes/annesburg)
-- flow: ประกาศอีเวนต์ -> ผู้เล่นไปกดเข้าร่วมที่จุด NPC ของทีมตัวเอง -> วาปเข้า safe zone
-- -> รอครบเวลา safe zone -> เปิดโซนสู้กัน + ปิดไม่ให้เข้าร่วมเพิ่ม -> ตายได้ 1 ครั้ง (เกิดใหม่ใน
-- โซน) ตายครั้งที่ 2 = วาปกลับจุดเข้าร่วม ออกจากรอบทันที -> จบรอบวาปทุกคนที่เหลือกลับจุดเข้าร่วม
-- =========================
Config.Team = {
    enabled          = true,
    safeZoneDuration = 20, -- 300 วินาที (5 นาที) หลังวาปเข้าไปแล้วยังสู้กันไม่ได้
    maxRespawns      = 1,   -- ตายได้กี่ครั้งก่อนถูกเด้งออกจากรอบถาวร (1 = เกิดใหม่ได้ 1 ครั้ง)

    -- จุดตกแอร์ดรอป (จุดเกิดกล่อง Config.Airdrop ด้านล่างต้องตรงกับพิกัดนี้)
    dropCoords = vector4(3158.5923, -492.7288, 43.4045, 351.8208),

    teams = {
        {
            id         = 'A',
            cityId     = 'valentine', -- ต้องตรงกับ id ใน nx_cityselect/config.lua -> Config.Cities
            label      = 'ทีม A (Valentine)',
            zoneSpawn  = vector4(3175.5391, -339.3997, 43.1643, 190.2213), -- จุดเกิดทีม A ในสนาม
            -- TODO: ปรับพิกัดจุด NPC เข้าร่วมทีมจริง ตอนนี้ใช้ spawnPoint ของ Valentine ใน
            -- nx_cityselect/config.lua ไปก่อน (ยืนยันแล้วว่าเป็นจุดที่ยืนได้จริง) เพราะยังไม่มี
            -- พิกัดจุด NPC แยกต่างหากจากผู้ใช้งาน ควรเข้าเกมไปตรวจสอบแล้วปรับใหม่
            joinCoords = vector4(-170.7112, 623.6540, 114.0321, 228.4342),
        },
        {
            id         = 'B',
            cityId     = 'rhodes',
            label      = 'ทีม B (Rhodes)',
            zoneSpawn  = vector4(3355.8877, -551.6219, 42.9280, 278.4370), -- จุดเกิดทีม B ในสนาม
            -- TODO: ปรับพิกัดจุด NPC เข้าร่วมทีมจริง (ตอนนี้ใช้ spawnPoint ของ Rhodes ชั่วคราว)
            joinCoords = vector4(1221.5322, -1302.0590, 76.8985, 135.7318),
        },
        {
            id         = 'C',
            cityId     = 'annesburg',
            label      = 'ทีม C (Annesburg)',
            zoneSpawn  = vector4(3121.4070, -675.5122, 43.0089, 2.9577), -- จุดเกิดทีม C ในสนาม
            -- TODO: ปรับพิกัดจุด NPC เข้าร่วมทีมจริง (ตอนนี้ใช้ spawnPoint ของ Annesburg ชั่วคราว)
            joinCoords = vector4(2926.5059, 1285.3009, 44.6548, 68.1800),
        },
    },

    -- NPC + prompt ที่จุดเข้าร่วมทีม (แยกจาก NPC ของ bcc-train เองทั้งหมด)
    npc = {
        model    = 's_m_m_sdticketseller_01', -- โมเดลเดียวกับที่ยืนยันแล้วว่าใช้ได้จริงในโปรเจกต์นี้ (bcc-train)
        holdTime = 1200,                      -- มิลลิวินาที กดค้างเพื่อเข้าร่วม
        radius   = 3.0,                       -- ระยะที่ต้องเข้าใกล้ถึงจะขึ้น prompt
    },

    -- รัศมี safe zone รอบ zoneSpawn ของแต่ละทีม (หน่วยเมตร) — คุมทั้งกำแพงมองไม่เห็นและวง
    -- marker สีแดงบนพื้น (client_team.lua) จากค่าเดียวกันนี้ ปรับที่นี่ที่เดียวพอ
    -- TODO: ตั้งค่า default ไว้ก่อน ปรับตามพื้นที่จริงที่เดินตรวจแล้ว
    safeZoneRadius = 30.0,

    -- Blip จุดเกิดแต่ละทีม (แสดงถาวรบนแผนที่ ไม่ผูกกับรอบอีเวนต์)
    blip = {
        sprite = 1258184551, -- sprite เดียวกับที่ bcc-train ใช้จริงในโปรเจกต์นี้ (blip สถานี)
        scale  = 0.8,
    },
}

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
-- ผูกกับ Config.Team.safeZoneDuration ให้กล่องเปิดล็อคได้พอดีตอนที่ safe zone หมดเวลา/โซนเปิดสู้กัน
Config["TimeToUnlock"] = Config.Team.safeZoneDuration * 1000
Config["TimeToRemove"] =30*60*1000        -- 30 * 60 * 1000 เวลาก่อนลบกล่อง

-- ระยะเวลากดค้างเพื่อเปิดกล่อง (Hold-to-loot)
-- 2 phase แบบ nx_event: phase 1 = lp_textui:TextUIHold (จับ/grip ลอยเหนือกล่อง)
-- -> ขอ lock จาก server -> phase 2 = lp_progbar (แถบเปิดกล่อง + ท่าอนิเมชั่น)
Config["LootGripHoldTime"] = 800              -- ms, phase 1: lp_textui:TextUIHold
Config["TimeToPickingAirdrop"] = 5 * 1000     -- ms, phase 2: lp_progbar (ปรับได้)
Config["LabelToPickingAirdrop"] = "กำลังเปิดแอร์ดรอป"

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
Config["LootKey"] = 0x760A9C6F                 -- INPUT_INTERACT_OPTION1 (G)
Config["LootDistance"] = 2.0                   -- ระยะที่เริ่มเปิดได้
Config["CancelLootOnDamage"] = true            -- โดนยิง/โดนตี/โดนดาเมจ -> ยกเลิก
Config["CancelLootOnMoveAway"] = true          -- เดินหนี -> ยกเลิก

-- === Gameplay ===
Config["Radius"] = 300.0

-- === Airdrop Points and Rewards ===
Config["Airdrop"] = {
    [1] = {
        ['Label'] = "Airdrop",
        ['MaxPlayer'] = 60, -- รวม 3 ทีม
        ['MainBlip'] = {
            sprite = 615597833,
            scale = 1.0,
            color = 26,
            text = 'Airdrop'
        },
        -- ต้องตรงกับ Config.Team.dropCoords (จุดตกแอร์ดรอปที่แจ้งไว้)
        ['Coords'] = {
            { x = Config.Team.dropCoords.x, y = Config.Team.dropCoords.y, z = Config.Team.dropCoords.z }
        },
        Item = {
            {
                -- Money รองรับ {fixed} หรือ {min,max}
                Money = {1500},
                Percent = 100
            },
            {
                Item = "a_c_fishmuskie_01_lg",
                Count = {1, 10},
                Percent = 100
            },
            {
                Weapon = "death_token",
                Count = 1,
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
