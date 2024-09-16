CREATE TABLE `archive_entity` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `pkey` (`entity_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
