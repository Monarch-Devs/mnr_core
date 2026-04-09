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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `char_slots` (
    `userId` INT UNSIGNED NOT NULL,
    `slots` TINYINT UNSIGNED NOT NULL DEFAULT 2,
    PRIMARY KEY (`userId`),
    FOREIGN KEY (`userId`) REFERENCES `users`(`userId`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `char_docs` (
    `charId` INT UNSIGNED NOT NULL,
    `type` VARCHAR(64) NOT NULL,
    `issued_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `expires_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`charId`, `type`),
    FOREIGN KEY (`charId`) REFERENCES `characters`(`charId`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `char_money` (
    `charId` INT UNSIGNED NOT NULL,
    `money` INT UNSIGNED NOT NULL DEFAULT 0,
    `bank` INT UNSIGNED NOT NULL DEFAULT 0,
    `black_money` INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`charId`),
    FOREIGN KEY (`charId`) REFERENCES `characters`(`charId`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `char_groups` (
    `charId` INT UNSIGNED NOT NULL,
    `slot` TINYINT UNSIGNED NOT NULL,
    `cat` VARCHAR(32) NOT NULL,
    `name` VARCHAR(64) NOT NULL,
    `grade` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `duty` TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (`charId`, `slot`),
    UNIQUE KEY `unique_group_name` (`charId`, `name`),
    FOREIGN KEY (`charId`) REFERENCES `characters`(`charId`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `char_status` (
    `charId` INT UNSIGNED NOT NULL,
    `health` TINYINT UNSIGNED NOT NULL DEFAULT 200,
    `armor` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `hunger` TINYINT UNSIGNED NOT NULL DEFAULT 100,
    `thirst` TINYINT UNSIGNED NOT NULL DEFAULT 100,
    `stress` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`charId`),
    FOREIGN KEY (`charId`) REFERENCES `characters`(`charId`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `char_position` (
    `charId` INT UNSIGNED NOT NULL,
    `x` FLOAT NOT NULL,
    `y` FLOAT NOT NULL,
    `z` FLOAT NOT NULL,
    `w` FLOAT NOT NULL,
    PRIMARY KEY (`charId`),
    FOREIGN KEY (`charId`) REFERENCES `characters`(`charId`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `groups` (
    `name` VARCHAR(64) NOT NULL,
    `label` VARCHAR(64) NOT NULL,
    `cat` VARCHAR(32) NOT NULL,
    PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `group_grades` (
    `group_name` VARCHAR(64)  NOT NULL,
    `grade` TINYINT UNSIGNED NOT NULL,
    `label` VARCHAR(64)  NOT NULL,
    PRIMARY KEY (`group_name`, `grade`),
    FOREIGN KEY (`group_name`) REFERENCES `groups`(`name`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;