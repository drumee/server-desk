CREATE TABLE `contact_email` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varchar(16) NOT NULL,
  `email` varchar(255) DEFAULT NULL,
  `category` enum('prof','priv') NOT NULL DEFAULT 'priv',
  `is_default` tinyint(4) NOT NULL DEFAULT 0,
  `contact_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `ctime` int(11) NOT NULL,
  `mtime` int(11) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `email` (`email`,`id`),
  UNIQUE KEY `email_contact_id` (`email`,`contact_id`),
  KEY `idx_contactid_default` (`contact_id`,`is_default`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
