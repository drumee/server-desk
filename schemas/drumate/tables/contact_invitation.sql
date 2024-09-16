CREATE TABLE `contact_invitation` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `uid` varchar(16) NOT NULL,
  `bound` enum('out','in') NOT NULL DEFAULT 'out',
  `status` enum('refuse','accept','pending','delete','inform') NOT NULL,
  `ctime` int(11) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `uid_bound` (`uid`,`bound`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
