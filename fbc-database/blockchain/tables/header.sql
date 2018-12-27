USE `blockchain`;

/*Table structure for table `header` */;

DROP TABLE IF EXISTS `header`;

CREATE TABLE `header` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `version` int(11) NOT NULL,
  `hashPrevBlock` varchar(256) NOT NULL,
  `hashMerkleRoot` varchar(256) NOT NULL,
  `timestamp` bigint(20) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;
