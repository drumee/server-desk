CREATE TABLE `permission` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `resource_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `entity_id` varchar(512) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `message` mediumtext DEFAULT NULL,
  `expiry_time` int(11) NOT NULL DEFAULT 0,
  `ctime` int(11) DEFAULT NULL,
  `utime` int(11) DEFAULT NULL,
  `permission` tinyint(4) unsigned NOT NULL,
  `assign_via` enum('system','link','share','no_traversal','root') DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `pkey` (`resource_id`,`entity_id`),
  KEY `entity_id` (`entity_id`),
  KEY `permission` (`permission`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
