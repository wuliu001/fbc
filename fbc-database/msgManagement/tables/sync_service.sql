USE `msg_queues`;

DROP TABLE IF EXISTS `sync_service`;

CREATE TABLE `sync_service` (
  `id` bigint(20)  NOT NULL AUTO_INCREMENT,
  `syncService_id` varchar(100) comment 'the unique identifier for each sync service machine',
  `create_time` datetime NOT NULL,
  `last_sync_time` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uni_syncService_id` (`syncService_id`)
) ENGINE=InnoDB;