USE `commons`;

/*Table structure for table `logs_module` */;

DROP TABLE IF EXISTS `logs_module`;

CREATE TABLE `logs_module` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` enum('E','I','D','W') NOT NULL,
  `user_id` int(11) NOT NULL,
  `module` varchar(50) NOT NULL,
  `proc_name` varchar(50) NOT NULL,
  `params` json DEFAULT NULL,
  `body` longtext,
  `return_message` longtext NOT NULL,
  `log_time` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `log_type_idx` (`type`),
  KEY `log_userid_idx` (`user_id`),
  KEY `log_schema_idx` (`module`),
  KEY `log_name_idx` (`proc_name`)
) ENGINE=InnoDB;
