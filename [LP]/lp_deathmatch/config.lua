Config = {}

Config.Debug = true
Config.Locale = 'th'

-- หมายเหตุ: ค่า config อื่นๆ ทั้งหมด (เมือง, ตารางเวลา, อาวุธที่นับแต้มได้, คูลดาวน์, รางวัล ฯลฯ)
-- อยู่ใน server/config_server.lua (server-only) เพราะ client ไม่มีความจำเป็นต้องรู้ค่าพวกนี้เลย —
-- client แค่เป็นตัวแสดงผลตามที่ server broadcast มา + รายงานว่า "ฉันโดนใครฆ่าด้วยอาวุธอะไร" เท่านั้น
