ConfigMain = {}
Locale = 'en' -- 🌍 ภาษาเริ่มต้น (en = อังกฤษ)

ConfigMain.synsociety = false -- ✅ หากใช้ **syn_society** และต้องการให้รองรับ
ConfigMain.CheckHorse = true -- ✅ ตรวจสอบ **ID ของม้า** หรือไม่

-- 🔹 รายชื่อ "งานที่ปฏิบัติหน้าที่" (On-Duty Jobs)
OnDutyJobs = {
     'police',          -- ตำรวจ
     'marshal',         -- มาร์แชล
     'lawmen',          -- เจ้าหน้าที่กฎหมาย
     'sheriffrhodes',   -- นายอำเภอโรดส์
}

-- 🛠 **คำสั่งที่ใช้ในระบบตำรวจ**
ConfigMain.adjustbadgecommand = "adjustbadge" -- 🎖 คำสั่งปรับระดับตราตำรวจ
ConfigMain.openpolicemenu = "policemenu"      -- 📋 คำสั่งเปิดเมนูตำรวจ
ConfigMain.jailcommand = 'jail'               -- 🚔 คำสั่งขังคุก (สำหรับตำรวจ/แอดมิน)
ConfigMain.unjailcommand = 'unjail'           -- 🔓 คำสั่งปล่อยออกจากคุก (สำหรับตำรวจ/แอดมิน)
ConfigMain.finecommand = 'fine'               -- 💰 คำสั่งออกใบสั่งปรับ (สำหรับตำรวจ/แอดมิน)

-- อีเวนต์ Jail (คุก) สำหรับใช้ในสคริปต์อื่น ๆ
-- วิธีใช้: TriggerServerEvent('MJ-Police:JailPlayer', function(id, time, "ชื่อสถานที่")

-- 🏛 **รหัสคุก (Jail ID)**
-- Sisika = sk  (คุกซิซิก้า)
-- Blackwater = bw  (แบล็ควอเตอร์)
-- Armadillo = ar  (อาร์มาดิลโล)
-- Tumbleweed = tu  (ทัมเบิลวีด)
-- Strawberry = st  (สตรอว์เบอร์รี)
-- Valentine = val  (วาเลนไทน์)
-- Saint Denis = sd  (แซงต์เดนิส)
-- Annesburg = an  (แอนส์เบิร์ก)
