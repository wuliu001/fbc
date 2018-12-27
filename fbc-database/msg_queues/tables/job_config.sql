USE `msg_queues`;

/*Table structure for table `job_config` */;

DROP TABLE IF EXISTS `job_config`;

CREATE TABLE `job_config` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `queue_type` varchar(50),
  `queue_step` tinyint(4),
  `proc_name` varchar(100),
  `type` varchar(20),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;