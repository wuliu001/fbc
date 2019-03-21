USE `blockchain_cache`;

/*Table structure for table `body` */;

DROP TABLE IF EXISTS `body`;

CREATE TABLE `body` (
  `header`        INT(11) NOT NULL,
  `hash`          VARCHAR(256) NOT NULL,
  `delete_flag`   TINYINT(4) NOT NULL DEFAULT 0 COMMENT '0:not delete; 1:delete',
  PRIMARY KEY     (`header`)
) ENGINE=InnoDB;
