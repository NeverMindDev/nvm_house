CREATE TABLE IF NOT EXISTS `nvm_houses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `owner` varchar(50) NOT NULL,
  `house_coords` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`house_coords`)),
  `garage_coords` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`garage_coords`)),
  `interior` int(11) NOT NULL,
  `is_locked` tinyint(1) DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

CREATE TABLE IF NOT EXISTS `nvm_houses_keys` (
  `id` int(20) NOT NULL AUTO_INCREMENT,
  `house_id` int(20) DEFAULT NULL,
  `player_identifier` varchar(50) DEFAULT NULL,
  `player_name` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `house_id` (`house_id`),
  CONSTRAINT `nvm_houses_keys_ibfk_1` FOREIGN KEY (`house_id`) REFERENCES `nvm_houses` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;