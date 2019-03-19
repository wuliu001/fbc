USE `blockchain_cache`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `spreadPackingCache.confirm` */;

DROP PROCEDURE IF EXISTS `spreadPackingCache.confirm`;

DELIMITER $$
USE `blockchain_cache`$$
CREATE PROCEDURE `spreadPackingCache.confirm`(
    user_i                      INT,
    body_i                      LONGTEXT,
    OUT returnCode_o            INT,
    OUT returnMsg_o             LONGTEXT
    )
ll:BEGIN
    DECLARE v_procname                      VARCHAR(64) DEFAULT 'spreadPackingCache.confirm';
    DECLARE v_modulename                    VARCHAR(50) DEFAULT 'blockchain_cacheCache';
    DECLARE v_params_body                   LONGTEXT DEFAULT NULL;
    DECLARE v_returnCode                    INT DEFAULT 0;
    DECLARE v_returnMsg                     LONGTEXT DEFAULT '';
    DECLARE v_sql                           LONGTEXT DEFAULT '';
    DECLARE v_success_next_step             INT DEFAULT msg_queues.`getNextStep`('spreadPackingCache', 1, 0);
    DECLARE v_fail_next_step                INT DEFAULT msg_queues.`getNextStep`('spreadPackingCache', 1, 1);
    DECLARE v_fail_ids                      LONGTEXT DEFAULT NULL;
    
    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        SELECT GROUP_CONCAT(id) INTO v_fail_ids FROM blockchain_cache.temp_mpc_queue_id;
        ROLLBACK;
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        SET v_sql = CONCAT('UPDATE msg_queues.queues
                               SET queue_step = v_fail_next_step,
                                   cycle_cnt = CASE WHEN ',v_fail_next_step,' = queue_step THEN cycle_cnt + 1 ELSE 0 END,
                                   `status` = CASE WHEN ',v_fail_next_step,' <> queue_step THEN 1 ELSE `status` END,
                                   last_update_time = UTC_TIMESTAMP()
                             WHERE id IN (',v_fail_ids,')
                               AND queue_type = "spreadPackingCache"
                               AND queue_step = 1');
        IF IFNULL(v_sql,'') <> '' THEN
            CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);
        END IF;
    END;
    
    SET returnCode_o = 400;
    SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error');
    SET v_params_body = CONCAT('{}');
    SET body_i = TRIM(body_i);
    
    SET returnMsg_o = 'check input null data Error.';
    IF IFNULL(body_i,'') = '' THEN
        SET returnCode_o = 511;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'fail to create temp table.';
    CREATE TEMPORARY TABLE IF NOT EXISTS blockchain_cache.temp_mpc_queue_id (
     `id`                    BIGINT(20) UNSIGNED,
      KEY `key_id_index`     (`id`)
    ) ENGINE=InnoDB;
    TRUNCATE TABLE blockchain_cache.temp_mpc_queue_id;
    
    CREATE TEMPORARY TABLE IF NOT EXISTS blockchain_cache.temp_mpc_transactions (
     `address`                VARCHAR(256) ,
      KEY `key_address`       (`address`)
    ) ENGINE=InnoDB;
    TRUNCATE TABLE blockchain_cache.temp_mpc_transactions;
    
    START TRANSACTION;
    SET SESSION innodb_lock_wait_timeout = 120;
    
    SET returnMsg_o = 'fail to insert data into temp table.';
    SET v_sql = CONCAT('INSERT INTO blockchain_cache.temp_mpc_queue_id(id) VALUES ',body_i);
    CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);
    
    SET returnMsg_o = 'fail to get tobe update data from msg_queues.queues.';
    SELECT CASE WHEN COUNT(1) = 0 THEN '' 
           ELSE CONCAT('INSERT INTO blockchain_cache.temp_mpc_transactions(address) VALUES ',
                        GROUP_CONCAT(commons.`Util.getField2`(a.queues,'|$|',2))) END
      INTO v_sql
      FROM msg_queues.queues a,
           blockchain_cache.temp_mpc_queue_id b
     WHERE a.id = b.id
       AND a.queue_type = 'spreadPackingCache'
       AND a.queue_step = 1;
    IF IFNULL(v_sql,'') <> '' THEN
        CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);
    END IF;

    SET returnMsg_o = 'fail to update confirmtimes.';
    UPDATE blockchain_cache.transactions a,
           (SELECT address ,COUNT(1) AS cnt FROM blockchain_cache.temp_mpc_transactions GROUP BY address)b
       SET a.comfirmedTimes = IFNULL(a.comfirmedTimes,0) + b.cnt
     WHERE a.address = b.address;  
    
    SET returnMsg_o = 'fail to update msg_queues.';
    UPDATE msg_queues.queues a,
           blockchain_cache.temp_mpc_queue_id b
       SET queue_step = v_success_next_step,
           cycle_cnt = 0,
           last_update_time = UTC_TIMESTAMP()
     WHERE a.id = b.id
       AND a.queue_type = 'spreadPackingCache'
       AND a.queue_step = 1;
    
    COMMIT;

    SET returnCode_o = 200;
    SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
    
END $$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;