USE `blockchain_cache`;

/*Table structure for table `transactions` */;

DROP TABLE IF EXISTS `transactions`;

CREATE TABLE `transactions` (
  `address`                   VARCHAR(256) NOT NULL,
  `initiator`                 VARCHAR(256) NOT NULL,
  `nonceForCurrentInitiator`  BIGINT(20) NOT NULL,
  `nonceForOriginInitiator`   BIGINT(20) NOT NULL,
  `nonceForSmartContract`     BIGINT(20) DEFAULT NULL,
  `receiver`                  VARCHAR(256) NOT NULL,
  `txType`                    VARCHAR(32) NOT NULL,
  `detail`                    LONGTEXT NOT NULL,
  `gasCost`                   FLOAT NOT NULL,
  `gasDeposit`                FLOAT NOT NULL,
  `hashSign`                  VARCHAR(256) NOT NULL,
  `receiptAddress`            VARCHAR(256) NOT NULL,
  `request_timestamp`         DATETIME NOT NULL,
  `createTime`                DATETIME NOT NULL,
  `last_update_time`          DATETIME NOT NULL,
  `status`                    TINYINT(4) NOT NULL DEFAULT 0 COMMENT '0:waiting match; 1:matched; 2:logstic confirmed; 3:closed',
  `comfirmedTimes`            INT NOT NULL DEFAULT 0,
  `delete_flag`               TINYINT(4) NOT NULL DEFAULT 0 COMMENT '0:not delete; 1:delete',
  PRIMARY KEY                 (`address`)
) ENGINE=InnoDB;
