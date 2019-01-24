USE `keystore`;

/*Table structure for table `accounts` */;

DROP TABLE IF EXISTS `accounts`;

CREATE TABLE `accounts` (
  `id`              BIGINT(20) NOT NULL AUTO_INCREMENT,
  `accountAddress`  VARCHAR(256) NOT NULL,
  `private_key`     TEXT NOT NULL,
  `txPassword`      VARCHAR(50) NOT NULL,
  PRIMARY KEY       (`id`)
) ENGINE=InnoDB;
