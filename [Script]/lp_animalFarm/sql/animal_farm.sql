-- ══════════════════════════════════════════════════════════════
--  AnimalFarm — รัน SQL นี้ครั้งเดียวก่อน ensure resource
-- ══════════════════════════════════════════════════════════════

-- 1. ตาราง animal_farm
CREATE TABLE IF NOT EXISTS `animal_farm` (
  `id`         INT       NOT NULL AUTO_INCREMENT,
  `char_id`    INT       NOT NULL,
  `zone_type`  VARCHAR(32) NOT NULL,
  `slot`       TINYINT   NOT NULL,
  `state`      VARCHAR(16) NOT NULL DEFAULT 'feed',
  `hp`         TINYINT   NOT NULL DEFAULT 100,
  `exp`        TINYINT   NOT NULL DEFAULT 0,
  `last_fed`   INT       NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_slot`       (`char_id`, `zone_type`, `slot`),
  INDEX  `idx_char_zone`     (`char_id`, `zone_type`),
  INDEX  `idx_state_lastfed` (`state`, `last_fed`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. ไอเทม large_meat (เนื้อขนาดใหญ่ — ใช้เลี้ยงสัตว์และรับเป็น reward)
INSERT INTO `items` (`item`, `label`, `limit`, `weight`, `can_remove`, `type`, `usable`, `groupId`, `metadata`, `desc`, `degradation`)
SELECT 'large_meat', 'Large Meat', 50, 1.0, 1, 'item_standard', 0, 1, '{}', 'Large chunk of raw meat used for feeding animals.', 0
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `item` = 'large_meat');
