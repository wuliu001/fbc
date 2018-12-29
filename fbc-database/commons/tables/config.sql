USE `commons`;

/*Table structure for table `config` */;

DROP TABLE IF EXISTS `config`;

CREATE TABLE `config` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `code` varchar(50) NOT NULL,
  `value` varchar(100)  NOT NULL,
  `description` text ,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;
