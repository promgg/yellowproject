-- ═══════════════════════════════════════════════════════════════════════════
--  lp_stablehook — ปรับเมนู kd_stable ผ่าน hook filter ของ jo_libs
--
--  ทำไมต้องมี resource แยก:
--  kd_stable เป็น escrow (.fxap) แก้โค้ดข้างในไม่ได้ แก้ได้แค่ config/lang
--  แต่มันเปิด hook filter ให้ resource ภายนอกมาแก้ข้อมูลเมนูได้ (jo_libs/modules/hook)
--  เอกสารทางการระบุเองว่าถ้าจะเอาปุ่มอย่าง bequeath ออก ให้ดักผ่าน filter พวกนี้
--
--  เฟสแรก (ตอนนี้): แค่ dump โครงสร้าง item/horseData ออกมาดูว่าปุ่ม bequeath
--  เก็บไว้เป็น field ชื่ออะไร — ยังไม่แก้อะไรทั้งนั้น คืนค่าเดิมกลับไปทุกครั้ง
-- ═══════════════════════════════════════════════════════════════════════════

Config = {}

Config.Debug = false -- true = พิมพ์ log ทุกครั้งที่บล็อก prompt (ใช้ตอนเทสว่าทำงานจริงไหม)

-- ── ปิดปุ่มมอบม้า/มอบเกวียน ──────────────────────────────────────────────────
-- ตั้ง false เพื่อคืนปุ่มกลับมา (ไม่ต้องลบ resource)
Config.DisableBequeath = true

-- ชื่อ prompt ที่จะบล็อก — ค่าที่ filter updatePreviewPrompt ส่งมาเป็น arg1
-- ยืนยันจากการ dump จริง: ตอนเลือกเมนูมอบม้าได้ค่า "bequeath"
-- (ทั้งม้าและเกวียนใช้ชื่อ prompt เดียวกัน — item.action ต่างกันเป็น bequeathHorse/bequeathWagon)
Config.BlockPrompts = {
    'bequeath',
}

-- ── โหมด dump ────────────────────────────────────────────────────────────────
-- filter ยิงทุกครั้งที่เมนูสร้างแถวม้า 1 ตัว = ถ้าไม่จำกัดจะท่วมคอนโซล
-- จำกัดจำนวนครั้งที่พิมพ์ พอครบแล้วเงียบ — restart resource เพื่อเริ่มนับใหม่
-- ปิดไว้แล้ว: dump เสร็จสิ้นภารกิจ — สรุปคือไม่มี filter ตัวไหนแตะปุ่ม bequeath เลย
-- (ยิงจริงแค่ filterHorseData / generateHorseStatisticsForMenu / filterYourHorseLine /
--  updateHorseDataBeforeSpawn ส่วน updatePreviewPrompt ไม่ยิงด้วยซ้ำ)
-- เปิด true อีกครั้งถ้าจะสำรวจโครงสร้างเมนู kd_stable เพิ่มในอนาคต
Config.Dump = {
    enabled       = false,
    limitPerFilter = 2,  -- พิมพ์กี่ครั้งต่อ filter หนึ่งตัว แล้วหยุด
    maxDepth      = 3,   -- ไล่ลงไปในตารางซ้อนลึกสุดกี่ชั้น
}

-- ── filter ที่จะดัก ──────────────────────────────────────────────────────────
-- ชื่อมาจากเอกสาร kd_stable (client filters)
--
-- รอบแรก dump 2 ตัวนี้ไปแล้ว — ไม่เจอปุ่ม bequeath:
--   filterYourHorseLine (item, horseData)  — แถวเมนูม้า มีแค่ action/data/statistics/
--                                            sliders/title ฯลฯ ไม่มีรายการปุ่มเลย
--   filterHorseData     (horseData)        — ข้อมูลม้าดิบ ไม่มีปุ่มเช่นกัน
-- สรุป: ปุ่ม bequeath ไม่ได้ผูกกับแถวม้า แต่เป็น "prompt" ที่สร้างตอนเปิดเมนู
--
-- รอบนี้ดักให้ครบทุก client filter ที่เอกสารระบุ จะได้จบในรอบเดียว ไม่ต้องลองหลายรอบ
-- (แต่ละตัวพิมพ์แค่ limitPerFilter ครั้งแล้วหยุด เลยไม่ท่วมคอนโซล)
-- ตัวที่น่าจะใช่ที่สุดคือ updatePreviewPrompt (currentPrompt, itemMenuData) = prompt โดยตรง
Config.Filters = {
    -- ดัก/ดูไปแล้วรอบก่อน (ไม่เจอปุ่ม) — คงไว้เผื่อเทียบ
    'filterYourHorseLine',
    'filterHorseData',

    -- เกี่ยวกับ prompt / การแสดงผลรายการม้า
    'updatePreviewPrompt',
    'updateItemHorseAvailable',

    -- ที่เหลือ กวาดให้ครบเผื่อปุ่มไปโผล่ที่ไหน
    'canAccessToStable',
    'generateHorseStatisticsForMenu',
    'isSameMenu',
    'updateLangForNUI',
    'updateHorseDataBeforeSpawn',
    'canFleeHorse',
}
