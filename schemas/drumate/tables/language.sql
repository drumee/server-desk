CREATE TABLE `language` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `base` varchar(10) NOT NULL,
  `name` varchar(100) NOT NULL,
  `locale` varchar(100) NOT NULL,
  `state` enum('deleted','active','frozen','replaced') NOT NULL,
  `ctime` int(11) NOT NULL,
  `mtime` int(11) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `locale` (`locale`),
  KEY `base` (`base`),
  KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
