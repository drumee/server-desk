CREATE TABLE `thread` (
  `sys_id` int(11) NOT NULL AUTO_INCREMENT,
  `master_id` varbinary(16) NOT NULL,
  `type` enum('block','media','comment') CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `name` varchar(256) NOT NULL,
  `device` enum('desktop','tablet','mobile') CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT 'desktop',
  `lang` varchar(10) CHARACTER SET armscii8 COLLATE armscii8_general_ci NOT NULL,
  `author_id` varbinary(16) NOT NULL,
  `comment` varchar(256) NOT NULL,
  `ctime` int(11) NOT NULL,
  PRIMARY KEY (`sys_id`),
  KEY `type` (`type`),
  KEY `master_id` (`master_id`),
  KEY `comment` (`comment`),
  KEY `author_id` (`author_id`),
  KEY `ctime` (`ctime`),
  KEY `device` (`device`),
  KEY `lang` (`lang`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
