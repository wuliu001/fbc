USE `blockchain_cache`;

/*Table structure for table `block` */;

DROP TABLE IF EXISTS `block`;

CREATE TABLE `block` (
  `user` varchar(50) NOT NULL,
  `transactionType` varchar(32) NOT NULL,
  `blockObject` longtext NOT NULL,
  `hashSign` varchar(256) NOT NULL,
  `timestamp` bigint(20) NOT NULL,
  `comfirmedTimes` int(11) NOT NULL
) ENGINE=InnoDB;
