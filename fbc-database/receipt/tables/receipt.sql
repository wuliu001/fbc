USE `receipt`;

/*Table structure for table `receipt` */;

DROP TABLE IF EXISTS `receipt`;

CREATE TABLE `receipt` (
  `address`         VARCHAR(256) NOT NULL,
  `accountAddress`  VARCHAR(256) NOT NULL,
  `txAddress`       VARCHAR(256) NOT NULL,
  `gasCost`         FLOAT NOT NULL,
  `creditRating`    FLOAT NOT NULL,
  PRIMARY KEY       (`address`)
) ENGINE=InnoDB;
