USE `msg_queues`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `sync_service.insert` */;

DROP PROCEDURE IF EXISTS `sync_service.insert`;

DELIMITER $$

CREATE PROCEDURE `sync_service.insert`(
    user_i            INT,
    syncService_id_i  VARCHAR(100),
    body_i            LONGTEXT,
    OUT returnCode_o  INT,
    OUT returnMsg_o   LONGTEXT
    )
ll:BEGIN
    DECLARE v_procname          VARCHAR(64) DEFAULT 'sync_service.insert';
    DECLARE v_modulename        VARCHAR(50) DEFAULT 'messageManager';
    DECLARE v_body              LONGTEXT DEFAULT NULL;
    DECLARE v_params_body       LONGTEXT DEFAULT NULL;
    DECLARE v_returnCode        INT DEFAULT 0;
    DECLARE v_returnMsg         LONGTEXT DEFAULT '';
    DECLARE v_queue_type        LONGTEXT;
    DECLARE v_sync_id           BIGINT(20);
    DECLARE v_sql               LONGTEXT;
    DECLARE v_cnt               INT;


    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        ROLLBACK;
        TRUNCATE TABLE msg_queues.`temp_ssi_service`;
        TRUNCATE TABLE msg_queues.`temp_ssi_service2`;
        DROP TABLE IF EXISTS msg_queues.`temp_ssi_service`;
        DROP TABLE IF EXISTS msg_queues.`temp_ssi_service2`;
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
    END;
    
    SET SESSION group_concat_max_len = 4294967295;
    SET returnCode_o = 400;
    SET returnMsg_o =  'Workflow Manager sync_service.insert Command Error.';
    SET v_params_body = CONCAT('{"user_i":"',user_i,'","syncService_id_i":"',IFNULL(syncService_id_i,''),'"}'); 
    SET syncService_id_i = TRIM(syncService_id_i);
    SET v_body = TRIM(body_i);
    
    SET returnMsg_o = 'check input null data Error.';
    IF IFNULL(v_body,'') = '' OR IFNULL(syncService_id_i,'') = '' THEN
        SET returnCode_o = 600;
        CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    CREATE TEMPORARY TABLE IF NOT EXISTS msg_queues.`temp_ssi_service` (
      `sync_id`              INT,
      `endpoint_id`          VARCHAR(100) NOT NULL,
      `endpoint_ip`          VARCHAR(20) NOT NULL,
      `endpoint_port`        VARCHAR(20) NOT NULL,
      `queue_types`          TEXT NOT NULL,
      `endpoint_weight`      INT NOT NULL
    ) ENGINE=InnoDB; 
    TRUNCATE TABLE msg_queues.`temp_ssi_service`;
    
    CREATE TEMPORARY TABLE IF NOT EXISTS msg_queues.`temp_ssi_service2` (
      `sync_id`              INT,
      `endpoint_id`          VARCHAR(100),
      `endpoint_ip`          VARCHAR(20),
      `endpoint_port`        VARCHAR(20),
      `queue_type`           VARCHAR(50),
      `endpoint_weight`      INT
    ) ENGINE=InnoDB; 
    TRUNCATE TABLE msg_queues.`temp_ssi_service2`;

    START TRANSACTION;
    SET SESSION innodb_lock_wait_timeout = 30;
    
    SET returnMsg_o = 'input sync service info Error.';
    INSERT INTO msg_queues.`sync_service` (syncService_id,create_time,last_sync_time)
         VALUES (syncService_id_i,UTC_TIMESTAMP(),UTC_TIMESTAMP())
             ON DUPLICATE KEY UPDATE last_sync_time = UTC_TIMESTAMP();

    SELECT IFNULL(MAX(id),0) INTO v_sync_id FROM msg_queues.sync_service WHERE syncService_id = syncService_id_i;
      
    SET returnMsg_o = 'input service confi to temp table Error.';
    SET v_sql = CONCAT('INSERT INTO msg_queues.temp_ssi_service(`endpoint_id`,`endpoint_ip`,`endpoint_port`,`queue_types`,`endpoint_weight`) VALUES ',v_body);
    CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);

    SET returnMsg_o = 'check input service config data Error.';
    SELECT COUNT(1)
      INTO v_cnt
      FROM msg_queues.temp_ssi_service
     WHERE IFNULL(`endpoint_id`,'') = ''
        OR IFNULL(`endpoint_ip`,'') = ''
        OR IFNULL(`endpoint_port`,'') = ''
        OR IFNULL(`queue_types`,'') = ''
        OR IFNULL(`endpoint_weight`,0) = 0
        OR v_sync_id = 0;
     IF v_cnt > 0 THEN
         ROLLBACK;
         TRUNCATE TABLE msg_queues.`temp_ssi_service`;
         TRUNCATE TABLE msg_queues.`temp_ssi_service2`;
         DROP TABLE IF EXISTS msg_queues.`temp_ssi_service`;
         DROP TABLE IF EXISTS msg_queues.`temp_ssi_service2`;
         SET returnCode_o = 600;
         LEAVE ll;
     END IF;

    SET returnMsg_o = 'INSERT temp_ssi_service2.';
    SELECT GROUP_CONCAT('("',endpoint_id,'","',endpoint_ip,'","',endpoint_port,'",',endpoint_weight,',',
           REPLACE(CONCAT('"', REPLACE(queue_types, ',', '","'), '"'), ',' ,
                   CONCAT('),("', endpoint_id,'","',endpoint_ip,'","',endpoint_port,'",',endpoint_weight,',')), ')')
      INTO v_sql
      FROM msg_queues.`temp_ssi_service`;
    SET v_sql = CONCAT('INSERT INTO msg_queues.`temp_ssi_service2`(endpoint_id,endpoint_ip,endpoint_port,endpoint_weight,queue_type) VALUES ', v_sql);
    CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);

    SET returnMsg_o = 'UPDATE temp_ssi_service2.';
    UPDATE msg_queues.temp_ssi_service2
       SET queue_type = TRIM(queue_type);

    SELECT GROUP_CONCAT(DISTINCT a.queue_type)
      INTO v_queue_type
      FROM msg_queues.temp_ssi_service2 a
      LEFT JOIN msg_queues.queue_workflows b ON a.queue_type = b.queue_type
     WHERE b.queue_type IS NULL;

    IF v_queue_type IS NOT NULL THEN
        ROLLBACK;
        TRUNCATE TABLE msg_queues.`temp_ssi_service`;
        TRUNCATE TABLE msg_queues.`temp_ssi_service2`;
        DROP TABLE IF EXISTS msg_queues.`temp_ssi_service`;
        DROP TABLE IF EXISTS msg_queues.`temp_ssi_service2`;
        SET returnCode_o = 600;
        SET returnMsg_o = CONCAT('queue_type ', v_queue_type, ' not in queue_workflows.');
        LEAVE ll;
    END IF;

    SET returnMsg_o = 'insert sync service config data Error.';
    DELETE FROM msg_queues.`sync_service_config` WHERE sync_id = v_sync_id;

    INSERT INTO msg_queues.`sync_service_config`(sync_id,endpoint_id,endpoint_ip,endpoint_port,queue_type,endpoint_weight,create_time,last_update_time)
    SELECT v_sync_id,a.endpoint_id,a.endpoint_ip,a.endpoint_port,a.queue_type,a.endpoint_weight,UTC_TIMESTAMP(),UTC_TIMESTAMP() 
      FROM msg_queues.`temp_ssi_service2` a
        ON DUPLICATE KEY UPDATE endpoint_weight = a.endpoint_weight,
                                last_update_time = UTC_TIMESTAMP();

    COMMIT;

    TRUNCATE TABLE msg_queues.`temp_ssi_service`;
    TRUNCATE TABLE msg_queues.`temp_ssi_service2`;
    DROP TABLE IF EXISTS msg_queues.`temp_ssi_service`;
    DROP TABLE IF EXISTS msg_queues.`temp_ssi_service2`;

    SET returnCode_o = 200;
    SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);    
    
END $$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;