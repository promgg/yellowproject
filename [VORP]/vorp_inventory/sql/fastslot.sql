-- ตาราง fast slot / hotbar แบบเปิด (แทนระบบใน MJDevFastSlot.lua ตัวเข้ารหัสเดิม)
-- ผูกช่องกับตัวละคร (charidentifier) เพื่อให้ช่องอยู่ครบหลัง relog / สลับตัวละคร / รีสตาร์ท resource
-- เก็บ "ชื่อไอเทม + metadata" ไม่เก็บ item id เพราะ id ของ vorp_inventory เปลี่ยนทุก session
CREATE TABLE IF NOT EXISTS `vorp_fastslots` (
  `charidentifier` INT(11)      NOT NULL,
  `slot`           INT(11)      NOT NULL,
  `item_name`      VARCHAR(100) NOT NULL,
  `item_type`      VARCHAR(30)  NOT NULL DEFAULT 'item_standard',
  `metadata`       LONGTEXT     DEFAULT NULL,
  PRIMARY KEY (`charidentifier`, `slot`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Favorite, category filter and sort mode are stored per character.
-- The resource also creates this table automatically on startup.
CREATE TABLE IF NOT EXISTS `vorp_inventory_preferences` (
  `charidentifier`  INT(11)     NOT NULL,
  `sort_mode`       VARCHAR(20) NOT NULL DEFAULT 'category',
  `category_filter` VARCHAR(20) NOT NULL DEFAULT 'all',
  `favorites`       LONGTEXT    DEFAULT NULL,
  PRIMARY KEY (`charidentifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
