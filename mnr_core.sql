CREATE TABLE IF NOT EXISTS `users` (
    `userId` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
    `license` VARCHAR(50) DEFAULT NULL,
    `license2` VARCHAR(50) NOT NULL UNIQUE,
    `fivem` VARCHAR(20) DEFAULT NULL,
    `steam` VARCHAR(30) DEFAULT NULL,
    `discord` VARCHAR(30) DEFAULT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `last_login` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`userId`)
); ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `char_slots` (
    `userId` INT UNSIGNED NOT NULL,
    `slots` TINYINT UNSIGNED NOT NULL DEFAULT 2,
    PRIMARY KEY (`userId`),
    FOREIGN KEY (`userId`) REFERENCES `users`(`userId`) ON DELETE CASCADE
); ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `characters` (
    `charId` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `userId` INT UNSIGNED NOT NULL,
    `slot` TINYINT UNSIGNED NOT NULL,
    `firstname` VARCHAR(50) NOT NULL,
    `lastname` VARCHAR(50) NOT NULL,
    `gender` ENUM('M', 'F', 'X') NOT NULL,
    `origin` VARCHAR(50) NOT NULL,
    `birthdate` DATE NOT NULL,
    PRIMARY KEY (`charId`),
    FOREIGN KEY (`userId`) REFERENCES `users`(`userId`) ON DELETE CASCADE,
    UNIQUE KEY `unique_user_slot` (`userId`, `slot`)
); ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `char_position` (
    `charId` INT UNSIGNED NOT NULL,
    `x` FLOAT NOT NULL,
    `y` FLOAT NOT NULL,
    `z` FLOAT NOT NULL,
    `w` FLOAT NOT NULL,
    PRIMARY KEY (`charId`),
    FOREIGN KEY (`charId`) REFERENCES `characters`(`charId`) ON DELETE CASCADE
); ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;