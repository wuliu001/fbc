USE `blockchain_cache`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `cacheBlock.insert` */;

DROP PROCEDURE IF EXISTS `cacheBlock.insert`;

DELIMITER $$
USE `blockchain_cache`$$
CREATE PROCEDURE `cacheBlock.insert`( 
    body_i                      LONGTEXT,
    user_i                      VARCHAR(50),
    type_i                      VARCHAR(32), 
    hashsign_i                  VARCHAR(256),
    is_create_i                 TINYINT(4),
    node_dns_i                  VARCHAR(100),
    OUT goods_batch_id_o        VARCHAR(256),
    OUT returnCode_o            INT,
    OUT returnMsg_o             LONGTEXT
    )
ll:BEGIN
    DECLARE v_procname          VARCHAR(64) DEFAULT 'cacheBlock.insert';
    DECLARE v_modulename        VARCHAR(50) DEFAULT 'blockchainCache';
    DECLARE v_user              VARCHAR(50);
    DECLARE v_type              VARCHAR(32);
    DECLARE v_body              LONGTEXT;
    DECLARE v_hashsign          VARCHAR(256);
    DECLARE v_is_create         TINYINT(4);
    DECLARE v_node_dns          VARCHAR(100);
    DECLARE v_params_body       LONGTEXT DEFAULT NULL;
    DECLARE v_returnCode        INT DEFAULT 0;
    DECLARE v_returnMsg         LONGTEXT DEFAULT '';
    DECLARE v_queue_body        LONGTEXT;
    DECLARE v_count             INT;
    DECLARE v_timestamp         BIGINT(20);
    DECLARE v_sql               LONGTEXT;
    DECLARE v_blockobject       LONGTEXT;
    DECLARE done                INT DEFAULT 0;
    DECLARE v_dst_endpoint_info VARCHAR(100);

    #send to other nodes
    DECLARE cur_next_serv CURSOR FOR SELECT DISTINCT CONCAT(endpoint_ip,':',endpoint_port)
                                       FROM msg_queues.sync_service_config 
                                      WHERE queue_type = 'syncBlockCache'
                                        AND CONCAT(endpoint_ip,':',endpoint_port) <> v_node_dns;
                                        
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    
    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        SELECT '' success_handled_tids,GROUP_CONCAT(queue_id) fail_handled_tids FROM blockchain_cache.temp_cbi_body;
        TRUNCATE TABLE blockchain_cache.temp_cbi_body;
        DROP TABLE IF EXISTS blockchain_cache.temp_cbi_body;        
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
    END;
    
    SET v_params_body = CONCAT('{"user_i":"',IFNULL(user_i,''),'","type_i":"',IFNULL(type_i,''),'","hashsign_i":"',IFNULL(hashsign_i,'')
                                 ,'","is_create_i":"',IFNULL(is_create_i,''),'","node_dns_i":"',IFNULL(node_dns_i,''),'"}');
    SET v_user = TRIM(user_i);
    SET v_type = TRIM(type_i);
    SET v_hashsign = TRIM(hashsign_i);
    SET v_body = TRIM(body_i);
    SET v_is_create = TRIM(is_create_i);
    SET v_node_dns = TRIM(node_dns_i);
    
    SET returnMsg_o = 'create temp table.';                                
    CREATE TEMPORARY TABLE IF NOT EXISTS blockchain_cache.temp_cbi_body (
     `queue_id`               BIGINT(20),
     `body`                   LONGTEXT,
     KEY `key_queue_id`       (`queue_id`)
    ) ENGINE=InnoDB;
    TRUNCATE TABLE blockchain_cache.temp_cbi_body;

    SET returnMsg_o = 'check body null data error.';
    IF IFNULL(v_body,'') = '' THEN
        SELECT '' success_handled_tids,GROUP_CONCAT(queue_id) fail_handled_tids FROM blockchain_cache.temp_cbi_body;
        TRUNCATE TABLE blockchain_cache.temp_cbi_body;
        DROP TABLE IF EXISTS blockchain_cache.temp_cbi_body;
        SET returnCode_o = 511;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET v_sql = CONCAT('INSERT INTO blockchain_cache.temp_cbi_body VALUES ',v_body);
    CALL commons.dynamic_sql_execute(v_sql,v_returnCode,v_returnMsg);
    
    SET returnMsg_o = 'check blockObject null data error.';
    SELECT MAX(`body`) INTO v_blockobject FROM blockchain_cache.temp_cbi_body;
    IF IFNULL(v_blockobject,'') = '' THEN
        SELECT '' success_handled_tids,GROUP_CONCAT(queue_id) fail_handled_tids FROM blockchain_cache.temp_cbi_body;
        TRUNCATE TABLE blockchain_cache.temp_cbi_body;
        DROP TABLE IF EXISTS blockchain_cache.temp_cbi_body;    
        SET returnCode_o = 511;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'check user null data error.';
    IF IFNULL(v_user,'') = '' THEN
        SELECT '' success_handled_tids,GROUP_CONCAT(queue_id) fail_handled_tids FROM blockchain_cache.temp_cbi_body;
        TRUNCATE TABLE blockchain_cache.temp_cbi_body;
        DROP TABLE IF EXISTS blockchain_cache.temp_cbi_body;    
        SET returnCode_o = 511;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'check transactionType null data error.';
    IF IFNULL(v_type,'') = '' THEN
        SELECT '' success_handled_tids,GROUP_CONCAT(queue_id) fail_handled_tids FROM blockchain_cache.temp_cbi_body;
        TRUNCATE TABLE blockchain_cache.temp_cbi_body;
        DROP TABLE IF EXISTS blockchain_cache.temp_cbi_body;    
        SET returnCode_o = 511;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;    

    SET returnMsg_o = 'check hashsign null data error.';
    IF IFNULL(v_hashsign,'') = '' THEN
        SELECT '' success_handled_tids,GROUP_CONCAT(queue_id) fail_handled_tids FROM blockchain_cache.temp_cbi_body;
        TRUNCATE TABLE blockchain_cache.temp_cbi_body;
        DROP TABLE IF EXISTS blockchain_cache.temp_cbi_body;    
        SET returnCode_o = 511;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'check is_create null data error.';
    IF v_is_create IS NULL THEN
        SELECT '' success_handled_tids,GROUP_CONCAT(queue_id) fail_handled_tids FROM blockchain_cache.temp_cbi_body;
        TRUNCATE TABLE blockchain_cache.temp_cbi_body;
        DROP TABLE IF EXISTS blockchain_cache.temp_cbi_body;    
        SET returnCode_o = 511;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'check node_dns null data error.';
    IF IFNULL(v_node_dns,'') = '' THEN
        SELECT '' success_handled_tids,GROUP_CONCAT(queue_id) fail_handled_tids FROM blockchain_cache.temp_cbi_body;
        TRUNCATE TABLE blockchain_cache.temp_cbi_body;
        DROP TABLE IF EXISTS blockchain_cache.temp_cbi_body;    
        SET returnCode_o = 511;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    SET returnMsg_o = 'check blockObject json format error.';
    IF IFNULL(JSON_VALID(v_blockobject),0) = 0 THEN
        SELECT '' success_handled_tids,GROUP_CONCAT(queue_id) fail_handled_tids FROM blockchain_cache.temp_cbi_body;
        TRUNCATE TABLE blockchain_cache.temp_cbi_body;
        DROP TABLE IF EXISTS blockchain_cache.temp_cbi_body;    
        SET returnCode_o = 512;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'check request_timestemp null data error.';
    SET v_timestamp = TRIM(BOTH '"' FROM v_blockobject->"$.request_timestemp");
    IF v_timestamp IS NULL THEN
        SELECT '' success_handled_tids,GROUP_CONCAT(queue_id) fail_handled_tids FROM blockchain_cache.temp_cbi_body;
        TRUNCATE TABLE blockchain_cache.temp_cbi_body;
        DROP TABLE IF EXISTS blockchain_cache.temp_cbi_body;    
        SET returnCode_o = 513;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'fail to concat queue body.';
    SET v_queue_body = CONCAT('(null,','''','[',v_blockobject,',"',v_hashsign,'","',v_node_dns,'"]','''',',0)');
    
    SELECT COUNT(1)  INTO v_count FROM blockchain_cache.`block` WHERE `hashsign` = v_hashsign;
    IF v_count = 0 THEN 
        ##insert into queueu
        SET returnMsg_o = 'fail to insert data into queue.';
        OPEN cur_next_serv;
        S:REPEAT
            FETCH cur_next_serv INTO v_dst_endpoint_info;
            IF NOT done THEN
                CALL `msg_queues`.`queues.insert`(0, v_queue_body, 'syncBlockCache', 0, v_dst_endpoint_info, v_returnCode,v_returnMsg);
                IF v_returnCode <> 200 THEN
                    SELECT '' success_handled_tids,GROUP_CONCAT(queue_id) fail_handled_tids FROM blockchain_cache.temp_cbi_body;
                    TRUNCATE TABLE blockchain_cache.temp_cbi_body;
                    DROP TABLE IF EXISTS blockchain_cache.temp_cbi_body;                
                    CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
                    LEAVE ll;
                END IF;        
           END IF;
        UNTIL done END REPEAT;
        CLOSE cur_next_serv;
        
        #sync msg
        SET returnMsg_o = 'fail to insert data into cache block.';
        INSERT INTO blockchain_cache.`block`(`user`,`transactionType`,`blockObject`,`hashsign`,`timestamp`,`comfirmedTimes`)
             VALUES (v_user,v_type,v_blockobject,v_hashsign,v_timestamp,0);
        
        UPDATE msg_queues.queues a
           SET a.queues = CONCAT(a.queue_id,'|$|',a.queues),
               a.queue_step = msg_queues.`getNextStep`('syncBlockCache', 0, 0),
               a.last_update_time = UTC_TIMESTAMP()
         WHERE a.queue_type = 'syncBlockCache' AND a.queue_step = 0;
        
        ##output hashsign
        IF v_is_create = 1 THEN 
            SET goods_batch_id_o = v_hashsign;
        END IF;
    ELSEIF v_count > 0 AND v_is_create = 0 THEN           
        ##insert into queueu
        SET returnMsg_o = 'fail to send confirm msg into queue.';
        OPEN cur_next_serv;
        S:REPEAT
            FETCH cur_next_serv INTO v_dst_endpoint_info;
            IF NOT done THEN
                CALL `msg_queues`.`queues.insert`(0, v_queue_body, 'syncBlockCache', 0, v_dst_endpoint_info, v_returnCode,v_returnMsg);
                IF v_returnCode <> 200 THEN
                    SELECT '' success_handled_tids,GROUP_CONCAT(queue_id) fail_handled_tids FROM blockchain_cache.temp_cbi_body;
                    TRUNCATE TABLE blockchain_cache.temp_cbi_body;
                    DROP TABLE IF EXISTS blockchain_cache.temp_cbi_body;                
                    CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
                    LEAVE ll;
                END IF;        
           END IF;
        UNTIL done END REPEAT;
        CLOSE cur_next_serv;

       SET returnMsg_o = 'fail to update cache block.';
        UPDATE blockchain_cache.`block` 
           SET `comfirmedTimes` = `comfirmedTimes` + 1 
         WHERE `hashsign` = v_hashsign;

        UPDATE msg_queues.queues a
           SET a.queues = CONCAT(a.queue_id,'|$|',a.queues),
               a.queue_step = msg_queues.`getNextStep`('syncBlockCache', 0, 0),
               a.last_update_time = UTC_TIMESTAMP()
         WHERE a.queue_type = 'syncBlockCache' AND a.queue_step = 0;
        
    ELSEIF v_count > 0 AND v_is_create = 1 THEN  
        SET goods_batch_id_o = v_hashsign;
    END IF;
    
    SELECT GROUP_CONCAT(queue_id) success_handled_tids,'' fail_handled_tids FROM blockchain_cache.temp_cbi_body;
    
    TRUNCATE TABLE blockchain_cache.temp_cbi_body;
    DROP TABLE IF EXISTS blockchain_cache.temp_cbi_body;

    SET returnCode_o = 200;
    SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
    
END $$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;