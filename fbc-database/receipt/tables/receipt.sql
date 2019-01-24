USE `receipt`;

/*Table structure for table `receipt` */;

DROP TABLE IF EXISTS `receipt`;

CREATE TABLE `receipt` (
  `id`              BIGINT(20) NOT NULL AUTO_INCREMENT,
  `address`         VARCHAR(256) NOT NULL,
  `accountAddress`  VARCHAR(256) NOT NULL,
  `txAddress`       VARCHAR(256) NOT NULL,
  `gasCost`         FLOAT NOT NULL,
  `creditRating`    FLOAT NOT NULL,
  PRIMARY KEY       (`id`)
) ENGINE=InnoDB;
