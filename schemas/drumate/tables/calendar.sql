CREATE TABLE `calendar` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `calendar_id` varchar(16) NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `color` varchar(10) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `category` enum('own','other') NOT NULL,
  `owner_id` varchar(16) NOT NULL,
  `is_selected` tinyint(1) DEFAULT 0,
  `is_default` tinyint(1) DEFAULT 0,
  `ctime` int(11) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `calendar_id` (`calendar_id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
