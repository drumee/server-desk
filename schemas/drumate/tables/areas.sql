CREATE TABLE `areas` (
  `id` varbinary(16) NOT NULL,
  `name` varchar(30) NOT NULL,
  `order` tinyint(4) NOT NULL DEFAULT 1,
  `level` enum('public','restricted','private') NOT NULL DEFAULT 'private',
  PRIMARY KEY (`id`),
  UNIQUE KEY `level` (`level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
