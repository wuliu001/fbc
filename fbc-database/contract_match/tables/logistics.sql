USE `contract_match`;

/*Table structure for table `logistics` */;

DROP TABLE IF EXISTS `logistics`;

CREATE TABLE `logistics` ( 
  `logisticNo`                  VARCHAR(32) NOT NULL, 
  `variety`                     VARCHAR(100) NOT NULL,
  `logisticsExpense`            FLOAT NOT NULL, 
  `weight`                      FLOAT NOT NULL, 
  `fromLocation`                TEXT NOT NULL, 
  `toLocation`                  TEXT NOT NULL,
  PRIMARY KEY                   (`logisticNo`)
) ENGINE=InnoDB;