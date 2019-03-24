USE `statedb`;

/*Table structure for table `state_trie` */;

DROP TABLE IF EXISTS `state_trie`;

CREATE TABLE `state_trie` (
  `id`          BIGINT(20) NOT NULL AUTO_INCREMENT,
  `parentHash`  VARCHAR(256) DEFAULT '',
  `hash`        VARCHAR(256) DEFAULT '',
  `alias`       VARCHAR(200) DEFAULT '',
  `layer`       INT NOT NULL,
  `address`     VARCHAR(256) DEFAULT '',
  PRIMARY KEY   (`id`)
) ENGINE=InnoDB;
