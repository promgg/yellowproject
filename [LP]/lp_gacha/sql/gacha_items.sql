/* lp_gacha new items — 2 gacha-ticket items + 2 marksman-buff items (created 2026-07-10)
   Pools: กาชาโปรโมทเซิร์ฟ (gacha_promo) / กาชาสนับสนุน (gacha_support)
   buff_book_marksman / buff_cross_gold are item-only in v1 — no accuracy-buff logic wired yet.
   Run this against the production server DB before starting lp_gacha.
   Icons: placeholder until real artwork exists. */

INSERT IGNORE INTO `items` (`item`, `label`, `limit`, `can_remove`, `type`, `usable`) VALUES
                           ('gacha_promo',   'ตั๋วกาชาโปรโมทเซิร์ฟ', '100', '1', 'item_standard', '0'),
                           ('gacha_support', 'ตั๋วกาชาสนับสนุน', '100', '1', 'item_standard', '0'),
                           ('buff_book_marksman',      'สมุดคัมภีร์ (+5% ตีปืน)', '1', '1', 'item_standard', '0'),
                           ('buff_cross_gold',         'ไม้กางเขนทอง (+10% ตีปืน)', '1', '1', 'item_standard', '0');
