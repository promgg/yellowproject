/* MJ-AfkFishing fish items — migrated 2026-07-09 from a_c_fish*/legendary_* to fish_<species>_<size|legendary>
   Run this against your server DB before starting MJ-AfkFishing with the renamed config.lua.
   Icons: copy matching files in vorp_inventory/html/img/items/ (see icon-copy step run alongside this migration). */

/* Small / Common */
INSERT IGNORE INTO `items` (`item`, `label`, `limit`, `can_remove`, `type`, `usable`) VALUES
                           ('fish_bluegill_small',       'Blue Gil (Small)', '10', '1', 'item_standard', '0'),
                           ('fish_perch_small',          'Perch (Small)', '10', '1', 'item_standard', '0'),
                           ('fish_rockbass_small',       'Rock Bass (Small)', '10', '1', 'item_standard', '0'),
                           ('fish_chainpickerel_small',  'Chain Pickerel (Small)', '10', '1', 'item_standard', '0'),
                           ('fish_redfinpickerel_small', 'Red Fin Pickerel (Small)', '10', '1', 'item_standard', '0'),
                           ('fish_bullheadcat_small',    'Bullhead Cat (Small)', '10', '1', 'item_standard', '0');

/* Medium */
INSERT IGNORE INTO `items` (`item`, `label`, `limit`, `can_remove`, `type`, `usable`) VALUES
                           ('fish_largemouthbass_medium', 'Large Mouth Bass (Medium)', '10', '1', 'item_standard', '0'),
                           ('fish_smallmouthbass_medium', 'Small Mouth Bass (Medium)', '10', '1', 'item_standard', '0'),
                           ('fish_salmonsockeye_medium',  'Salmon Sockeye (Medium)', '10', '1', 'item_standard', '0'),
                           ('fish_rainbowtrout_medium',   'Rainbow Trout (Medium)', '10', '1', 'item_standard', '0');

/* Large */
INSERT IGNORE INTO `items` (`item`, `label`, `limit`, `can_remove`, `type`, `usable`) VALUES
                           ('fish_channelcatfish_large', 'Channel Catfish (Large)', '10', '1', 'item_standard', '0'),
                           ('fish_longnosegar_large',    'Long Nose Gar (Large)', '10', '1', 'item_standard', '0'),
                           ('fish_lakesturgeon_large',   'Lake Sturgeon (Large)', '10', '1', 'item_standard', '0'),
                           ('fish_muskie_large',         'Muskie (Large)', '10', '1', 'item_standard', '0'),
                           ('fish_northernpike_large',   'Northern Pike (Large)', '10', '1', 'item_standard', '0');

/* Legendary — previously had NO label/DB entry at all (borrowed a normal fish's icon via config `icon=`).
   Labels below are best-effort ("Legendary " + base fish name), same as shown in Alljob.md before this migration. */
INSERT IGNORE INTO `items` (`item`, `label`, `limit`, `can_remove`, `type`, `usable`) VALUES
                           ('fish_bluegill_legendary',       'Legendary Blue Gil', '10', '1', 'item_standard', '0'),
                           ('fish_perch_legendary',          'Legendary Perch', '10', '1', 'item_standard', '0'),
                           ('fish_rockbass_legendary',       'Legendary Rock Bass', '10', '1', 'item_standard', '0'),
                           ('fish_chainpickerel_legendary',  'Legendary Chain Pickerel', '10', '1', 'item_standard', '0'),
                           ('fish_redfinpickerel_legendary', 'Legendary Red Fin Pickerel', '10', '1', 'item_standard', '0'),
                           ('fish_bullheadcat_legendary',    'Legendary Bullhead Cat', '10', '1', 'item_standard', '0'),
                           ('fish_largemouthbass_legendary', 'Legendary Large Mouth Bass', '10', '1', 'item_standard', '0'),
                           ('fish_smallmouthbass_legendary', 'Legendary Small Mouth Bass', '10', '1', 'item_standard', '0'),
                           ('fish_salmonsockeye_legendary',  'Legendary Salmon Sockeye', '10', '1', 'item_standard', '0'),
                           ('fish_rainbowtrout_legendary',   'Legendary Rainbow Trout', '10', '1', 'item_standard', '0'),
                           ('fish_channelcatfish_legendary', 'Legendary Channel Catfish', '10', '1', 'item_standard', '0'),
                           ('fish_longnosegar_legendary',    'Legendary Long Nose Gar', '10', '1', 'item_standard', '0'),
                           ('fish_lakesturgeon_legendary',   'Legendary Lake Sturgeon', '10', '1', 'item_standard', '0'),
                           ('fish_muskie_legendary',         'Legendary Muskie', '10', '1', 'item_standard', '0'),
                           ('fish_northernpike_legendary',   'Legendary Northern Pike', '10', '1', 'item_standard', '0');
