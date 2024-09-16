CREATE TABLE `seo` (
  `sys_id` int(11) NOT NULL AUTO_INCREMENT,
  `ctime` int(11) unsigned DEFAULT NULL,
  `occurrence` int(6) unsigned DEFAULT 1,
  `word` varchar(300) NOT NULL,
  `hub_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `nid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `key` (`word`,`hub_id`,`nid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
