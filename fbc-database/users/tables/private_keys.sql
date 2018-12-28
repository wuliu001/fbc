USE `users`;

/*Table structure for table `private_keys` */;

DROP TABLE IF EXISTS `private_keys`;

CREATE TABLE `private_keys` (
  `id` varchar(50) NOT NULL,
  `private_key` text NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB;
