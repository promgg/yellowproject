-- ═══════════════════════════════════════════════════════════════════════════
--  lp_planting — ตารางเก็บต้นไม้ที่ปลูกไว้
--
--  เหตุที่ต้องมี: MJ-Planting เดิมเก็บใน memory ล้วน รีสตาร์ทเซิร์ฟทีต้นหายหมด
--  และผู้เล่นที่หลุดออกไปก็เสียเมล็ดฟรี (record ถูกลบตอน playerDropped)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS `lp_planting` (
    `id`             INT          NOT NULL AUTO_INCREMENT,

    -- เจ้าของเป็น "ตัวละคร" ไม่ใช่บัญชี — คนละตัวละครในบัญชีเดียวกันแยกแปลงกัน
    -- (ของเดิมใช้ server id ซึ่งเปลี่ยนทุกครั้งที่เข้าใหม่ ต้นจึงไม่มีวันกลับมา)
    `charidentifier` INT          NOT NULL,

    `zone_id`        VARCHAR(50)  NOT NULL  COMMENT 'คีย์ใน Config.Zones',

    -- เก็บ "ชื่อเมล็ด" ไม่ใช่เลขลำดับใน config — สลับ/แทรกรายการใน config ทีหลัง
    -- แล้วต้นที่ปลูกค้างไว้จะไม่ชี้ผิดพืช
    `seed`           VARCHAR(50)  NOT NULL,

    `stage`          VARCHAR(16)  NOT NULL DEFAULT 'fertilize'
                     COMMENT 'fertilize -> water -> grow',

    `x`              DOUBLE       NOT NULL,
    `y`              DOUBLE       NOT NULL,
    `z`              DOUBLE       NOT NULL,
    `heading`        FLOAT        NOT NULL DEFAULT 0,

    -- unix timestamp (os.time) ไม่ใช่ GetGameTimer ที่รีเซ็ตทุกครั้งที่รีสตาร์ท
    `planted_at`     INT UNSIGNED NOT NULL  COMMENT 'ใช้นับ timeout 24 ชม.',
    `watered_at`     INT UNSIGNED     NULL  COMMENT 'ใช้นับเวลาโต NULL = ยังไม่ได้รดน้ำ',

    PRIMARY KEY (`id`),
    INDEX `idx_char`    (`charidentifier`),
    INDEX `idx_zone`    (`zone_id`),
    INDEX `idx_planted` (`planted_at`)   -- ใช้ตอนกวาดต้นหมดอายุ
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='lp_planting: ต้นไม้ที่ผู้เล่นปลูกค้างไว้';
