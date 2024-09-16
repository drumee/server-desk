CREATE TABLE `contact_phone` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varchar(16) NOT NULL,
  `areacode` varchar(255) DEFAULT '',
  `phone` varchar(255) DEFAULT NULL,
  `category` enum('prof','priv') NOT NULL DEFAULT 'priv',
  `contact_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `ctime` int(11) NOT NULL,
  `mtime` int(11) NOT NULL,
  PRIMARY KEY (`sys_id`),
  KEY `id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
