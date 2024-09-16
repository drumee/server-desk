CREATE TABLE `font_face` (
  `sys_id` int(6) NOT NULL AUTO_INCREMENT,
  `family` varchar(80) NOT NULL,
  `style` varchar(30) NOT NULL,
  `weight` int(2) NOT NULL DEFAULT 400,
  `local1` varchar(80) NOT NULL,
  `local2` varchar(80) NOT NULL,
  `url` varchar(1024) NOT NULL,
  `format` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `unicode_range` varchar(20) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `comment` varchar(160) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `family` (`family`,`weight`),
  KEY `format` (`format`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
