CREATE TABLE `agenda` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `agenda_id` varchar(16) NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `place` varchar(255) DEFAULT NULL,
  `owner_id` varchar(16) NOT NULL,
  `category` enum('own','other') NOT NULL,
  `stime` int(11) NOT NULL,
  `etime` int(11) DEFAULT NULL,
  `calendar_id` varchar(16) DEFAULT NULL,
  `ctime` int(11) NOT NULL,
  `mtime` int(11) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `agenda_id` (`agenda_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
