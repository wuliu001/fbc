USE `contract_match`;

/*Table structure for table `logistics_events` */;

DROP TABLE IF EXISTS `logistics_events`;

CREATE TABLE `logistics_events` (
  `id`                BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT, 
  `logisticNo`        VARCHAR(32) NOT NULL, 
  `carType`           VARCHAR(50) NOT NULL, 
  `carNo`             VARCHAR(50) NOT NULL,
  `driverName`        VARCHAR(100) NOT NULL,
  `driverPhone`       VARCHAR(50) NOT NULL, 
  `location`          TEXT NOT NULL, 
  `recordTime`        DATETIME NOT NULL, 
  `detail`            TEXT NOT NULL,
  PRIMARY KEY         (`id`),
  KEY `idx_log`       (`logisticNo`)
) ENGINE=InnoDB;