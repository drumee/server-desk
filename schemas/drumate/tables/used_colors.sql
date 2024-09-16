CREATE TABLE `used_colors` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `rgba` varchar(50) NOT NULL,
  `hexacode` varchar(20) NOT NULL,
  `ctime` int(11) NOT NULL,
  PRIMARY KEY (`sys_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
