/* MJ-AfkFishing fish items — migrated 2026-07-09 from a_c_fish*/legendary_* to fish_<species>_<size|legendary>
   Labels updated 2026-07-11 to Thai names.
   Run this against your server DB before starting MJ-AfkFishing with the renamed config.lua.
   *** ต้องต่อ mysql ด้วย --default-character-set=utf8mb4 ไม่งั้น label ไทยจะเพี้ยน ***
   หมายเหตุ: ไฟล์นี้ใช้ INSERT IGNORE (สำหรับติดตั้งใหม่) — ถ้าไอเทมมีอยู่ใน DB แล้ว จะไม่แก้ label
   ให้ใช้ fish_labels_update.sql แทนเพื่ออัปเดต label ของแถวที่มีอยู่
   Icons: copy matching files in vorp_inventory/html/img/items/. */

/* Small / Common */
INSERT IGNORE INTO `items` (`item`, `label`, `limit`, `can_remove`, `type`, `usable`) VALUES
                           ('fish_bluegill_small',       'ปลาบลูกิลล์', '10', '1', 'item_standard', '0'),
                           ('fish_perch_small',          'ปลาคอน', '10', '1', 'item_standard', '0'),
                           ('fish_rockbass_small',       'ปลาร็อกแบส', '10', '1', 'item_standard', '0'),
                           ('fish_chainpickerel_small',  'ปลาพิกเคอเรลลายโซ่', '10', '1', 'item_standard', '0'),
                           ('fish_redfinpickerel_small', 'ปลาพิกเคอเรลครีบแดง', '10', '1', 'item_standard', '0'),
                           ('fish_bullheadcat_small',    'ปลาดุกหัวกระทิง', '10', '1', 'item_standard', '0');

/* Medium */
INSERT IGNORE INTO `items` (`item`, `label`, `limit`, `can_remove`, `type`, `usable`) VALUES
                           ('fish_largemouthbass_medium', 'ปลาแบสปากกว้าง', '10', '1', 'item_standard', '0'),
                           ('fish_smallmouthbass_medium', 'ปลาแบสปากเล็ก', '10', '1', 'item_standard', '0'),
                           ('fish_salmonsockeye_medium',  'ปลาแซลมอนซ็อกอาย', '10', '1', 'item_standard', '0'),
                           ('fish_rainbowtrout_medium',   'ปลาเทราต์สตีลเฮด', '10', '1', 'item_standard', '0');

/* Large */
INSERT IGNORE INTO `items` (`item`, `label`, `limit`, `can_remove`, `type`, `usable`) VALUES
                           ('fish_channelcatfish_large', 'ปลาดุกแชนแนล', '10', '1', 'item_standard', '0'),
                           ('fish_longnosegar_large',    'ปลาการ์จมูกยาว', '10', '1', 'item_standard', '0'),
                           ('fish_lakesturgeon_large',   'ปลาสเตอร์เจียนน้ำจืด', '10', '1', 'item_standard', '0'),
                           ('fish_muskie_large',         'ปลามัสกี้', '10', '1', 'item_standard', '0'),
                           ('fish_northernpike_large',   'ปลาหอกเหนือ', '10', '1', 'item_standard', '0');

/* Legendary */
INSERT IGNORE INTO `items` (`item`, `label`, `limit`, `can_remove`, `type`, `usable`) VALUES
                           ('fish_bluegill_legendary',       'ปลาบลูกิลล์ในตำนาน', '10', '1', 'item_standard', '0'),
                           ('fish_perch_legendary',          'ปลาคอนในตำนาน', '10', '1', 'item_standard', '0'),
                           ('fish_rockbass_legendary',       'ปลาร็อกแบสในตำนาน', '10', '1', 'item_standard', '0'),
                           ('fish_chainpickerel_legendary',  'ปลาพิกเคอเรลลายโซ่ในตำนาน', '10', '1', 'item_standard', '0'),
                           ('fish_redfinpickerel_legendary', 'ปลาพิกเคอเรลครีบแดงในตำนาน', '10', '1', 'item_standard', '0'),
                           ('fish_bullheadcat_legendary',    'ปลาดุกหัวกระทิงในตำนาน', '10', '1', 'item_standard', '0'),
                           ('fish_largemouthbass_legendary', 'ปลาแบสปากกว้างในตำนาน', '10', '1', 'item_standard', '0'),
                           ('fish_smallmouthbass_legendary', 'ปลาแบสปากเล็กในตำนาน', '10', '1', 'item_standard', '0'),
                           ('fish_salmonsockeye_legendary',  'ปลาแซลมอนซ็อกอายในตำนาน', '10', '1', 'item_standard', '0'),
                           ('fish_rainbowtrout_legendary',   'ปลาเทราต์สตีลเฮดในตำนาน', '10', '1', 'item_standard', '0'),
                           ('fish_channelcatfish_legendary', 'ปลาดุกแชนแนลในตำนาน', '10', '1', 'item_standard', '0'),
                           ('fish_longnosegar_legendary',    'ปลาการ์จมูกยาวในตำนาน', '10', '1', 'item_standard', '0'),
                           ('fish_lakesturgeon_legendary',   'ปลาสเตอร์เจียนน้ำจืดในตำนาน', '10', '1', 'item_standard', '0'),
                           ('fish_muskie_legendary',         'ปลามัสกี้ในตำนาน', '10', '1', 'item_standard', '0'),
                           ('fish_northernpike_legendary',   'ปลาหอกเหนือในตำนาน', '10', '1', 'item_standard', '0');
