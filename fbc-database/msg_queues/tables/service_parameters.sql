USE `msg_queues`;

DROP TABLE IF EXISTS `service_parameters`;

CREATE TABLE `service_parameters` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `queue_type` varchar(50) NOT NULL,
  `queue_step` tinyint(4) NOT NULL,
  `var_name` varchar(50) NOT NULL,
  `queue_val_pos` varchar(100) NOT NULL,
  `is_replace_resource` tinyint(4) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_queue_type` (`queue_type`),
  KEY `idx_queue_step` (`queue_step`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
