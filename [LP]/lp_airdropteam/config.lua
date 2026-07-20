
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
-- 2 แกนที่แยกอิสระจากกัน:
--   1) โซนสู้กัน (battle zone) = ผูกกับเมืองที่ผู้เล่นสังกัดใน nx_cityselect เสมอ (เกิดใหม่ในรอบ
--      ก็เกิดที่โซนนี้) ไม่ว่าจะเข้าร่วมผ่าน NPC ตัวไหนก็ตาม
--   2) จุดเข้า/จุดออก (entry/return point) = NPC สถานีที่กดค้างเข้าร่วมจริง เข้าได้ทุกสถานีไม่ว่า
--      จะเป็นเมืองอะไร แล้วออกจากรอบทางไหนก็ตาม (ตายครั้งที่ 2 / /backapt / จบรอบ) จะถูกส่งกลับ
--      ไปที่ "สถานีเดิมที่เข้ามา" เสมอ ไม่ใช่กลับตามเมืองสังกัด
-- flow: ประกาศอีเวนต์ -> ผู้เล่นไปกดเข้าร่วมที่ NPC สถานีไหนก็ได้ -> วาปเข้า safe zone ของเมือง
-- ตัวเอง -> รอครบเวลา safe zone -> เปิดโซนสู้กัน + ปิดไม่ให้เข้าร่วมเพิ่ม -> ตายได้ 1 ครั้ง (เกิดใหม่
-- ในโซน) ตายครั้งที่ 2 = วาปกลับสถานีที่เข้ามา ออกจากรอบทันที -> จบรอบวาปทุกคนที่เหลือกลับสถานีเดิม
-- =========================
Config.Team = {
    enabled          = true,
    safeZoneDuration = 300, -- 300 วินาที (5 นาที) หลังวาปเข้าไปแล้วยังสู้กันไม่ได้ (เดิมตั้ง 20 ไว้ทดสอบ)
    maxRespawns      = 1,   -- ตายได้กี่ครั้งก่อนถูกเด้งออกจากรอบถาวร (1 = เกิดใหม่ได้ 1 ครั้ง)
    maxPerCity       = 10,  -- จำกัดจำนวนคนต่อเมือง (battle team เดียวกัน) ที่เข้าร่วมรอบพร้อมกันได้

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
    -- marker แสดงขอบเขต (client_team.lua) จากค่าเดียวกันนี้ ปรับที่นี่ที่เดียวพอ
    -- TODO: ตั้งค่า default ไว้ก่อน ปรับตามพื้นที่จริงที่เดินตรวจแล้ว
    safeZoneRadius = 30.0,

    -- หน้าตาขอบเขต safe zone — เดิมมีแต่วงแบนบนพื้น ซึ่งที่รัศมี 30m เป็นเส้นบางๆ
    -- มองจากระยะไกลแทบไม่เห็น ผู้เล่นเลยเดินไปชนกำแพงมองไม่เห็นแล้วงงว่าทำไมไปต่อไม่ได้
    -- เพิ่มทรงกระบอกสูงเป็น "ผนัง" ให้เห็นขอบเขตจากทุกระยะ (แพตเทิร์นเดียวกับ PolyZone/CircleZone)
    safeZoneMarker = {
        enabled = true,
        ring = { enabled = true, r = 255, g = 40, b = 40, a = 90 },  -- วงแบนบนพื้น (type 28)

        -- ผนังทรงกระบอก (type 1) — ต้องเป็นผนัง "เตี้ยๆ ที่ระดับพื้น" เท่านั้น
        -- อย่าตั้ง height เป็นหลักร้อย/พัน: ผู้เล่นยืนอยู่ข้างในวง จะเห็นผิวด้านในของ
        -- ทรงกระบอกบังเต็มจอจนมองไม่เห็นขอบเขตที่พื้น (ค่า -500/1000 ของ PolyZone
        -- มีไว้สำหรับ debug ที่ต้องการมองทะลุภูมิประเทศ ไม่ใช่ใช้ในเกมจริง)
        wall = {
            enabled = true, r = 255, g = 40, b = 40, a = 110,
            height     = 4.0,   -- ความสูงผนัง (เมตร) — แค่พอสังเกตเห็นระดับสายตา
            baseOffset = -1.0,  -- ต่ำกว่าพื้นนิดหน่อย กันผนังลอยตอนพื้นไม่เรียบ
        },
    },

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
Config["TimeToPickingAirdrop"] = 100 * 1000   -- ms, phase 2: lp_progbar (ปรับได้)
-- === Lockpick ===
-- ต้องมี lockpick ถึงจะไขกล่องได้ หักตอน "เริ่มไข" (ตอนจองสิทธิ์เก็บของ)
-- ไม่ใช่ตอนได้ของ — โดนขัดจังหวะกลางคันก็เสียไปแล้ว
Config["RequireLockpick"] = true
Config["LockpickItem"]    = 'lockpick'
Config["NoLockpickMsg"]   = 'ต้องมีชุดสะเดาะกุญแจถึงจะไขกล่องได้'

Config["LabelToPickingAirdrop"] = "กำลังเปิดแอร์ดรอป"

-- lockpick minigame ก่อนเข้า phase 2 (lp_progbar) — พลาดได้ ล็อกกล่องยังอยู่กับผู้เล่นคนเดิม
-- ลองใหม่ได้ทันที ไม่มีพีนัลตี่ (ตรงกับ MJ-Airdrop/lp_robbery — ผลลัพธ์เป็นแค่ UX gate ฝั่ง client,
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
