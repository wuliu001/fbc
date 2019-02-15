

USE `msg_queues`;

DROP TABLE IF EXISTS `sync_service`;

CREATE TABLE `sync_service` (
  `id`                              INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `syncService_id`                  VARCHAR(100) COMMENT 'the unique identifier for each sync service machine',
  `create_time`                     DATETIME NOT NULL,
  `last_sync_time`                  DATETIME NOT NULL,
  PRIMARY KEY                       (`id`),
  UNIQUE KEY `uni_syncService_id`   (`syncService_id`)
) ENGINE=InnoDB;