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

-- ── ซ่อนปุ่มซื้อม้าที่ราคาเป็น "ทอง" (BUY WITH GOLD) ─────────────────────────
-- ตั้ง false เพื่อคืนปุ่มซื้อด้วยทองกลับมา
-- ยืนยันจาก dump จริง: หน้าซื้อม้า prompt ชื่อ "buy" เหมือนกันหมดทั้งเงินสด/ทอง
-- แยกด้วย itemMenuData.price = { gold = N } เท่านั้น (ไม่ใช่ชื่อ prompt "buyGold" ที่เดาไว้ตอนแรก)
-- ม้าราคาทองล้วน (id 7-18 พวก [Gacha]/[Donate]/[Event]) จะซ่อนปุ่มซื้อ — ม้าราคาเงินสดซื้อได้ปกติ
-- ตรรกะจริงอยู่ใน client/main.lua (filterPreviewPrompt) เพราะต้องอ่านราคาต่อม้า
Config.DisableGoldBuy = true

-- ชื่อ prompt ที่จะบล็อกด้วยชื่อตรงๆ — ยืนยันจาก dump: เมนูมอบม้าได้ค่า "bequeath"
-- (ทั้งม้าและเกวียนใช้ชื่อ prompt เดียวกัน — item.action ต่างกันเป็น bequeathHorse/bequeathWagon)
Config.BlockPrompts = {}
if Config.DisableBequeath then
    Config.BlockPrompts[#Config.BlockPrompts + 1] = 'bequeath'
end

-- ── ซ่อนรายการในเมนู ─────────────────────────────────────────────────────────
-- เจอจาก log ตอนเปิด jo debug (setr kd_stable:debug "on"): มี filter ชื่อ "mainMenu"
-- ที่ "ไม่มีในเอกสาร" ยิงครั้งเดียวตอนเปิดเมนู = ตัวที่ถือโครงเมนูทั้งหมด
--
-- เราจะไล่หา item ที่ action ตรงกับรายการนี้ แล้วตั้ง visible=false / disabled=true
-- ⚠️ ไม่ลบออกจาก array เพราะ item ผูกกับ id/index (จาก dump: id=3, index=4)
--    ถ้าลบแล้ว index จะเลื่อน เสี่ยงเลือกเมนูผิดตัว — ซ่อนปลอดภัยกว่า
Config.BlockActions = {
    'bequeathHorse',
    'bequeathWagon',
}

-- ── โหมด dump ────────────────────────────────────────────────────────────────
-- filter ยิงทุกครั้งที่เมนูสร้างแถวม้า 1 ตัว = ถ้าไม่จำกัดจะท่วมคอนโซล
-- จำกัดจำนวนครั้งที่พิมพ์ พอครบแล้วเงียบ — restart resource เพื่อเริ่มนับใหม่
-- ปิดไว้แล้ว: dump เสร็จสิ้นภารกิจ — สรุปคือไม่มี filter ตัวไหนแตะปุ่ม bequeath เลย
-- (ยิงจริงแค่ filterHorseData / generateHorseStatisticsForMenu / filterYourHorseLine /
--  updateHorseDataBeforeSpawn ส่วน updatePreviewPrompt ไม่ยิงด้วยซ้ำ)
-- เปิด true อีกครั้งถ้าจะสำรวจโครงสร้างเมนู kd_stable เพิ่มในอนาคต
Config.Dump = {
    enabled       = false, -- ยืนยันแล้วว่าปุ่มซื้อชื่อ "buy" แยกทอง/เงินสดที่ราคา — ปิด dump
    limitPerFilter = 20,  -- พิมพ์กี่ครั้งต่อ filter หนึ่งตัว แล้วหยุด
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
-- 🔎 รอบนี้หา "ปุ่มซื้อด้วยทอง" ในหน้าซื้อม้าใหม่ — ลดเหลือ filter ที่เกี่ยวกับ prompt/ปุ่ม
--    เท่านั้น คอนโซลจะได้ไม่ท่วมด้วยข้อมูลม้า (พวก filterHorseData/filterYourHorseLine)
--    ถ้าเปิดหน้าซื้อแล้วไม่เห็น updatePreviewPrompt โผล่เลย = ปุ่มทองไม่ผ่าน filter นี้
Config.Filters = {
    'updatePreviewPrompt',   -- ตัวหลักที่คุมชื่อ prompt (ปุ่ม)
    'updateItemHorseAvailable', -- แถวม้าในหน้าซื้อ (เผื่อปุ่ม/ราคาผูกตรงนี้)
    'canAccessToStable',
}
