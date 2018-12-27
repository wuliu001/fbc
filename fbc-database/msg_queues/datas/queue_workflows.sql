USE `msg_queues`;

TRUNCATE TABLE `queue_workflows`;

/* single queue column queue_type must at the same as column dst_queue_type */
INSERT INTO `queue_workflows` VALUES (1,'test',1,null,'/users/login','POST',0,0,'test',null,0,0,'sync processing_file');
INSERT INTO `queue_workflows` VALUES (2,'test',2,null,null,null,0,1,null,null,0,0,'end step');

TRUNCATE TABLE service_parameters;

TRUNCATE TABLE job_config;