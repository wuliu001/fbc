USE `centerdb`;

/*Table structure for table `smartcontracts` */;

DROP TABLE IF EXISTS `smartcontracts`;

CREATE TABLE `smartcontracts` (
  `id`              BIGINT(20) NOT NULL AUTO_INCREMENT,
  `accountAddress`  VARCHAR(256) NOT NULL,
  `gas`             FLOAT NOT NULL,
  `nonce`           INT(11) NOT NULL,
  PRIMARY KEY       (`id`)
) ENGINE=InnoDB;
