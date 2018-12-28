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
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;