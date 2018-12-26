USE `commons`;

/*Table structure for table `performance_statistic` */;

DROP TABLE IF EXISTS `performance_statistic`;

CREATE TABLE `performance_statistic` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `proc_name` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `start_time` datetime(3) NOT NULL,
  `end_time` datetime(3) NOT NULL,
  `duration` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
;
