USE `contract_match`;

/*Table structure for table `logistics` */;

DROP TABLE IF EXISTS `logistics`;

CREATE TABLE `logistics` (
  `id`                          BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT, 
  `logisticNo`                  VARCHAR(32) NOT NULL, 
  `variety`                     VARCHAR(100) NOT NULL,
  `logisticsExpense`            FLOAT NOT NULL, 
  `weight`                      FLOAT NOT NULL, 
  `fromLocation`                TEXT NOT NULL, 
  `toLocation`                  TEXT NOT NULL,
  PRIMARY KEY                   (`id`),
  UNIQUE KEY `unq_log`          (`logisticNo`)
) ENGINE=InnoDB;