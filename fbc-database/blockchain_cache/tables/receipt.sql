USE `blockchain_cache`;

/*Table structure for table `receipt` */;

DROP TABLE IF EXISTS `receipt`;

CREATE TABLE `receipt` (
  `address`         VARCHAR(256) NOT NULL,
  `accountAddress`  VARCHAR(256) NOT NULL,
  `txAddress`       VARCHAR(256) NOT NULL,
  `gasCost`         FLOAT NOT NULL,
  `creditRating`    FLOAT NOT NULL,
  `delete_flag`     TINYINT(4) NOT NULL DEFAULT 0 COMMENT '0:not delete; 1:delete',
  PRIMARY KEY       (`address`)
) ENGINE=InnoDB;
