USE `msg_queues`;

DROP TABLE IF EXISTS `queues`;

CREATE TABLE `queues` (
  `id` bigint(20)  NOT NULL AUTO_INCREMENT,
  `queue_id` bigint(20) ,
  `queue_type` varchar(50) NOT NULL,
  `queue_step` tinyint(4) NOT NULL,
  `queues` longtext NOT NULL,
  `status` tinyint(4) NOT NULL default 0 comment '0:success,1:fail',
  `source_endpoint_info` varchar(100) NOT NULL DEFAULT 'default',
  `dst_endpoint_info` varchar(100),
  `cycle_cnt` int(11) NOT NULL default 0,
  `create_time` datetime NOT NULL,
  `last_update_time` datetime NOT NULL,
  `is_delete` tinyint(4) NOT NULL default 0 comment '0:not delete,1:delete',
  `is_re_assign_endpoint` tinyint default 1 comment '0:not allow re_assign, 1:allow re_assign',
  `remark`   longtext,
  PRIMARY KEY (`id`),
  KEY `idx_queue_id` (`queue_id`),
  KEY `idx_queue_type` (`queue_type`),
  KEY `idx_queue_step` (`queue_step`),
  KEY `idx_source_endpoint_info` (`source_endpoint_info`),
  KEY `idx_dst_endpoint_info` (`dst_endpoint_info`),
  UNIQUE KEY `un_que_type`(`queue_id`,`queue_type`,`dst_endpoint_info`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
