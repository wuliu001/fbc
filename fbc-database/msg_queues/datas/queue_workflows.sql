USE `msg_queues`;

TRUNCATE TABLE `queue_workflows`;

/* single queue column queue_type must at the same as column dst_queue_type */
INSERT INTO `queue_workflows` VALUES (1,'test',0,null,'/users/login','POST',0,0,'test',null,0,0,'sync processing_file');
INSERT INTO `queue_workflows` VALUES (2,'test',1,null,null,null,0,1,null,null,0,0,'end step');

TRUNCATE TABLE service_parameters;
INSERT INTO `service_parameters` (`id`, `queue_type`, `queue_step`, `var_name`, `queue_val_pos`, `is_replace_resource`) VALUES (1,'test', 0, 'body', '1', 0);
INSERT INTO `service_parameters` (`id`, `queue_type`, `queue_step`, `var_name`, `queue_val_pos`, `is_replace_resource`) VALUES (2,'test', 0, 'userAccount', '2', 0);


TRUNCATE TABLE job_config;