USE `keystore`;

/*Table structure for table `accounts` */;

DROP TABLE IF EXISTS `accounts`;

CREATE TABLE `accounts` (
  `accountAddress`  VARCHAR(256) NOT NULL,
  `private_key`     TEXT NOT NULL,
  `txPassword`      VARCHAR(50) NOT NULL,
  PRIMARY KEY       (`accountAddress`)
) ENGINE=InnoDB;
