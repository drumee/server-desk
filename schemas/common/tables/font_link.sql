CREATE TABLE `font_link` (
  `sys_id` int(11) NOT NULL AUTO_INCREMENT,
  `family` varchar(256) DEFAULT NULL,
  `name` varchar(128) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `variant` varchar(128) DEFAULT NULL,
  `url` varchar(1024) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `status` enum('active','frozen') CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT 'active',
  `ctime` int(11) NOT NULL,
  `mtime` int(11) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `family` (`family`),
  KEY `url` (`url`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
