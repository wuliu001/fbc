USE `blockchain`;

/*Table structure for table `body_tx_address` */;

DROP TABLE IF EXISTS `body_tx_address`;

CREATE TABLE `body_tx_address` (
  `id`           BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `hash`         VARCHAR(256) NOT NULL,
  `tx_address`   VARCHAR(256) NOT NULL,
  PRIMARY KEY    (`id`)
) ENGINE=InnoDB;
