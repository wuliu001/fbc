USE `statedb`;

/*Table structure for table `state_object` */;

DROP TABLE IF EXISTS `state_object`;

CREATE TABLE `state_object` (
  `accountAddress`          VARCHAR(256) NOT NULL,
  `publicKey`               TEXT NOT NULL,
  `creditRating`            FLOAT NOT NULL,
  `balance`                 FLOAT NOT NULL,
  `smartContractPrice`      FLOAT DEFAULT NULL,
  `minSmartContractDeposit` FLOAT DEFAULT NULL,
  `nonce`                   INT(11) NOT NULL,
  PRIMARY KEY               (`accountAddress`)
) ENGINE=InnoDB;
