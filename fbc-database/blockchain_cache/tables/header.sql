USE `blockchain_cache`;

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
  `delete_flag`  TINYINT(4) NOT NULL DEFAULT 0 COMMENT '0:not delete; 1:delete',
  PRIMARY KEY    (`nonce`)
) ENGINE=InnoDB;
