CREATE TABLE `map_agenda` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `agenda_id` varchar(16) NOT NULL,
  `contact_id` varchar(16) NOT NULL,
  `uid` varchar(16) DEFAULT NULL,
  `ctime` int(11) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `agenda_contact` (`agenda_id`,`contact_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
