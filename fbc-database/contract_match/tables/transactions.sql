USE `contract_match`;

/*Table structure for table `transactions` */;

DROP TABLE IF EXISTS `transactions`;

CREATE TABLE `transactions` (
  `address`                     VARCHAR(256) NOT NULL,
  `initiator`                   VARCHAR(256) NOT NULL,
  `nonceForCurrentInitiator`    BIGINT(20) NOT NULL,
  `nonceForOriginInitiator`     BIGINT(20) NOT NULL,
  `nonceForSmartContract`       BIGINT(20) DEFAULT NULL,
  `receiver`                    VARCHAR(256) NOT NULL,
  `txType`                      VARCHAR(32) NOT NULL,
  `variety`                     VARCHAR(100) NOT NULL,
  `placeOfProduction`           VARCHAR(256) DEFAULT NULL,
  `dateOfMature`                DATETIME NOT NULL,
  `dateOfProduction`            DATETIME NOT NULL,
  `appearanceRating`            INT NOT NULL,
  `sizeRating`                  INT NOT NULL,
  `sweetnessRating`             INT NOT NULL,
  `minQuantity`                 INT NOT NULL,
  `maxQuantity`                 INT NOT NULL,
  `price`                       FLOAT NOT NULL,
  `countryOfDeliveryLocation`   VARCHAR(100) NOT NULL,
  `provinceOfDeliveryLocation`  VARCHAR(100) NOT NULL,
  `cityOfDeliveryLocation`      VARCHAR(100) NOT NULL,
  `zoneOfDeliveryLocation`      VARCHAR(100) NOT NULL,
  `addressOfDeliveryLocation`   VARCHAR(200) NOT NULL,
  `request_begin_time`          DATETIME NOT NULL,
  `request_end_time`            DATETIME NOT NULL,
  `gasCost`                     FLOAT NOT NULL,
  `gasDeposit`                  FLOAT NOT NULL,
  `matchedQuantity`             FLOAT DEFAULT NULL,
  `totalPrice`                  FLOAT DEFAULT NULL,
  `logisticNo`                  VARCHAR(32) DEFAULT NULL,
  `createTime`                  DATETIME NOT NULL,
  `last_update_time`            DATETIME NOT NULL,
  `status`                      TINYINT(4) NOT NULL DEFAULT 0 COMMENT '0:waiting match; 1:matched; 2:logstic confirmed; 3:closed',
  PRIMARY KEY                 (`address`)
) ENGINE=InnoDB;