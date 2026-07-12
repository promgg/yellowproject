/* lp_gacha new items — 2 gacha-ticket items (created 2026-07-10)
   Pools: กาชาโปรโมทเซิร์ฟ (gacha_promo) / กาชาสนับสนุน (gacha_support)
   (เดิมมี buff_book_marksman/buff_cross_gold ในนี้ด้วย แต่ 2 ตัวนั้นซ้ำกับ bonus_gun5/bonus_gun10
   ที่มีอยู่ใน DB แล้วอยู่ก่อนหน้า — เปลี่ยน pool ให้ใช้ bonus_gun5/10 แทน ไม่ต้องลงทะเบียนใหม่)
   Run this against the production server DB before starting lp_gacha. */

INSERT IGNORE INTO `items` (`item`, `label`, `limit`, `can_remove`, `type`, `usable`) VALUES
                           ('gacha_promo',   'ตั๋วกาชาโปรโมทเซิร์ฟ', '100', '1', 'item_standard', '0'),
                           ('gacha_support', 'ตั๋วกาชาสนับสนุน', '100', '1', 'item_standard', '0');
