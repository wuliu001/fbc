USE `transaction_cache`;

/*Table structure for table `block` */;

DROP TABLE IF EXISTS `block`;

CREATE TABLE `block` (
  `id`              BIGINT(20) NOT NULL AUTO_INCREMENT,
  `accountAddress`  VARCHAR(256) NOT NULL,
  `transactionType` VARCHAR(32) NOT NULL,
  `blockObject`     LONGTEXT NOT NULL,
  `hashSign`        VARCHAR(256) NOT NULL,
  `timestamp`       BIGINT(20) NOT NULL,
  `comfirmedTimes`  INT(11) NOT NULL,
  PRIMARY KEY       (`id`)
) ENGINE=InnoDB;
