

CREATE TABLE IF NOT EXISTS `bank_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `identifier` varchar(50) NOT NULL,
  `charidentifier` int(11) NOT NULL,
  `money` double(22,2) DEFAULT 0.00 NOT NULL,
  `gold` double(22,2) DEFAULT 0.00 NOT NULL,
  `items` longtext DEFAULT '[]',
  `invspace` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ── Migration ที่แนะนำหลังปรับ Config.SafeBox (ขั้นต่ำ 20 ช่อง) ──
-- รันครั้งเดียวด้วยตัวเอง (ไม่รันอัตโนมัติจากรีซอร์ส) เพื่อดันบัญชีเก่าที่ invspace ต่ำกว่าขั้นต่ำใหม่ให้ขึ้นมาที่ 20
-- ไม่กระทบบัญชีที่มีช่องเยอะกว่านี้อยู่แล้ว
-- UPDATE bank_users SET invspace = 20 WHERE invspace < 20;

-- ── (แนะนำ) unique key กันแถวบัญชีซ้ำต่อ (ตัวละคร, ธนาคาร) ──
-- ตารางเดิมไม่มี unique constraint ทำให้ check-then-insert ตอนเปิดบัญชีครั้งแรกพร้อมกันสองครั้งอาจได้ 2 แถว
-- ก่อนรัน ต้องลบแถวซ้ำที่มีอยู่ก่อน (เก็บ id น้อยสุดของแต่ละคู่) แล้วค่อยเพิ่ม key:
--   DELETE b1 FROM bank_users b1
--     INNER JOIN bank_users b2
--     ON b1.charidentifier = b2.charidentifier AND b1.name = b2.name AND b1.id > b2.id;
--   ALTER TABLE bank_users ADD UNIQUE KEY uq_char_bank (charidentifier, name);
