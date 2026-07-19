Config = {}

-- เครื่องมือ debug ล้วน — ปิดตอนขึ้น production
Config.Enabled = true

-- ความถี่ในการเช็คว่าเปลี่ยน interior หรือยัง (ms)
-- 500 = ไวพอสำหรับเดินเข้า/ออกประตู และแทบไม่กิน CPU (เทียบกับ Wait(0) ที่ไม่จำเป็นเลย)
Config.PollInterval = 500

-- คำสั่งพิมพ์สถานะปัจจุบันตามต้องการ (ไม่ต้องรอเดินเข้าออก) — false = ไม่ลงทะเบียนคำสั่ง
Config.Command = 'interior'

-- ทศนิยมของพิกัดที่พิมพ์ออกมา — 4 ตำแหน่งพอสำหรับเอาไปวางใน config ของ resource อื่น
Config.CoordDecimals = 4
