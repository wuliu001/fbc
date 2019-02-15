

USE `msg_queues`;

DROP TABLE IF EXISTS `sync_service_config`;

CREATE TABLE `sync_service_config` (
  `id`                                INT(11) UNSIGNED  NOT NULL AUTO_INCREMENT,
  `sync_id`                           INT(11) UNSIGNED NOT NULL,
  `endpoint_id`                       VARCHAR(100) NOT NULL,
  `endpoint_ip`                       VARCHAR(20) NOT NULL,
  `endpoint_port`                     VARCHAR(20) NOT NULL,
  `queue_type`                        VARCHAR(50) NOT NULL,
  `endpoint_weight`                   INT(11) NOT NULL,
  `create_time`                       DATETIME NOT NULL,
  `last_update_time`                  DATETIME NOT NULL,
  `cur_weight_after_selected`         INT NOT NULL DEFAULT 0,
  PRIMARY KEY                         (`id`),
  UNIQUE KEY `uni_sync_endpoint_id`   (`sync_id`,`endpoint_ip`,`endpoint_port`,`queue_type`)
) ENGINE=InnoDB;