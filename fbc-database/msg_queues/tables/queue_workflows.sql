USE `msg_queues`;

/*Table structure for table `queue_workflows` */;

DROP TABLE IF EXISTS `queue_workflows`;

CREATE TABLE `queue_workflows` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `queue_type` varchar(50) NOT NULL,
  `queue_step` tinyint(4) NOT NULL,
  `special_step` json DEFAULT NULL,
  `uri` text DEFAULT NULL,
  `method` varchar(10) DEFAULT NULL,  
  `repeat_count` int(11) NOT NULL DEFAULT 0 comment '0:unlimited cycle other number:max cycle count',  
  `is_end_step` tinyint(4) NOT NULL DEFAULT '0' comment '0:not the end step 1:end step',
  `dst_queue_type` varchar(50) DEFAULT NULL,
  `dst_queue_step` tinyint(4) DEFAULT NULL,
  `limit` int(11) NOT NULL DEFAULT 0 comment '0:unlimited  other number:max limit count',
  `double_side` int(11) NOT NULL DEFAULT 1 comment '1:double side has queues  0:only one side has queues',
  `remark` text DEFAULT NULL  , 
  PRIMARY KEY (`id`),
  UNIQUE KEY `u_idx_ts` (`queue_type`,`queue_step`),
  KEY `idx_queue_type` (`queue_type`),
  KEY `idx_queue_step` (`queue_step`)
) ENGINE=InnoDB;