USE `tx_cache`;

/*Table structure for table `transactions` */;

DROP TABLE IF EXISTS `transactions`;

CREATE TABLE `transactions` (
  `txAddress`       VARCHAR(256) NOT NULL,
  `accountAddress`  VARCHAR(256) NOT NULL,
  `transactionType` VARCHAR(32) NOT NULL,
  `blockObject`     LONGTEXT NOT NULL,
  `hashSign`        VARCHAR(256) NOT NULL,
  `gasCost`         FLOAT NOT NULL,
  `gasDeposit`      FLOAT NOT NULL,
  `nonce`           INT(11),
  `timestamp`       BIGINT(20) NOT NULL,
  `comfirmedTimes`  INT NOT NULL DEFAULT 0,
  `delete_flag`     TINYINT(4) NOT NULL DEFAULT 0 COMMENT '0:not delete; 1:delete',
  PRIMARY KEY       (`txAddress`)
) ENGINE=InnoDB;
