-- ============================================================
--  MJ-Mailboard | Database DDL
--  Discord: https://discord.gg/gHRNMDQKzb
--  Version : 1.0
-- ============================================================

CREATE TABLE IF NOT EXISTS `mailboard_posts` (
    `id`         INT          NOT NULL AUTO_INCREMENT  COMMENT 'Primary key, auto increment',
    `identifier` VARCHAR(64)  NOT NULL                 COMMENT 'Player identifier (steam/license)',
    `charname`   VARCHAR(100) NOT NULL                 COMMENT 'Character full name (firstname + lastname)',
    `text`       TEXT         NOT NULL                 COMMENT 'Post content / message',
    `image`      TEXT             NULL DEFAULT NULL    COMMENT 'Optional image URL or base64',
    `time`       INT UNSIGNED NOT NULL                 COMMENT 'Unix timestamp of post creation',
    PRIMARY KEY (`id`),
    INDEX `idx_identifier` (`identifier`),
    INDEX `idx_time`       (`time`)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='MJ-Mailboard posts board';
