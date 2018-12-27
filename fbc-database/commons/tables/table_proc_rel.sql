USE `commons`;

/*Table structure for table `table_proc_rel` */;

DROP TABLE IF EXISTS `table_proc_rel`;

CREATE TABLE `table_proc_rel` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `table_schema` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `table_name` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `routine_schema` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `routine_name` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `routine_type` varchar(10) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `table_is_deprecated` tinyint(4) DEFAULT NULL,
  `routine_is_deprecated` tinyint(4) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
