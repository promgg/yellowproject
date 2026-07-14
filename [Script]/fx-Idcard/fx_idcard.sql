CREATE TABLE IF NOT EXISTS `fx_idcard` (
    `charid` varchar(64) NOT NULL,
    `data` longtext NOT NULL,
    `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
    PRIMARY KEY (`charid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
