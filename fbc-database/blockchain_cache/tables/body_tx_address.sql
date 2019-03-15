USE `blockchain_cache`;

/*Table structure for table `body_tx_address` */;

DROP TABLE IF EXISTS `body_tx_address`;

CREATE TABLE `body_tx_address` (
  `id`                   BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `hash`                 VARCHAR(256) NOT NULL,
  `tx_address`           VARCHAR(256) NOT NULL,
  `delete_flag`          TINYINT(4) NOT NULL DEFAULT 0 COMMENT '0:not delete; 1:delete',
  PRIMARY KEY            (`id`)
) ENGINE=InnoDB;
