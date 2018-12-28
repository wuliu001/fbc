USE `msg_queues`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `get_next_server` */;

DROP PROCEDURE IF EXISTS `get_next_server`;

DELIMITER $$

CREATE PROCEDURE `get_next_server`(
    syncService_id_i                VARCHAR(100), 
    queue_type_i                    VARCHAR(50),
    OUT endpoint_info_o             VARCHAR(50),
    OUT returnCode_o                INT,
    OUT returnMsg_o                 TEXT)
ll:BEGIN
    DECLARE v_sync_id                  INT;
    DECLARE v_id                       BIGINT;
    DECLARE v_params_body              LONGTEXT DEFAULT NULL;
    DECLARE v_procname                 VARCHAR(50) DEFAULT 'get_next_server';
    DECLARE v_modulename               VARCHAR(50) DEFAULT 'messageManager';
    DECLARE v_body                     LONGTEXT DEFAULT NULL;
    DECLARE v_max_endpoint_weight      INT;
    DECLARE v_sum_endpoint_weight      INT;
    DECLARE v_returnCode               INT;
    DECLARE v_returnMsg                LONGTEXT;
    
    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;   
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
    END;

    SET returnCode_o = 400;
    SET returnMsg_o = CONCAT(v_modulename,v_procname,' command Error.');;

    SELECT MAX(a.id)
      INTO v_sync_id
      FROM `sync_service` a
    WHERE a.syncService_id = syncService_id_i;

    SELECT SUM(endpoint_weight) INTO v_sum_endpoint_weight FROM `sync_service_config` WHERE sync_id = v_sync_id AND queue_type = queue_type_i;
    IF v_sum_endpoint_weight IS NULL THEN
        SET returnCode_o = 653;
        SET returnMsg_o = CONCAT('input parameter queue_type_i ', IFNULL(queue_type_i,'null') , ' is wrong');
        LEAVE ll;
    END IF;

    SET returnMsg_o = 'update sync_service_config';
    UPDATE `sync_service_config`
       SET cur_weight_after_selected = cur_weight_after_selected + endpoint_weight
     WHERE sync_id = v_sync_id
       AND queue_type = queue_type_i;


    SELECT MAX(cur_weight_after_selected) INTO v_max_endpoint_weight FROM `sync_service_config` WHERE sync_id = v_sync_id AND queue_type = queue_type_i;

    SET returnMsg_o = 'get endpoint_info_o.';
    SELECT MIN(a.id)
      INTO v_id
      FROM `sync_service_config` a
     WHERE a.sync_id = v_sync_id 
       AND queue_type = queue_type_i
       AND a.cur_weight_after_selected = v_max_endpoint_weight;

    SELECT CONCAT('http://', a.endpoint_ip, ':', a.endpoint_port)
      INTO endpoint_info_o
      FROM `sync_service_config` a
     WHERE a.id = v_id;

    SET returnMsg_o = 'update sync_service_config.';
    UPDATE `sync_service_config`
       SET cur_weight_after_selected = cur_weight_after_selected - v_sum_endpoint_weight
     WHERE id = v_id;

    SET returnCode_o = 200;
    SET returnMsg_o = 'OK';
END$$

DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;