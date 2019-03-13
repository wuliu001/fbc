USE `contract_match`;

/*Table structure for table `pending_match_transactions` */;

DROP TABLE IF EXISTS `pending_match_transactions`;

CREATE TABLE `pending_match_transactions` (
  `address`       VARCHAR(256) NOT NULL,
  `detail`        LONGTEXT NOT NULL,
  PRIMARY KEY     (`address`)
) ENGINE=InnoDB;
