

USE `msg_queues`;

DROP TABLE IF EXISTS `service_parameters`;

CREATE TABLE `service_parameters` (
  `id`                     INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `queue_type`             VARCHAR(50) NOT NULL,
  `queue_step`             TINYINT(4) NOT NULL,
  `body_val_pos`           VARCHAR(50) DEFAULT NULL,
  `parameter_val_pos`      VARCHAR(50) DEFAULT NULL,
  PRIMARY KEY              (`id`),
  KEY `idx_queue_type`     (`queue_type`),
  KEY `idx_queue_step`     (`queue_step`)
) ENGINE=InnoDB;