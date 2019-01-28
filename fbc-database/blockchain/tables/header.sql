USE `blockchain`;

/*Table structure for table `header` */;

DROP TABLE IF EXISTS `header`;

CREATE TABLE `header` (
  `parentHash`   VARCHAR(256) NOT NULL,
  `stateRoot`    VARCHAR(256) NOT NULL,
  `txRoot`       VARCHAR(256) NOT NULL,
  `receiptRoot`  VARCHAR(256) NOT NULL,
  `bloom`        LONGTEXT NOT NULL,
  `time`         DATETIME,
  `nonce`        INT(11) NOT NULL,
  PRIMARY KEY    (`nonce`)
) ENGINE=InnoDB;
