USE `blockchain`;

/*Table structure for table `body` */;

DROP TABLE IF EXISTS `body`;

CREATE TABLE `body` (
  `header`    VARCHAR(256) NOT NULL,
  `hash`      VARCHAR(256) NOT NULL,
  PRIMARY KEY (`header`)
) ENGINE=InnoDB;
