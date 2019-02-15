
USE `msg_queues`;

/*Table structure for table `job_config` */;

DROP TABLE IF EXISTS `job_config`;

CREATE TABLE `job_config` (
  `id`                  INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `queue_type`          VARCHAR(50),
  `queue_step`          TINYINT(4),
  `proc_name`           VARCHAR(100),
  `type`                VARCHAR(20),
  PRIMARY KEY           (`id`)
) ENGINE=InnoDB;