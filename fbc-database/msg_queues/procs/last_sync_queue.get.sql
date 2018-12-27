USE `msg_queues`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `last_sync_queue.get` */;

DROP PROCEDURE IF EXISTS `last_sync_queue.get`;

DELIMITER $$

CREATE PROCEDURE `last_sync_queue.get`(
    user_i                   INT,
    dst_queue_type_i         VARCHAR(50),
    dst_queue_step_i         TINYINT,
    endpoint_info_i          VARCHAR(100),
    OUT returnCode_o         INT,
    OUT returnMsg_o          LONGTEXT
    )
ll:BEGIN
    DECLARE v_procname          VARCHAR(64) DEFAULT 'last_sync_queue.get';
    DECLARE v_modulename        VARCHAR(50) DEFAULT 'messageManager';
    DECLARE v_body              LONGTEXT DEFAULT NULL;
    DECLARE v_params_body       LONGTEXT DEFAULT NULL;
    DECLARE v_returnCode        INT DEFAULT 0;
    DECLARE v_returnMsg         LONGTEXT DEFAULT '';
    DECLARE v_is_type_valid     INT;
    
    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
    END;
    
    SET SESSION group_concat_max_len = 4294967295;
    SET returnCode_o = 400;
    SET returnMsg_o =  'Workflow Manager last_sync_queue.get Command Error.';
    SET v_params_body = CONCAT('{"user_i":"',user_i,'","dst_queue_step_i":"',IFNULL(dst_queue_step_i,''),'","endpoint_info_i":"',IFNULL(endpoint_info_i,''),'","dst_queue_type_i":"',IFNULL(dst_queue_type_i,''),'"}');
    SET endpoint_info_i = TRIM(endpoint_info_i);
    SET dst_queue_step_i = TRIM(dst_queue_step_i);
    
    SET returnMsg_o = 'check input null data Error.';
    IF IFNULL(dst_queue_type_i,'') = '' OR IFNULL(endpoint_info_i,'') = '' OR dst_queue_step_i IS NULL THEN
        SET returnCode_o = 600;
        CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    SET returnMsg_o = 'check input queue_type invalid.';
    SET v_is_type_valid = msg_queues.`checkStatus`(dst_queue_type_i,dst_queue_step_i);
    IF v_is_type_valid = 0 THEN
        SET returnCode_o = 600;
        CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;  
    
    SET returnMsg_o = 'fail to return final result.';
    IF EXISTS (SELECT 1 FROM msg_queues.queues WHERE source_endpoint_info = endpoint_info_i AND queue_type = dst_queue_type_i) THEN 
        SELECT IFNULL(MAX(queue_id),0) last_synced_id 
          FROM msg_queues.queues 
         WHERE queue_type = dst_queue_type_i
           AND source_endpoint_info = endpoint_info_i;
    ELSE
        SELECT IFNULL(MAX(queue_id),0) last_synced_id 
          FROM msg_queues.queues 
         WHERE queue_type = dst_queue_type_i
           AND queue_step > dst_queue_step_i
           AND dst_endpoint_info = endpoint_info_i;
    END IF;
       
    SET returnCode_o = 200;
    SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.d`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);    

END $$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;