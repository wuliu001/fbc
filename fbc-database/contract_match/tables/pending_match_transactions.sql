USE `contract_match`;

/*Table structure for table `pending_match_transactions` */;

DROP TABLE IF EXISTS `pending_match_transactions`;

CREATE TABLE `pending_match_transactions` (
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
  `createTime`                DATETIME NOT NULL,
  `closeTime`                 DATETIME DEFAULT NULL,
  `match_flag`                TINYINT(4) NOT NULL DEFAULT 0 COMMENT '0:not match; 1:matched',
  PRIMARY KEY                 (`address`)
) ENGINE=InnoDB;
