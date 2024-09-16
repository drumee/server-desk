CREATE TABLE `content_tag` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `language` varchar(50) NOT NULL,
  `type` enum('block','folder','link','video','image','audio','document','stylesheet','other') NOT NULL,
  `status` enum('online','offline') DEFAULT NULL,
  `name` varchar(500) NOT NULL,
  `description` varchar(1024) NOT NULL,
  `ctime` int(11) NOT NULL,
  `rank` int(8) NOT NULL,
  `group_rank` int(8) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
