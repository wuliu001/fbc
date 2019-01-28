USE `transactions`;

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
  `createTime`                DATETIME NOT NULL,
  `closeTime`                 DATETIME DEFAULT NULL,
  PRIMARY KEY                 (`address`)
) ENGINE=InnoDB;
