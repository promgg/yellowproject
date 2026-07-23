-- ═══════════════════════════════════════════════════════════════════════════
--  lp_washing — ล้างตัว/ชำระคราบสกปรก
--
--  2 โหมดแยกกัน เปิด/ปิดอิสระ:
--   1) River  — ยืนแช่น้ำตื้นตามแม่น้ำ/คลอง แล้วกดค้าง E ล้างตัว (ฟรี ทุกแหล่งน้ำ)
--   2) BathHouse — อ่างอาบน้ำในโรงแรม เสียเงิน มีฉาก anim scene ของเกมจริง
--
--  natives ที่ใช้ล้าง ยืนยันแล้วว่าใช้ได้จริงกับ ped —
--  [BCC]/bcc-stables/client/main.lua:1738-1740 ใช้ชุดเดียวกันนี้ล้างม้าอยู่แล้ว
-- ═══════════════════════════════════════════════════════════════════════════

Config = {}

Config.Debug = false -- true = เปิด /washpos กับ print วินิจฉัย

-- ── สิ่งที่ล้างออก ───────────────────────────────────────────────────────────
Config.Clean = {
    envDirt      = true,  -- ฝุ่น/โคลนจากสิ่งแวดล้อม (ClearPedEnvDirt)
    blood        = true,  -- คราบเลือด (ClearPedBloodDamage)
    damageDecals = true,  -- รอยแผล decal ทุกโซน (ClearPedDamageDecalByZone)

    -- ล้างความเปียกด้วยไหม — ปิดไว้ตั้งใจ
    -- เพิ่งขึ้นจากน้ำแล้วตัวแห้งทันทีมันขัดตา ปล่อยให้เปียกแล้วแห้งเองตามระบบเกม
    wetness      = false,
}

-- ═══════════════════════════════════════════════════════════════════════════
--  โหมด 1: ล้างตัวในแม่น้ำ
-- ═══════════════════════════════════════════════════════════════════════════
Config.River = {
    enabled = true,

    -- เงื่อนไข: อยู่ในน้ำ แต่ "ไม่ได้ว่ายน้ำ" = ยืนแช่น้ำตื้นแถวตลิ่งเท่านั้น
    -- ว่ายอยู่กลางแม่น้ำจะกดล้างไม่ได้ (ท่าล้างตัวเป็นท่านั่งยอง เล่นกลางน้ำลึกแล้วพัง)
    -- ไม่ต้องตั้งพิกัดคลองทีละจุด — ใช้ได้กับทุกแหล่งน้ำในแมพอัตโนมัติ

    -- ต้องนั่งย่อ (กด Ctrl) ก่อน prompt ถึงจะขึ้น
    -- ท่าล้างตัวเป็นท่านั่งยองอยู่แล้ว บังคับให้ย่อก่อนเลยต่อเนื่องกว่า
    -- และกัน prompt เด้งใส่หน้าทุกครั้งที่เดินลุยน้ำข้ามแม่น้ำเฉย ๆ
    requireCrouch = true,

    holdMs     = 900,   -- กดค้าง E กี่ ms (เท่ากับ lp_planting/MJ-Mining)
    durationMs = 6000,  -- ความยาวหลอดล้างตัว
    label      = 'ล้างตัว',
    busyLabel  = 'กำลังล้างตัว...',

    -- ท่าทาง — scenario ท่านั่งวักน้ำล้างหน้า
    -- เลือกตัว _NO_BUCKET เพราะตัวที่มีถังจะให้เกม spawn prop ถังขึ้นมาเอง
    -- ซึ่ง ClearPedTasks เก็บไม่ลง = ถังค้างเป็นซากในโลก (บทเรียนจาก lp_planting)
    scenario   = 'WORLD_HUMAN_WASH_FACE_BUCKET_GROUND_NO_BUCKET',

    cooldownMs = 3000,  -- กันกดรัวซ้ำ
}

-- ═══════════════════════════════════════════════════════════════════════════
--  โหมด 2: อ่างอาบน้ำในโรงแรม
-- ═══════════════════════════════════════════════════════════════════════════
--  อ่างเป็น prop ที่มีอยู่ในแมพอยู่แล้ว สคริปต์ไม่ได้ spawn และไม่ได้ไปค้นหา prop
--  เราแค่จำ "พิกัดจุดที่ผู้เล่นต้องไปยืน" (stand) ไว้ทีละโรงแรม แล้วเช็คระยะ
--
--  ── เรื่องฉาก anim scene ────────────────────────────────────────────────────
--  rsg-bathing ใช้ anim scene ของเกมพาตัวละครลงอ่างจริง โดย dict ถูก "เบคพิกัด
--  โลกไว้แล้ว" จึงต้องใช้ของเมืองนั้นเท่านั้น เช่น Saint Denis คือ
--      script@mini_game@bathing@BATHING_INTRO_OUTRO_ST_DENIS   scene: s_regular_intro
--  เอา dict ของเมืองหนึ่งไปใช้อีกเมืองไม่ได้ ตัวละครจะโผล่ผิดที่
--
--  ชื่อ slot ของ ped ในฉากคือ "ARTHUR" และต้องผูกประตูเข้าไปด้วยในชื่อ "Door"
--  (เลยต้องมีฟิลด์ door เก็บ door hash ไว้ ไม่งั้นฉากจะขาดตัวแสดง)
--  ยืนยันจากซอร์ส rsg-bathing/client/client.lua:74-79
--
--  ของเราทำแค่ intro -> แช่ -> ล้าง -> outro
--  ไม่ได้ทำส่วนถอดเสื้อผ้า / ผ้าเช็ดตัว / มินิเกมถูตัว / กล้อง ของต้นทาง
--  เพราะพวกนั้นผูกกับ rsg-appearance + rsg-wardrobe ซึ่งเราไม่มี
--
--  ถ้าฉากมีปัญหา ตั้ง useAnimScene = false จะกลับไปใช้ท่าล้างตัวธรรมดา
--  (โค้ดมี timeout ในตัว ถ้าโหลดฉากไม่ขึ้นใน 3 วิ จะ fallback เองไม่ค้างจอ)
Config.BathHouse = {
    enabled = true,

    -- ใช้ฉากอ่างอาบน้ำจริงของเกม (ยังไม่ได้ทดสอบในเกม — มี fallback รออยู่)
    useAnimScene = true,
    -- แช่อยู่ในอ่างกี่ ms ก่อนลุกขึ้น (ระหว่างนี้คราบถูกล้าง)
    -- 0 = intro จบแล้วต่อ outro เลย ไม่มีช่วงค้างท่า
    -- (ใน Lua เลข 0 เป็น truthy ค่า `soakMs or 5000` จึงได้ 0 จริง ๆ ไม่เด้งไป 5000)
    soakMs       = 0,

    price      = 5,     -- ราคาต่อครั้ง
    moneyType  = 0,     -- 0 = เงินสด, 1 = ทอง (ตรงกับ VORP character.removeCurrency)
    range      = 1.5,   -- ระยะที่ prompt ขึ้น (ต้นทาง rsg ใช้ 1.0 ซึ่งแคบไปหน่อย)
    holdMs     = 900,
    durationMs = 12000,
    label      = 'อาบน้ำ',
    busyLabel  = 'กำลังอาบน้ำ...',

    -- เฉพาะ 3 เมืองของเรา ให้ตรงกับ lp_planting / nx_shop / nx_graverobbery
    -- (Saint Denis / Strawberry / Blackwater / Van Horn มีอ่างในเกมเหมือนกัน
    --  แต่ไม่ใช่เมืองในระบบเรา ถ้าจะเปิดเพิ่มค่อยใส่ทีหลัง)
    locations = {
        {
            id    = 'valentine',
            label = 'Valentine',
            stand = vector3(-320.56, 762.41, 117.44),
            dict  = 'script@mini_game@bathing@BATHING_INTRO_OUTRO_VALENTINE',
            scene = 's_regular_intro',
            door  = 142240370, -- door hash ของโรงแรมนั้น ผูกเข้าฉากในชื่อ "Door"
            blip  = { enabled = false, sprite = 1475879922, name = 'Bath House Valentine' },
        },
        {
            id    = 'annesburg',
            label = 'Annesburg',
            stand = vector3(2950.42, 1332.15, 44.44),
            dict  = 'script@mini_game@bathing@BATHING_INTRO_OUTRO_ANNESBURG',
            scene = 's_regular_intro',
            door  = -201071322, -- door hash ของโรงแรมนั้น ผูกเข้าฉากในชื่อ "Door"
            blip  = { enabled = false, sprite = 1475879922, name = 'Bath House Annesburg' },
        },
        {
            id    = 'rhodes',
            label = 'Rhodes',
            stand = vector3(1340.11, -1379.6, 84.28),
            dict  = 'script@mini_game@bathing@BATHING_INTRO_OUTRO_RHODES',
            scene = 's_regular_intro',
            door  = -1847993131, -- door hash ของโรงแรมนั้น ผูกเข้าฉากในชื่อ "Door"
            blip  = { enabled = false, sprite = 1475879922, name = 'Bath House Rhodes' },
        },
    },
}
