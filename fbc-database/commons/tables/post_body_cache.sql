USE `commons`;

/*Table structure for table `post_body_cache` */;

DROP TABLE IF EXISTS `post_body_cache`;

CREATE TABLE `post_body_cache` (
  `uuid` varchar(100)NOT NULL,
  `ord` int(11) NOT NULL,
  `body_cache` longtext NOT NULL,
  `create_time` datetime NOT NULL,
  PRIMARY KEY (`uuid`,`ord`)
) ENGINE=InnoDB;
