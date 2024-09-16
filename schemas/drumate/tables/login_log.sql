CREATE TABLE `login_log` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `cookie_id` varchar(64) NOT NULL,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`)),
  `intime` int(11) DEFAULT NULL,
  `outtime` int(11) DEFAULT NULL,
  PRIMARY KEY (`sys_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
