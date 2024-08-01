CREATE TABLE IF NOT EXISTS `nvm_houses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `bidentifier` varchar(50) NOT NULL,
  `bname` varchar(50) NOT NULL,
  `oidentifier` varchar(50) DEFAULT NULL,
  `oname` varchar(50) DEFAULT NULL,
  `house_coords` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`house_coords`)),
  `garage_coords` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`garage_coords`)),
  `interior` int(11) NOT NULL,
  `is_locked` tinyint(1) DEFAULT 1,
  `is_buyable` tinyint(1) DEFAULT 1,
  `price` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

CREATE TABLE IF NOT EXISTS `nvm_houses_keys` (
  `id` int(20) NOT NULL AUTO_INCREMENT,
  `house_id` int(11) DEFAULT NULL,
  `identifier` varchar(50) DEFAULT NULL,
  `name` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `house_id` (`house_id`),
  CONSTRAINT `nvm_houses_keys_ibfk_1` FOREIGN KEY (`house_id`) REFERENCES `nvm_houses` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
