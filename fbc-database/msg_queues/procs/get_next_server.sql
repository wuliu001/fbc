

USE `msg_queues`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `get_next_server` */;

DROP PROCEDURE IF EXISTS `get_next_server`;

DELIMITER $$

CREATE PROCEDURE `get_next_server`(
    syncService_id_i                VARCHAR(100), 
    body_i                          LONGTEXT,
    OUT endpoint_details            LONGTEXT,
    OUT returnCode_o                INT,
    OUT returnMsg_o                 LONGTEXT)
ll:BEGIN
    DECLARE v_sync_id                  INT;
    DECLARE v_id                       BIGINT;
    DECLARE v_params_body              LONGTEXT DEFAULT NULL;
    DECLARE v_procname                 VARCHAR(50) DEFAULT 'get_next_server';
    DECLARE v_modulename               VARCHAR(50) DEFAULT 'messageManager';
    DECLARE v_max_endpoint_weight      INT;
    DECLARE v_sum_endpoint_weight      INT;
    DECLARE v_returnCode               INT;
    DECLARE v_returnMsg                LONGTEXT;
    DECLARE v_sql                      LONGTEXT;
    
    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        ROLLBACK;
        TRUNCATE TABLE msg_queues.`temp_gns_queue_types_copy`;
        TRUNCATE TABLE msg_queues.`temp_gns_queue_types`;
        DROP TABLE IF EXISTS msg_queues.`temp_gns_queue_types`;    
        DROP TABLE IF EXISTS msg_queues.`temp_gns_queue_types_copy`;
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
    END;

    SET returnCode_o = 400;
    SET returnMsg_o =  CONCAT(v_modulename, ' ', v_procname, ' command Error');
    SET v_params_body = CONCAT('{"syncService_id_i":"',IFNULL(syncService_id_i,'NULL'),'"}'); 
    SET syncService_id_i = TRIM(syncService_id_i);
    SET body_i = TRIM(body_i);
    
    SET returnMsg_o = 'check input null data error.';
    IF IFNULL(syncService_id_i,'') = '' OR IFNULL(body_i,'') = '' THEN
        SET returnCode_o = 651;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF; 

    SET returnMsg_o = 'fail to get the sync service id.';
    SELECT MAX(id)
      INTO v_sync_id
      FROM `sync_service` 
     WHERE syncService_id = syncService_id_i;
     
    IF v_sync_id IS NULL THEN
        SET returnCode_o = 652;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;    
    
    SET returnMsg_o = 'fail to create temp table.';
    CREATE TEMPORARY TABLE IF NOT EXISTS msg_queues.`temp_gns_queue_types` (
      `sync_id`                   INT,
      `queue_type`                VARCHAR(50),
      `out_endpoint_info`         VARCHAR(100),
      `sum_weight`                INT,
      `max_weight`                INT,
      `selected_id`               INT,
      KEY `sync_id_idx`           (`sync_id`),
      KEY `queue_type_idx`        (`queue_type`),
      KEY `selected_id_idx`       (`selected_id`)
    ) ENGINE=InnoDB;
    TRUNCATE TABLE msg_queues.`temp_gns_queue_types`;
    
    CREATE  TEMPORARY TABLE IF NOT EXISTS msg_queues.`temp_gns_queue_types_copy` LIKE msg_queues.`temp_gns_queue_types`;
    TRUNCATE TABLE msg_queues.`temp_gns_queue_types_copy`;
    
    START TRANSACTION;
    SET SESSION innodb_lock_wait_timeout = 30;
    
    SET returnMsg_o = 'fail to deal with temp table.';
    SET v_sql = CONCAT('INSERT INTO msg_queues.`temp_gns_queue_types`(sync_id,queue_type) VALUES ',CONCAT('(',v_sync_id,',''',REPLACE(body_i,',',CONCAT('''),(',v_sync_id,',''')),''')'));
    CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg); 
    
    INSERT INTO msg_queues.`temp_gns_queue_types_copy`(queue_type,sync_id,sum_weight,max_weight)
    SELECT a.queue_type, a.sync_id, SUM(endpoint_weight), MAX(cur_weight_after_selected + endpoint_weight)
      FROM msg_queues.`temp_gns_queue_types` a
      LEFT JOIN msg_queues.`sync_service_config`  b 
        ON a.sync_id = b.sync_id
       AND a.queue_type = b.queue_type
     GROUP BY a.queue_type,a.sync_id;

    SET returnMsg_o = 'fail to get the endpoint weight.';
    IF EXISTS (SELECT 1 FROM msg_queues.`temp_gns_queue_types_copy` WHERE sum_weight IS NULL )THEN
        COMMIT;
        TRUNCATE TABLE msg_queues.`temp_gns_queue_types_copy`;
        TRUNCATE TABLE msg_queues.`temp_gns_queue_types`;
        DROP TABLE IF EXISTS msg_queues.`temp_gns_queue_types`;    
        DROP TABLE IF EXISTS msg_queues.`temp_gns_queue_types_copy`;
        SET returnCode_o = 653;
        SET returnMsg_o = CONCAT(returnMsg_o,' input parameter queue_type_i ', IFNULL(body_i,'NULL'));
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    SET returnMsg_o = 'fail to deal with the output server.';
    UPDATE msg_queues.`sync_service_config` a,
           msg_queues.`temp_gns_queue_types_copy` b 
       SET b.selected_id = a.id,
           b.out_endpoint_info =  CONCAT('http://', a.endpoint_ip, ':', a.endpoint_port)
     WHERE a.sync_id = b.sync_id
       AND a.queue_type = b.queue_type
       AND a.cur_weight_after_selected + a.endpoint_weight = b.max_weight;

    SET returnMsg_o = 'fail to update sync_service_config .';
    UPDATE msg_queues.`sync_service_config` a,
           msg_queues.`temp_gns_queue_types_copy` b 
       SET a.cur_weight_after_selected = ( CASE WHEN a.id = b.selected_id THEN a.cur_weight_after_selected + a.endpoint_weight - sum_weight ELSE cur_weight_after_selected + endpoint_weight END )    
     WHERE a.sync_id = b.sync_id
       AND a.queue_type = b.queue_type;
    
    SELECT GROUP_CONCAT('("',queue_type,'","',out_endpoint_info,'")') INTO endpoint_details FROM msg_queues.`temp_gns_queue_types_copy`;
    
    COMMIT;
    
    SET returnCode_o = 200;
    SET returnMsg_o = 'OK';
    
    TRUNCATE TABLE msg_queues.`temp_gns_queue_types_copy`;
    TRUNCATE TABLE msg_queues.`temp_gns_queue_types`;
    DROP TABLE IF EXISTS msg_queues.`temp_gns_queue_types`;    
    DROP TABLE IF EXISTS msg_queues.`temp_gns_queue_types_copy`;
    CALL `commons`.`log_module.d`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
END$$

DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;