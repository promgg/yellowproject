/* MJ-AfkFishing rod + bait items — job_fishing_rod / job_fishing_bait
   (fixes a typo carried over from nx_shop's old "jop_fishing_*" item ids)
   Labels match nx_shop/shared/config.lua's General Store listing.
   Skip this file if you already registered these items manually in your DB. */

INSERT IGNORE INTO `items` (`item`, `label`, `limit`, `can_remove`, `type`, `usable`) VALUES
                           ('job_fishing_rod', 'เบ็ดตกปลา', '1', '1', 'item_standard', '0'),
                           ('job_fishing_bait', 'เหยื่อตกปลา', '20', '1', 'item_standard', '0');
