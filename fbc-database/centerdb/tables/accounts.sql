USE `centerdb`;

/*Table structure for table `accounts` */;

DROP TABLE IF EXISTS `accounts`;

CREATE TABLE `accounts` (
  `accountAddress`      VARCHAR(256) NOT NULL,
  `userAccount`         VARCHAR(50) NOT NULL,
  `loginPassword`       VARCHAR(50) NOT NULL,
  `corporationName`     VARCHAR(300) NOT NULL,
  `owner`               VARCHAR(50) NOT NULL,
  `address`             TEXT NOT NULL,
  `companyRegisterDate` DATETIME NOT NULL,
  `registeredCapital`   INT(11) NOT NULL,
  `annualIncome`        INT(11) NOT NULL,
  `telNum`              VARCHAR(50) NOT NULL,
  `email`               VARCHAR(200) NOT NULL,
  `create_time`         DATETIME NOT NULL,
  `last_update_time`    DATETIME NOT NULL,
  `last_login_time`     DATETIME NOT NULL,
  PRIMARY KEY           (`accountAddress`)
) ENGINE=InnoDB;
