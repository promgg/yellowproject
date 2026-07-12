CREATE TABLE IF NOT EXISTS `nx_graverobbery_graves` (
    `grave_id` VARCHAR(100) NOT NULL,
    `village_id` VARCHAR(100) NOT NULL,
    `looted_at` DATETIME NULL,
    `available_at` DATETIME NULL,
    `looted_by_character` VARCHAR(100) NULL,
    PRIMARY KEY (`grave_id`),
    INDEX `idx_nx_graverobbery_available_at` (`available_at`),
    INDEX `idx_nx_graverobbery_village_id` (`village_id`)
);

CREATE TABLE IF NOT EXISTS `nx_graverobbery_security_log` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `source` INT NULL,
    `identifier` VARCHAR(100) NULL,
    `character_id` VARCHAR(100) NULL,
    `grave_id` VARCHAR(100) NULL,
    `village_id` VARCHAR(100) NULL,
    `event_name` VARCHAR(100) NOT NULL,
    `reason` VARCHAR(255) NOT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_nx_graverobbery_security_created` (`created_at`)
);
