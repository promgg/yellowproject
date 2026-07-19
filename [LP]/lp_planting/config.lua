-- ═══════════════════════════════════════════════════════════════════════════
--  lp_planting — ระบบปลูกพืช (แทน MJ-Planting)
--
--  ต่างจากของเดิม:
--   • เก็บต้นไม้ลง DB — ออกเกม/รีสตาร์ทเซิร์ฟแล้วต้นยังอยู่
--   • ใช้เวลานาฬิกาจริง (os.time) ไม่ใช่ GetGameTimer ที่รีเซ็ตทุกครั้งที่รีสตาร์ท
--   • บังคับโควตาจริงฝั่ง server (ของเดิมมีตัวเลขแต่ไม่เคยเช็ค = ปลูกได้ไม่จำกัด)
--   • อ้างพืชด้วย "ชื่อเมล็ด" ไม่ใช่เลขลำดับใน config (สลับลำดับแล้วต้นเก่าไม่ชี้ผิดพืช)
-- ═══════════════════════════════════════════════════════════════════════════

Config = {}

Config.Debug = false -- เปิดเฉพาะตอน dev คุม print ทั้ง client/server

-- ── ของที่ใช้ ────────────────────────────────────────────────────────────────
Config.FertilizerItem = 'compost'    -- ปุ๋ย (ขายใน nx_shop หมวด farming)
Config.WaterBucketItem = 'tool_bucket' -- ถังน้ำ เก็บจำนวนครั้งที่รดได้ใน metadata.uses

-- ── กติกา ────────────────────────────────────────────────────────────────────
Config.MaxPlantsPerZone  = 10  -- ต่อ "หนึ่งตัวละคร ต่อหนึ่งโซน" — server บังคับจริง
Config.PlantTimeoutHours = 24  -- ปลูกแล้วไม่ทำให้ครบใน 24 ชม. = ลบทิ้ง (นับจากตอนปลูก)

-- ── การกดใช้งาน ──────────────────────────────────────────────────────────────
Config.InteractRange  = 2.0  -- ระยะที่ prompt ลอยขึ้นเหนือต้น
Config.InteractHoldMs = 900  -- กดค้าง E กี่ ms (เท่ากับ MJ-Lumberjack/MJ-Mining/lp_animalFarm)

-- ── โจรบุก (สุ่มหลังรดน้ำ) ────────────────────────────────────────────────────
-- ตั้ง 0 = ปิดระบบโจร
Config.BanditChance = 40 -- เปอร์เซ็นต์

-- ── จุดเติมน้ำ ───────────────────────────────────────────────────────────────
Config.WaterRefill = {
    usesPerRefill = 10,                 -- เติม 1 ครั้ง รดได้กี่ต้น
    holdMs        = 900,
    propModel     = 'p_waterpump01x',
    range         = 3.0,                -- ระยะกดเติมจริง
}

-- ── โซนปลูก ──────────────────────────────────────────────────────────────────
-- waterPoints รองรับกี่จุดก็ได้ ตอนนี้มีเมืองละ 1 จุด (ยกมาจาก MJ-Planting)
--
-- ⚠️ TODO: ผู้ว่าจ้างขอเมืองละ 4 จุด — รอพิกัดที่เดินเก็บในเกม
--    เพิ่มได้เลยโดยต่อ entry ในตาราง waterPoints ของโซนนั้น ไม่ต้องแก้โค้ด
--    (prop สแนปลงพื้นเองตอน spawn แกน z จึงไม่ต้องเป๊ะ แต่ x/y ต้องไม่ชนสิ่งกีดขวาง)
Config.Zones = {
    valentine_farm = {
        label  = 'Valentine Farm',
        coords = vector3(-847.4569, 320.4838, 95.5757),
        range  = 40.0,   -- รัศมีโซนที่ใช้เมล็ดได้
        minDistance = 3.0, -- ระยะห่างขั้นต่ำระหว่างต้น
        blip = { enabled = true, sprite = 669307703, scale = 1.2,
                 color = 'BLIP_STYLE_CHALLENGE_OBJECTIVE', label = 'Valentine Farm' },
        waterPoints = {
            { coords = vector3(-855.6186, 331.2108, 96.1075), heading = 77.0 },
            -- TODO: อีก 3 จุด
        },
        crops = {
            seed_corn      = { label = 'ข้าวโพด',  reward = { item = 'job_corn',      count = 10 } },
            seed_carrot    = { label = 'แครอท',    reward = { item = 'job_carrot',    count = 10 } },
            seed_yarrow    = { label = 'ยาร์โรว์', reward = { item = 'job_Yarrow',    count = 10 } },
            seed_sugarcane = { label = 'อ้อย',     reward = { item = 'job_sugarcane', count = 10 } },
        },
    },

    annesburg_farm = {
        label  = 'Annesburg Farm',
        coords = vector3(2967.7837, 773.5686, 51.3994),
        range  = 40.0,
        minDistance = 3.0,
        blip = { enabled = true, sprite = 669307703, scale = 1.2,
                 color = 'BLIP_STYLE_CHALLENGE_OBJECTIVE', label = 'Annesburg Farm' },
        waterPoints = {
            { coords = vector3(2969.4299, 788.4561, 51.3998), heading = 5.5112 },
            -- TODO: อีก 3 จุด
        },
        crops = {
            seed_mushroom = { label = 'เห็ดป่า', reward = { item = 'job_mushroom', count = 10 } },
            seed_Ginseng  = { label = 'โสม',     reward = { item = 'job_Ginseng',  count = 10 } },
            seed_opium    = { label = 'ฝิ่น',    reward = { item = 'job_opium',    count = 10 } },
            seed_berry    = { label = 'เบอร์รี่', reward = { item = 'job_berry',    count = 10 } },
        },
    },

    rhodes_farm = {
        label  = 'Rhodes Farm',
        coords = vector3(968.0037, -1996.9865, 45.885),
        range  = 40.0,
        minDistance = 3.0,
        blip = { enabled = true, sprite = 669307703, scale = 1.2,
                 color = 'BLIP_STYLE_CHALLENGE_OBJECTIVE', label = 'Rhodes Farm' },
        waterPoints = {
            { coords = vector3(968.0037, -1996.9865, 45.885), heading = 176.6739 },
            -- TODO: อีก 3 จุด (จุดนี้ทับจุดปลูกพอดี ควรย้ายออกด้วย)
        },
        crops = {
            seed_tobacco_plant = { label = 'ยาสูบ',        reward = { item = 'job_tobacco_plant', count = 10 } },
            seed_barley        = { label = 'ข้าวบาร์เลย์', reward = { item = 'job_barley',        count = 10 } },
            seed_cotton        = { label = 'ฝ้าย',         reward = { item = 'job_cotton',        count = 10 } },
            seed_orange        = { label = 'ส้ม',          reward = { item = 'job_orange',        count = 10 } },
        },
    },
}

-- ── ค่ากลางของพืชทุกชนิด ─────────────────────────────────────────────────────
-- ทุกชนิดใช้โมเดล/เวลาเท่ากันหมด (ยกมาจากของเดิม) จึงตั้งรวมที่เดียว
-- ถ้าวันหลังอยากให้พืชบางชนิดต่างออกไป ใส่คีย์ชื่อเดียวกันทับใน crops ของมันได้
Config.CropDefaults = {
    model       = 'crp_seedling_aa_sim',    -- ต้นกล้า
    modelGrown  = 'crp_wheat_stk_ab_sim',   -- ต้นโตพร้อมเก็บ
    growSeconds = 1200,                     -- 20 นาที นับจากรดน้ำเสร็จ
    swapSeconds = 600,                      -- สลับเป็นโมเดลโตตอนผ่านครึ่งทาง
}

-- ── ตารางค้นหา: ชื่อเมล็ด -> โซน + ข้อมูลพืช ─────────────────────────────────
-- สร้างครั้งเดียวตอนโหลด ทั้ง client และ server ใช้ร่วมกัน
-- (เก็บชื่อเมล็ดลง DB แล้วมาหาโซนย้อนกลับผ่านตารางนี้)
Config.SeedLookup = {}
for zoneId, zone in pairs(Config.Zones) do
    for seed, crop in pairs(zone.crops) do
        if Config.SeedLookup[seed] then
            print(('^1[lp_planting]^7 เมล็ด "%s" ถูกใช้ซ้ำใน 2 โซน — ระบบจะจำได้แค่โซนเดียว'):format(seed))
        end
        Config.SeedLookup[seed] = {
            zoneId = zoneId,
            zone   = zone,
            crop   = crop,
            model       = crop.model       or Config.CropDefaults.model,
            modelGrown  = crop.modelGrown  or Config.CropDefaults.modelGrown,
            growSeconds = crop.growSeconds or Config.CropDefaults.growSeconds,
            swapSeconds = crop.swapSeconds or Config.CropDefaults.swapSeconds,
        }
    end
end
