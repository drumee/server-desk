CREATE TABLE `hashtag` (
  `label` varchar(100) NOT NULL,
  `hash_id` varbinary(16) NOT NULL,
  `ctime` int(11) NOT NULL,
  `mtime` int(11) NOT NULL,
  KEY `label` (`label`,`hash_id`),
  KEY `ctime` (`ctime`,`mtime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
