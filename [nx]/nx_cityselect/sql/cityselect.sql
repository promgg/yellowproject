-- nx_cityselect Database Tables
-- Run this once before starting the resource

CREATE TABLE IF NOT EXISTS `nx_player_city` (
    `identifier`     VARCHAR(60)  NOT NULL COMMENT 'Steam/License identifier',
    `charidentifier` INT(11)      NOT NULL COMMENT 'VORP Character ID',
    `city_id`        VARCHAR(50)  NOT NULL COMMENT 'City ID matching config',
    `selected_at`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`identifier`, `charidentifier`),
    INDEX `idx_city_id` (`city_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Permanent player city assignments';

CREATE TABLE IF NOT EXISTS `nx_player_heritage` (
    `identifier`     VARCHAR(60)  NOT NULL COMMENT 'Steam/License identifier',
    `charidentifier` INT(11)      NOT NULL COMMENT 'VORP Character ID',
    `heritage_id`    VARCHAR(50)  NOT NULL COMMENT 'Heritage ID matching config (white/native)',
    `selected_at`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`identifier`, `charidentifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Permanent player heritage/crafting-lineage assignments';

CREATE TABLE IF NOT EXISTS `nx_city_slots` (
    `city_id`       VARCHAR(50) NOT NULL COMMENT 'City ID matching config',
    `current_count` INT(11)     NOT NULL DEFAULT 0 COMMENT 'Current cycle registration count',
    `updated_at`    TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`city_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='City slot counters per registration cycle';

-- Seed initial slot rows (insert for each city_id defined in config.lua)
INSERT IGNORE INTO `nx_city_slots` (`city_id`, `current_count`) VALUES
    ('valentine',   0),
    ('blackwater',  0),
    ('rhodes',      0);

-- Items - insert into VORP items table (adjust table name if different)
INSERT IGNORE INTO `items` (`item`, `label`, `limit`, `can_remove`, `type`, `usable`, `desc`) VALUES
    ('mj_badge_valentine',  'บัตรประจำเมือง Valentine',  1, 0, 'item', 1, 'บัตรประจำเมืองสำหรับชาว Valentine'),
    ('mj_badge_blackwater', 'บัตรประจำเมือง Blackwater', 1, 0, 'item', 1, 'บัตรประจำเมืองสำหรับชาว Blackwater'),
    ('mj_badge_rhodes',     'บัตรประจำเมือง Rhodes',     1, 0, 'item', 1, 'บัตรประจำเมืองสำหรับชาว Rhodes');
