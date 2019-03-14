USE `blockchain_cache`;

/*Table structure for table `state_trie` */;

DROP TABLE IF EXISTS `state_trie`;

CREATE TABLE `state_trie` (
  `id`                     BIGINT(20) NOT NULL AUTO_INCREMENT,
  `parentHash`             VARCHAR(256) DEFAULT '',
  `hash`                   VARCHAR(256) NOT NULL,
  `alias`                  VARCHAR(200) DEFAULT '',
  `layer`                  INT NOT NULL,
  `address`                VARCHAR(256) DEFAULT '',
  `delete_flag`            TINYINT(4) NOT NULL DEFAULT 0 COMMENT '0:not delete; 1:delete',
  PRIMARY KEY              (`id`),
  UNIQUE KEY `uqe_st_idx`  (`alias`,`layer`)
) ENGINE=InnoDB;
