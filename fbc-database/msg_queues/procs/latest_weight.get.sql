

USE `msg_queues`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `latest_weight.get` */;

DROP PROCEDURE IF EXISTS `latest_weight.get`;

DELIMITER $$

CREATE PROCEDURE `latest_weight.get`(
    user_i               INT,
    syncService_id_i     VARCHAR(100),
    OUT returnCode_o     INT,
    OUT returnMsg_o      LONGTEXT)
ll:BEGIN
    DECLARE v_sync_id                  INT;
    DECLARE v_params_body              LONGTEXT DEFAULT '{}';
    DECLARE v_procname                 VARCHAR(50) DEFAULT 'latest_weight.get';
    DECLARE v_modulename               VARCHAR(50) DEFAULT 'messageManager';
    DECLARE v_returnCode               INT;
    DECLARE v_returnMsg                LONGTEXT;
    
    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
    END;

    SET returnCode_o = 400;
    SET returnMsg_o =  CONCAT(v_modulename, ' ', v_procname, ' command Error');
    SET syncService_id_i = TRIM(syncService_id_i);
    
    SET returnMsg_o = 'fail to check input parameter syncService_id_i.';
    SELECT MAX(id)
      INTO v_sync_id
      FROM msg_queues.`sync_service`
     WHERE syncService_id = syncService_id_i;

    IF v_sync_id IS NULL THEN
        SET returnCode_o = 600;
        CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    SET returnMsg_o = 'fail to get latest weight.';
    SELECT GROUP_CONCAT('("',CONCAT_WS('","', syncService_id_i, endpoint_id,endpoint_ip,endpoint_port, queue_type, cur_weight_after_selected),'")') 
        AS cur_weight_after_selected
      FROM msg_queues.`sync_service_config` 
     WHERE sync_id = v_sync_id;

    SET returnCode_o = 200;
    SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(user_i,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
END$$

DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;