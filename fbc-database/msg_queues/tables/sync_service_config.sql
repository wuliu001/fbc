USE `msg_queues`;

DROP TABLE IF EXISTS `sync_service_config`;

CREATE TABLE `sync_service_config` (
  `id` bigint(20)  NOT NULL AUTO_INCREMENT,
  `sync_id` int(11) NOT NULL,
  `endpoint_id` varchar(100) NOT NULL,
  `endpoint_ip` varchar(20) NOT NULL,
  `endpoint_port` varchar(20) NOT NULL,
  `queue_type` varchar(50) NOT NULL,
  `endpoint_weight` int(11) NOT NULL,
  `create_time` datetime NOT NULL,
  `last_update_time` datetime NOT NULL,
  `cur_weight_after_selected` int NOT NULL default 0,
  PRIMARY KEY (`id`),
  KEY `idx_endpoint_id` (`endpoint_id`),
  KEY `idx_sync_id` (`sync_id`),
  UNIQUE KEY `uni_sync_endpoint_id`(`sync_id`,`endpoint_id`,`endpoint_ip`,`endpoint_port`,`queue_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;