
CREATE TABLE IF NOT EXISTS `items` (
  `item` varchar(50) NOT NULL,
  `label` varchar(50) NOT NULL,
  `limit` int(11) NOT NULL DEFAULT 1,
  `can_remove` tinyint(1) NOT NULL DEFAULT 1,
  `type` varchar(50) DEFAULT NULL,
  `usable` tinyint(1) DEFAULT NULL,
  `id` int(11) NOT NULL,
  `groupId` int(10) UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Item Group ID for Filtering',
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT '{}',
  `desc` varchar(5550) NOT NULL DEFAULT 'nice item'
) ;

INSERT ignore INTO `items` (`item`, `label`, `limit`, `can_remove`, `type`, `usable`, `id`, `groupId`, `metadata`, `desc`) VALUES
('Outfit', 'Outfit', 1, 1, 'item_standard', 1, 2023, 1, '{}', 'Outfit');

ALTER TABLE `items`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

