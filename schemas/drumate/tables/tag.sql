CREATE TABLE `tag` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `tag_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `parent_tag_id` varchar(16) DEFAULT NULL,
  `name` varchar(255) NOT NULL,
  `position` int(11) unsigned DEFAULT 0,
  `ctime` int(11) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `name` (`name`),
  UNIQUE KEY `tag_id` (`tag_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
