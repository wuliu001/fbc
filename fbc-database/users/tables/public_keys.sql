USE `users`;

/*Table structure for table `public_keys` */;

DROP TABLE IF EXISTS `public_keys`;

CREATE TABLE `public_keys` (
  `ID` varchar(50) NOT NULL,
  `public_key` text NOT NULL,
  `create_time` datetime NOT NULL,
  `is_sync` int(11) NOT NULL,
  `last_be_sync_time` datetime NOT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `ID_UNIQUE` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
