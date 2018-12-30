USE `msg_queues`;

TRUNCATE TABLE `queue_workflows`;

/* single queue column queue_type must at the same as column dst_queue_type */
INSERT INTO `queue_workflows` VALUES (1,'test',0,null,'/msg/test','POST',0,0,'test',null,0,0,'sync testdata');
INSERT INTO `queue_workflows` VALUES (2,'test',1,null,null,null,0,1,null,null,0,0,'end step');

INSERT INTO `queue_workflows` VALUES (3,'syncBlockCache',0,null,null,null,0,0,null,null,0,0,'sync block cache');
INSERT INTO `queue_workflows` VALUES (4,'syncBlockCache',1,null,'/goods','POST',0,0,'syncBlockCache',null,0,0,'sync block cache');
INSERT INTO `queue_workflows` VALUES (5,'syncBlockCache',2,null,null,null,0,1,null,null,0,0,'end step');

TRUNCATE TABLE service_parameters;
INSERT INTO `service_parameters` (`id`, `queue_type`, `queue_step`, `var_name`, `queue_val_pos`, `is_replace_resource`) VALUES (1,'test', 0, 'body', '1,2', 0);
INSERT INTO `service_parameters` (`id`, `queue_type`, `queue_step`, `var_name`, `queue_val_pos`, `is_replace_resource`) VALUES (2,'test', 0, 'userAccount', '3', 0);
INSERT INTO `service_parameters` (`id`, `queue_type`, `queue_step`, `var_name`, `queue_val_pos`, `is_replace_resource`) VALUES (3,'syncBlockCache', 1, 'body', '1,2', 0);


TRUNCATE TABLE job_config;