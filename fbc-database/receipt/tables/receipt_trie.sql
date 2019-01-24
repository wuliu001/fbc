USE `receipt`;

/*Table structure for table `receipt_trie` */;

DROP TABLE IF EXISTS `receipt_trie`;

CREATE TABLE `receipt_trie` (
  `id`          BIGINT(20) NOT NULL AUTO_INCREMENT,
  `parentHash`  VARCHAR(256) NOT NULL,
  `hash`        VARCHAR(256) NOT NULL,
  `alias`       VARCHAR(200) NOT NULL,
  `layer`       INT NOT NULL,
  `address`     VARCHAR(256) DEFAULT NULL,
  PRIMARY KEY   (`id`)
) ENGINE=InnoDB;
