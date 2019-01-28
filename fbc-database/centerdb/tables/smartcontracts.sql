USE `centerdb`;

/*Table structure for table `smartcontracts` */;

DROP TABLE IF EXISTS `smartcontracts`;

CREATE TABLE `smartcontracts` (
  `accountAddress`  VARCHAR(256) NOT NULL,
  PRIMARY KEY       (`accountAddress`)
) ENGINE=InnoDB;
