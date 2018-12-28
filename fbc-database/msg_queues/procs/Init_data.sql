USE `msg_queues`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure msg_queues.`Init_data` */;

DROP PROCEDURE IF EXISTS msg_queues.`Init_data`;

USE `msg_queues`;
DELIMITER $$
CREATE PROCEDURE msg_queues.`Init_data`(
    user_i                INT,
    OUT returnCode_o      INT,
    OUT returnMsg_o       LONGTEXT
)
LL:BEGIN

    DECLARE v_procname            VARCHAR(50) DEFAULT 'msg_queues.Init_data';
    DECLARE v_modulename          VARCHAR(50) DEFAULT 'messageManager';
    DECLARE v_body                LONGTEXT DEFAULT NULL;
    DECLARE v_params_body         LONGTEXT DEFAULT NULL;
    DECLARE v_returnCode          INT;
    DECLARE v_returnMsg           TEXT;
  
    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;

        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
    END;

    SET returnCode_o = 400; 
    SET returnMsg_o = CONCAT(v_modulename,v_procname,' command Error.');
    SET v_params_body = CONCAT('{"user_i":"',IFNULL(user_i,''),'"}');
    SET SESSION group_concat_max_len = 4294967295;

    TRUNCATE TABLE `queue_workflows`;
    /* single queue column queue_type must at the same as column dst_queue_type */
    INSERT INTO `queue_workflows` VALUES (1,'T21_C',0,'{"0":1,"1":2}','/foregrounddb/transactions','PUT',20,0,'T21_C',null,0,0,'orignal special0 means success 1 means fail');
    INSERT INTO `queue_workflows` VALUES (2,'T21_C',1,'{"0":3,"2":4}',null,null,20,0,null,null,0,0,'business return success results');
    INSERT INTO `queue_workflows` VALUES (3,'T21_C',2,'{"0":3,"2":5}',null,null,20,0,null,null,0,0,'business return fail results');
    INSERT INTO `queue_workflows` VALUES (4,'T21_C',3,'{"0":5,"2":5}',null,null,20,0,null,null,0,0,'unlock division step');
    INSERT INTO `queue_workflows` VALUES (5,'T21_C',4,null,null,null,20,0,null,null,0,0,'exception handle');
    INSERT INTO `queue_workflows` VALUES (6,'T21_C',5,null,null,null,0,1,null,null,0,0,'end step');

    INSERT INTO `queue_workflows` VALUES (10,'PROCESSING_FILE_SYNC',0,null,null,null,0,0,null,null,0,0,'update processing_file path & status');
    INSERT INTO `queue_workflows` VALUES (11,'PROCESSING_FILE_SYNC',1,null,'/history/processingfile','POST',0,0,'PROCESSING_FILE_SYNC',null,0,0,'sync processing_file');
    INSERT INTO `queue_workflows` VALUES (12,'PROCESSING_FILE_SYNC',2,null,null,null,0,0,null,null,0,0,'wait update devices.processing_files status to success');
    INSERT INTO `queue_workflows` VALUES (13,'PROCESSING_FILE_SYNC',3,null,null,null,0,1,null,null,0,0,'end step');

    INSERT INTO `queue_workflows` VALUES (14,'T22_C',0,'{"0":1, "1":2}','/vehicle_foregrounddb/transactions','PUT',20,0,'T22_C',null,0,0,'orignal special0 means success 1 means fail');
    INSERT INTO `queue_workflows` VALUES (15,'T22_C',1,'{"0":4, "2":4}',null,null,20,0,null,null,0,0,'business return success results');
    INSERT INTO `queue_workflows` VALUES (16,'T22_C',2,'{"0":3}',null,null,20,0,null,null,0,0,'business return fail results');
    INSERT INTO `queue_workflows` VALUES (17,'T22_C',3,'{"0":5,"2":5}',null,null,20,0,null,null,0,0,'unlock division step');
    INSERT INTO `queue_workflows` VALUES (18,'T22_C',4,null,null,null,0,0,null,null,0,0,'exception handle');
    INSERT INTO `queue_workflows` VALUES (19,'T22_C',5,null,null,null,0,1,null,null,0,0,'end step');


    INSERT INTO `queue_workflows` VALUES (24,'T2_C',0,'{"0": 1, "1": 2}','/landmarkdb/transactions','PUT',20,0,'T2_C',null,0,0,'orignal special0 means success 1 means fail');
    INSERT INTO `queue_workflows` VALUES (25,'T2_C',1,'{"0":3,"2":4}',null,null,20,0,null,null,0,0,'business return success results');
    INSERT INTO `queue_workflows` VALUES (26,'T2_C',2,'{"0":3,"2":4}',null,null,20,0,null,null,0,0,'business return fail results');
    INSERT INTO `queue_workflows` VALUES (27,'T2_C',3,'{"0":4,"2":4}',null,null,20,0,null,null,0,0,'unlock division step');
    INSERT INTO `queue_workflows` VALUES (28,'T2_C',4,null,null,null,0,1,null,null,0,0,'end step');


    INSERT INTO `queue_workflows` VALUES (31,'T20_C',0,'{"0": 1, "1": 2}','/foregrounddb/transactions','PUT',20,0,'T20_C',null,0,0,'orignal special0 means success 1 means fail');
    INSERT INTO `queue_workflows` VALUES (32,'T20_C',1,'{"0":3,"2":4}',null,null,20,0,null,null,0,0,'business return success results');
    INSERT INTO `queue_workflows` VALUES (33,'T20_C',2,'{"0":3,"2":5}',null,null,20,0,null,null,0,0,'business return fail results');
    INSERT INTO `queue_workflows` VALUES (34,'T20_C',3,'{"0":5,"2":5}',null,null,20,0,null,null,0,0,'unlock segment step');
    INSERT INTO `queue_workflows` VALUES (35,'T20_C',4,null,null,null,20,0,null,null,0,0,'exception handle');
    INSERT INTO `queue_workflows` VALUES (36,'T20_C',5,null,null,null,0,1,null,null,0,0,'end step');


    TRUNCATE TABLE service_parameters;

    INSERT INTO `msg_queues`.`service_parameters` (`id`, `queue_type`, `queue_step`, `var_name`, `queue_val_pos`, `is_replace_resource`) VALUES (1,'T21_C', 0, 'status', '2', 0);
    INSERT INTO `msg_queues`.`service_parameters` (`id`, `queue_type`, `queue_step`, `var_name`, `queue_val_pos`, `is_replace_resource`) VALUES (2,'T21_C', 0, 'body', '1,2', 0);
    INSERT INTO `msg_queues`.`service_parameters` (`id`, `queue_type`, `queue_step`, `var_name`, `queue_val_pos`, `is_replace_resource`) VALUES (3,'PROCESSING_FILE_SYNC', 1, 'body', '1,2', 0);
    INSERT INTO `msg_queues`.`service_parameters` (`id`, `queue_type`, `queue_step`, `var_name`, `queue_val_pos`, `is_replace_resource`) VALUES (4,'T22_C', 0, 'status', '2', 0);
    INSERT INTO `msg_queues`.`service_parameters` (`id`, `queue_type`, `queue_step`, `var_name`, `queue_val_pos`, `is_replace_resource`) VALUES (5,'T22_C', 0, 'body', '1,2', 0);
    INSERT INTO `msg_queues`.`service_parameters` (`id`, `queue_type`, `queue_step`, `var_name`, `queue_val_pos`, `is_replace_resource`) VALUES (6,'T20_C', 0, 'status', '2', 0);
    INSERT INTO `msg_queues`.`service_parameters` (`id`, `queue_type`, `queue_step`, `var_name`, `queue_val_pos`, `is_replace_resource`) VALUES (7,'T20_C', 0, 'body', '1,2', 1);
    INSERT INTO `msg_queues`.`service_parameters` (`id`, `queue_type`, `queue_step`, `var_name`, `queue_val_pos`, `is_replace_resource`) VALUES (8,'T2_C', 0, 'status', '2', 0);
    INSERT INTO `msg_queues`.`service_parameters` (`id`, `queue_type`, `queue_step`, `var_name`, `queue_val_pos`, `is_replace_resource`) VALUES (9,'T2_C', 0, 'body', '1,2', 0);

    TRUNCATE TABLE job_config;
    INSERT INTO `job_config`(queue_type, queue_step, proc_name, `type`) VALUES('T20_C', 1, 'history.`fgdb_merger.success_return`', 'success');
    INSERT INTO `job_config`(queue_type, queue_step, proc_name, `type`) VALUES('T20_C', 2, 'history.`fgdb_merger.fail_return`', 'fail');
    INSERT INTO `job_config`(queue_type, queue_step, proc_name, `type`) VALUES('T20_C', 3, 'history.`fgdb_merger.unlock_segment`', 'unlock');
    INSERT INTO `job_config`(queue_type, queue_step, proc_name, `type`) VALUES('T20_C', 4, 'history.`fgdb_merger.abnormal_handle`', 'abnormal');
    INSERT INTO `job_config`(queue_type, queue_step, proc_name, `type`) VALUES('T20_C', 5, NULL, 'end');

    INSERT INTO `job_config`(queue_type, queue_step, proc_name, `type`) VALUES('T21_C', 1, 'history.`fgdb_updater.success_return`', 'success');
    INSERT INTO `job_config`(queue_type, queue_step, proc_name, `type`) VALUES('T21_C', 2, 'history.`fgdb_updater.fail_return`', 'fail');
    INSERT INTO `job_config`(queue_type, queue_step, proc_name, `type`) VALUES('T21_C', 3, 'history.`fgdb_updater.unlock_division`', 'unlock');
    INSERT INTO `job_config`(queue_type, queue_step, proc_name, `type`) VALUES('T21_C', 4, 'history.`fgdb_updater.abnormal_handle`', 'abnormal');
    INSERT INTO `job_config`(queue_type, queue_step, proc_name, `type`) VALUES('T21_C', 5, NULL, 'end');

    INSERT INTO `job_config`(queue_type, queue_step, proc_name, `type`) VALUES('T22_C', 1, 'history.`veh_generator.success_return`', 'success');
    INSERT INTO `job_config`(queue_type, queue_step, proc_name, `type`) VALUES('T22_C', 2, 'history.`veh_generator.fail_return`', 'fail');
    INSERT INTO `job_config`(queue_type, queue_step, proc_name, `type`) VALUES('T22_C', 3, 'history.`veh_generator.unlock_division`', 'unlock');
    INSERT INTO `job_config`(queue_type, queue_step, proc_name, `type`) VALUES('T22_C', 4, 'history.`veh_generator.abnormal_handle`', 'abnormal');
    INSERT INTO `job_config`(queue_type, queue_step, proc_name, `type`) VALUES('T22_C', 5, NULL, 'end');

    INSERT INTO `job_config`(queue_type, queue_step, proc_name, `type`) VALUES('T2_C', 1, 'history.`roadmerge_update.success_return`', 'success');
    INSERT INTO `job_config`(queue_type, queue_step, proc_name, `type`) VALUES('T2_C', 2, 'history.`roadmerge_update.fail_return`', 'fail');
    INSERT INTO `job_config`(queue_type, queue_step, proc_name, `type`) VALUES('T2_C', 3, 'history.`roadmerge_update.unlock_division`', 'unlock');
    INSERT INTO `job_config`(queue_type, queue_step, proc_name, `type`) VALUES('T2_C', 4, NULL, 'end');

    SET returnCode_o = 200;
    SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.d`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);

END$$

DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;