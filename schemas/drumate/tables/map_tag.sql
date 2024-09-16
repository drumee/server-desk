CREATE TABLE `map_tag` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `tag_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `category` enum('group','contact') NOT NULL,
  `mode` enum('chat','mail') NOT NULL,
  `ctime` int(11) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`,`tag_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
