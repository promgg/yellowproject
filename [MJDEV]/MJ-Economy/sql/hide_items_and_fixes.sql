/* MJ-Economy — เพิ่มไอเทมหนังสัตว์ (large/medium/small) + แก้ label water ที่เพี้ยนเป็น mojibake
   (2026-07-11)
   *** ต้องต่อ mysql ด้วย charset utf8mb4 ไม่งั้น label ไทยจะเพี้ยน ***
   หมายเหตุ: hide_large/hide_small เป็นไอเทมใหม่ (ไม่เคยมีมาก่อน) hide_medium/hide_high/hide_low/
   bear_hide มีอยู่แล้วในระบบก่อนหน้านี้ — ใช้ INSERT IGNORE กันพลาดถ้ามีคนสร้าง hide_large/hide_small
   ไปแล้วโดยไม่รู้ */

INSERT IGNORE INTO `items` (`item`, `label`, `limit`, `can_remove`, `type`, `usable`) VALUES
                           ('hide_large', 'หนังสัตว์ Large', '10', '1', 'item_standard', '0'),
                           ('hide_small', 'หนังสัตว์ Small', '10', '1', 'item_standard', '0');

UPDATE `items` SET `label` = 'น้ำดื่ม' WHERE `item` = 'water';
