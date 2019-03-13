USE `blockchain_cache`;

/*Table structure for table `transaction_trie` */;

DROP TABLE IF EXISTS `transaction_trie`;

CREATE TABLE `transaction_trie` (
  `id`          BIGINT(20) NOT NULL AUTO_INCREMENT,
  `parentHash`  VARCHAR(256) DEFAULT NULL,
  `hash`        VARCHAR(256) NOT NULL,
  `alias`       VARCHAR(200) NOT NULL,
  `layer`       INT NOT NULL,
  `address`     VARCHAR(256) DEFAULT NULL,
  `delete_flag` TINYINT(4) NOT NULL DEFAULT 0 COMMENT '0:not delete; 1:delete',
  PRIMARY KEY   (`id`)
) ENGINE=InnoDB;
