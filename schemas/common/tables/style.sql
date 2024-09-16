CREATE TABLE `style` (
  `id` int(8) NOT NULL AUTO_INCREMENT,
  `name` varchar(80) NOT NULL DEFAULT 'My Style',
  `class_name` varchar(100) DEFAULT NULL,
  `selector` varchar(255) NOT NULL,
  `declaration` varchar(12000) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `comment` varchar(255) NOT NULL DEFAULT 'xxx',
  `status` enum('active','frozen') CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT 'active',
  PRIMARY KEY (`id`),
  KEY `className` (`selector`),
  KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
