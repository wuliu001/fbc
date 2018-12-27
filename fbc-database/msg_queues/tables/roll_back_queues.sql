USE `msg_queues`;

DROP TABLE IF EXISTS `roll_back_queues`;

CREATE TABLE `roll_back_queues` (
  `id` bigint(20)  NOT NULL AUTO_INCREMENT,
  `queue_id` bigint(20) , 
  `queue_type` varchar(50) NOT NULL,
  `queue_step` tinyint(4) NOT NULL,
  `queues` longtext NOT NULL,
  `status` tinyint(4) NOT NULL default 0 comment '0:success,1:fail',
  `source_endpoint_info` varchar(100) NOT NULL,
  `dst_endpoint_info` varchar(100),
  `cycle_cnt` int(11) NOT NULL default 0,
  `is_delete` tinyint(4) NOT NULL default 0 comment '0:not delete,1:delete',  
  `create_time` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_queue_id` (`queue_id`),
  KEY `idx_queue_type` (`queue_type`),
  KEY `idx_queue_step` (`queue_step`),
  KEY `idx_status` (`status`),
  KEY `idx_source_endpoint_info` (`source_endpoint_info`),
  KEY `idx_dst_endpoint_info` (`dst_endpoint_info`),
  UNIQUE KEY `un_que_type`(`queue_id`,`queue_type`,`dst_endpoint_info`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;