/* lp_fishing — ไอเทมเหยื่อ 14 ชนิด
   ชื่อไอเทม = ชื่อ prop ของเกมตรงๆ (ดู config/baits.lua) — server ลงทะเบียนเป็น usable item
   ให้ทั้ง 14 ตัวนี้ กดใช้แล้วจะติดเหยื่อเข้าเบ็ด

   *** ต้องต่อ mysql ด้วย --default-character-set=utf8mb4 ***

   หมายเหตุ: ไฟล์ต้นทางเดิม (vorp_fishing.sql) มี INSERT ก้อนที่สองสร้างไอเทมปลาชื่อ a_c_fish*
   ตัดออกแล้ว เพราะโปรเจกต์นี้ใช้ชื่อ fish_<species>_<size> (ดู MJ-AfkFishing/sql/fish_items.sql)
   และ server/server.lua ถูก remap ให้แจกชื่อชุดนั้นแล้ว — ถ้ารันก้อนเก่าจะได้ไอเทมค้าง 27 ตัวที่ไม่มีใครใช้
*/

/* Bait Data*/
INSERT IGNORE INTO `items` (`item`, `label`, `limit`, `can_remove`, `type`, `usable`) VALUES 
                           ('p_baitBread01x', 'Bread Bait', '10', '1', 'item_standard', '1'),
                           ('p_baitCorn01x', 'Corn Bait', '10', '1', 'item_standard', '1'),
                           ('p_baitCheese01x', 'Cheese Bait', '10', '1', 'item_standard', '1'),
                           ('p_baitWorm01x', 'Worm Bait', '10', '1', 'item_standard', '1'),
                           ('p_baitCricket01x', 'Cricket Bait', '10', '1', 'item_standard', '1'),
                           ('p_crawdad01x', 'Crawfish Bait', '10', '1', 'item_standard', '1'),
                           ('p_finishedragonfly01x', 'Dragonfly Lure', '10', '1', 'item_standard', '1'),
                           ('p_FinisdFishlure01x', 'Fish Lure', '10', '1', 'item_standard', '1'),
                           ('p_finishdcrawd01x', 'Crawfish Lure', '10', '1', 'item_standard', '1'),
                           ('p_finishedragonflylegendary01x', 'Legendary Dragonfly Lure', '10', '1', 'item_standard', '1'),
                           ('p_finisdfishlurelegendary01x', 'Legendary Fish Lure', '10', '1', 'item_standard', '1'),
                           ('p_finishdcrawdlegendary01x', 'Legendary Crawfish Lure', '10', '1', 'item_standard', '1'),
                           ('p_lgoc_spinner_v4', 'Spinner V4', '10', '1', 'item_standard', '1'),
                           ('p_lgoc_spinner_v6', 'Spinner V6', '10', '1', 'item_standard', '1');

/* Fish Data*/
