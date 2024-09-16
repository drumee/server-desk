CREATE TABLE `seo_object` (
  `sys_id` int(11) NOT NULL AUTO_INCREMENT,
  `hub_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `nid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `node` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`node`)),
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `key` (`hub_id`,`nid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
