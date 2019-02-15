
USE `msg_queues`;

DROP TABLE IF EXISTS `roll_back_queues`;

CREATE TABLE `roll_back_queues` (
  `id`                              BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `queue_id`                        BIGINT(20) UNSIGNED DEFAULT NULL,
  `main_queue_info`                 VARCHAR(255) DEFAULT NULL,
  `queue_type`                      VARCHAR(50) NOT NULL,
  `queue_step`                      TINYINT(4) NOT NULL,
  `queues`                          LONGTEXT NOT NULL,
  `status`                          TINYINT(4) NOT NULL DEFAULT 0 COMMENT '0:success; other numbers:fail',
  `source_endpoint_info`            VARCHAR(100) NOT NULL DEFAULT 'default',
  `dst_endpoint_info`               VARCHAR(100) DEFAULT NULL,
  `cycle_cnt`                       INT(11) NOT NULL DEFAULT 0,
  `create_time`                     DATETIME NOT NULL,
  `last_update_time`                DATETIME NOT NULL,
  `is_delete`                       TINYINT(4) NOT NULL DEFAULT 0 COMMENT '0:not delete; 1:delete',
  `is_re_assign_endpoint`           TINYINT DEFAULT 1 COMMENT '0:not allow re_assign; 1:allow re_assign',
  `remark`                          LONGTEXT DEFAULT NULL,
  PRIMARY KEY                       (`id`),
  UNIQUE KEY `un_que_type`          (`queue_id`,`queue_type`,`queue_step`,`dst_endpoint_info`)
) ENGINE=InnoDB;