-- ══════════════════════════════════════════════════════════════
--  lp_marketplace — รัน SQL นี้ครั้งเดียวก่อน ensure resource
-- ══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS `lp_marketplace` (
  `id`          INT          NOT NULL AUTO_INCREMENT,
  `seller_id`   VARCHAR(64)  NOT NULL,               -- charIdentifier ของผู้ขาย
  `seller_name` VARCHAR(64)  NOT NULL,
  `buyer_id`    VARCHAR(64)  DEFAULT NULL,           -- charIdentifier ของผู้ซื้อ
  `buyer_name`  VARCHAR(64)  DEFAULT NULL,
  `item_name`   VARCHAR(64)  NOT NULL,
  `item_label`  VARCHAR(128) NOT NULL,
  `category`    VARCHAR(32)  NOT NULL DEFAULT 'general',
  `quantity`    INT          NOT NULL,
  `price`       INT          NOT NULL,               -- ราคาต่อชิ้น
  `currency`    VARCHAR(16)  NOT NULL,                -- 'money' | 'gold'
  `status`      VARCHAR(16)  NOT NULL DEFAULT 'active', -- active | sold | cancelled | expired
  `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `sold_at`     DATETIME     DEFAULT NULL,
  `expires_at`  DATETIME     NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `idx_status`        (`status`),
  INDEX `idx_seller_status` (`seller_id`, `status`),
  INDEX `idx_status_expiry` (`status`, `expires_at`),
  INDEX `idx_category`      (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
