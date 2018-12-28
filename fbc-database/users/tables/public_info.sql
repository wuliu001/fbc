USE `users`;

/*Table structure for table `public_info` */;

DROP TABLE IF EXISTS `public_info`;

CREATE TABLE `public_info` (
  `id` varchar(50) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password` varchar(50) NOT NULL,
  `corporation_name` varchar(100) NOT NULL,
  `owner` varchar(50) NOT NULL,
  `address` varchar(1600) NOT NULL,
  `company_register_date` datetime NOT NULL,
  `registered_capital` int(11) NOT NULL,
  `annual_income` int(11) NOT NULL,
  `tel_num` varchar(50) NOT NULL,
  `email` varchar(200) NOT NULL,
  `create_time` datetime NOT NULL,
  `last_update_time` datetime NOT NULL,
  `last_login_time` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`),
  UNIQUE KEY `username_UNIQUE` (`username`)
) ENGINE=InnoDB;
