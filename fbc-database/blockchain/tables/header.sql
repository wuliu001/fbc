USE `blockchain`;

/*Table structure for table `header` */;

DROP TABLE IF EXISTS `header`;

CREATE TABLE `header` (
  `id`           BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `parentHash`   VARCHAR(256) NOT NULL,
  `stateRoot`    VARCHAR(256) NOT NULL,
  `txRoot`       VARCHAR(256) NOT NULL,
  `receiptRoot`  VARCHAR(256) NOT NULL,
  `Bloom`        LONGTEXT NOT NULL,
  `Time`         DATETIME,
  `Nonce`        INT(11),
  PRIMARY KEY    (`id`)
) ENGINE=InnoDB;
