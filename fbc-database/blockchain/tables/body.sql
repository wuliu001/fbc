USE `blockchain`;

/*Table structure for table `body` */;

DROP TABLE IF EXISTS `body`;

CREATE TABLE `body` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `blockType` int(11) NOT NULL,
  `blockObject` longtext NOT NULL,
  `hasPendingGoods` tinyint(4) NOT NULL,
  `nextSCDate` datetime NOT NULL,
  `hashMerkle` varchar(256) NOT NULL,
  `parentObject` varchar(300) NOT NULL,
  `timestamp` bigint(20) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;
