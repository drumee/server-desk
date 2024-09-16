CREATE TABLE `time_channel` (
  `entity_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `ref_sys_id` int(11) unsigned NOT NULL,
  `message` mediumtext DEFAULT NULL,
  `ctime` int(11) NOT NULL,
  PRIMARY KEY (`entity_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
