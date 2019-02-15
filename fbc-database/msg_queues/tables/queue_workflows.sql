
USE `msg_queues`;

/*Table structure for table `queue_workflows` */;

DROP TABLE IF EXISTS `queue_workflows`;

CREATE TABLE `queue_workflows` (
  `id`                        INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `queue_type`                VARCHAR(50) NOT NULL,
  `sub_queue_type`            VARCHAR(50) DEFAULT NULL,
  `success_percent`           INT DEFAULT NULL,
  `queue_step`                TINYINT(4) NOT NULL,
  `special_step`              JSON DEFAULT NULL,
  `uri`                       TEXT DEFAULT NULL,
  `method`                    VARCHAR(10) DEFAULT NULL,  
  `repeat_count`              INT(11) NOT NULL DEFAULT 0 COMMENT '0:unlimited cycle; other number:max cycle count',  
  `is_end_step`               TINYINT(4) NOT NULL DEFAULT '0' COMMENT '0:not the end step; 1:end step',
  `dst_queue_type`            VARCHAR(50) DEFAULT NULL COMMENT 'this column will be used to calculate weight,if double side=0 and the uri is not null,this column can not be null',
  `dst_queue_step`            TINYINT(4) DEFAULT NULL COMMENT 'this column will be used to calculate unsync queue,if double side=0 and the uri is not null,this column can not be null',
  `limit`                     INT(11) NOT NULL DEFAULT 0 COMMENT '0:unlimited; other number:max limit count',
  `double_side`               INT(11) NOT NULL DEFAULT 1 COMMENT '1:double side has queues; 0:only one side has queues',
  `remark`                    TEXT DEFAULT NULL , 
  PRIMARY KEY                 (`id`),
  UNIQUE KEY `u_idx_ts`       (`queue_type`,`queue_step`),
  KEY `idx_queue_step`        (`queue_step`)
) ENGINE=InnoDB;