USE `blockchain`;

/*Table structure for table `body` */;

DROP TABLE IF EXISTS `body`;

CREATE TABLE `body` (
  `id`        BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `header`    VARCHAR(256) NOT NULL,
  `hash`      VARCHAR(256) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;
