CREATE TABLE `action_log` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `uid` varchar(16) NOT NULL,
  `action` enum('added','deleted','changed','left','removed','backup','connection') DEFAULT NULL,
  `category` enum('media','permission','member','admin','title') NOT NULL,
  `notify_to` enum('all','member','admin') NOT NULL,
  `entity_id` varchar(16) DEFAULT NULL,
  `log` varchar(1000) NOT NULL,
  `ctime` int(11) NOT NULL,
  PRIMARY KEY (`sys_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
