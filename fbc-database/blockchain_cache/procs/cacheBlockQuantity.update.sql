USE `blockchain_cache`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `cacheBlockQuantity.update` */;

DROP PROCEDURE IF EXISTS `cacheBlockQuantity.update`;

DELIMITER $$
USE `blockchain_cache`$$
CREATE PROCEDURE `cacheBlockQuantity.update`(
    body_i                  LONGTEXT,
    user_i                  VARCHAR(50),
    goods_batch_id_i        VARCHAR(256),
    hashsign_i              VARCHAR(256),
    is_create_i             TINYINT(4),
    node_dns_i              VARCHAR(100),
    OUT returnCode_o        INT,
    OUT returnMsg_o         LONGTEXT
    )
ll:BEGIN
    DECLARE v_procname                         VARCHAR(64) DEFAULT 'cacheBlockQuantity.update';
    DECLARE v_modulename                       VARCHAR(50) DEFAULT 'blockchainCache';
    DECLARE v_body                             LONGTEXT;
    DECLARE v_goods_batch_id                   VARCHAR(256);
    DECLARE v_hashsign                         VARCHAR(256);
    DECLARE v_request_timestemp                BIGINT(20);
    DECLARE v_params_body                      LONGTEXT DEFAULT NULL;
    DECLARE v_returnCode                       INT DEFAULT 0;
    DECLARE v_returnMsg                        LONGTEXT DEFAULT '';
    DECLARE v_queue_body                       LONGTEXT;
    DECLARE v_count                            INT;
    DECLARE v_username                         VARCHAR(50);
    DECLARE v_type                             VARCHAR(32);
    DECLARE v_quantity                         DOUBLE;
    DECLARE v_countryofissuinglocation         VARCHAR(100);
    DECLARE v_cityofissuinglocation            VARCHAR(100);
    DECLARE v_zoneofissuinglocation            VARCHAR(100);
    DECLARE v_addressofissuinglocation         VARCHAR(100);
    DECLARE v_provinceofissuinglocation        VARCHAR(100);
    DECLARE v_goods_user                       VARCHAR(50);
    DECLARE v_sql                              LONGTEXT;
    DECLARE v_blockobject                      LONGTEXT;
    DECLARE v_dst_endpoint_info                VARCHAR(100);
    DECLARE v_user                             VARCHAR(50);
    DECLARE v_is_create                        TINYINT(4);
    DECLARE v_node_dns                         VARCHAR(100);
    DECLARE v_comments                         LONGTEXT;
    
    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        COMMIT;
        SELECT '' success_handled_tids,GROUP_CONCAT(queue_id) fail_handled_tids FROM blockchain_cache.temp_cbqu_body;
        TRUNCATE TABLE blockchain_cache.temp_cbqu_body;
        DROP TABLE IF EXISTS blockchain_cache.temp_cbqu_body;
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
    END;
    
    SET returnCode_o = 400;
    SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error');
    SET v_params_body = CONCAT('{"user_i":"',IFNULL(user_i,''),'"goods_batch_id_i":"',IFNULL(goods_batch_id_i,''),'"hashsign_i":"',IFNULL(hashsign_i,'')
                                 ,'"is_create_i":"',IFNULL(is_create_i,''),'"node_dns_i":"',IFNULL(node_dns_i,''),'"}');
    SET v_body = TRIM(body_i);
    SET v_goods_batch_id = TRIM(goods_batch_id_i);
    SET v_hashsign = TRIM(hashsign_i);
    SET v_is_create = TRIM(is_create_i);
    SET v_node_dns = TRIM(node_dns_i);
    SET v_user = TRIM(user_i);
    
    SET returnMsg_o = 'create temp table.';                                
    CREATE TEMPORARY TABLE IF NOT EXISTS blockchain_cache.temp_cbqu_body (
     `queue_id`               BIGINT(20),
     `body`                   LONGTEXT,
     KEY `key_queue_id`       (`queue_id`)
    ) ENGINE=InnoDB;
    TRUNCATE TABLE blockchain_cache.temp_cbqu_body;

    START TRANSACTION;
    SET SESSION innodb_lock_wait_timeout = 30;

    SET returnMsg_o = 'check body null data error.';
    IF IFNULL(v_body,'') = '' THEN
        COMMIT;
        SELECT '' success_handled_tids,GROUP_CONCAT(queue_id) fail_handled_tids FROM blockchain_cache.temp_cbqu_body;
        TRUNCATE TABLE blockchain_cache.temp_cbqu_body;
        DROP TABLE IF EXISTS blockchain_cache.temp_cbqu_body;
        SET returnCode_o = 511;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET v_sql = CONCAT('INSERT INTO blockchain_cache.temp_cbqu_body VALUES ',v_body);
    CALL commons.dynamic_sql_execute(v_sql,v_returnCode,v_returnMsg);

    SET returnMsg_o = 'check blockObject null data error.';
    SELECT MAX(`body`) INTO v_blockobject FROM blockchain_cache.temp_cbqu_body;
    IF IFNULL(v_blockobject,'') = '' THEN
        COMMIT;
        SELECT '' success_handled_tids,GROUP_CONCAT(queue_id) fail_handled_tids FROM blockchain_cache.temp_cbqu_body;
        TRUNCATE TABLE blockchain_cache.temp_cbqu_body;
        DROP TABLE IF EXISTS blockchain_cache.temp_cbqu_body;    
        SET returnCode_o = 511;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    SET returnMsg_o = 'check user null data error.';
    IF IFNULL(v_user,'') = '' THEN
        COMMIT;
        SELECT '' success_handled_tids,GROUP_CONCAT(queue_id) fail_handled_tids FROM blockchain_cache.temp_cbqu_body;
        TRUNCATE TABLE blockchain_cache.temp_cbqu_body;
        DROP TABLE IF EXISTS blockchain_cache.temp_cbqu_body;    
        SET returnCode_o = 511;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    SET returnMsg_o = 'check goods_batch_id null data error.';
    IF IFNULL(v_goods_batch_id,'') = '' THEN
        COMMIT;
        SELECT '' success_handled_tids,GROUP_CONCAT(queue_id) fail_handled_tids FROM blockchain_cache.temp_cbqu_body;
        TRUNCATE TABLE blockchain_cache.temp_cbqu_body;
        DROP TABLE IF EXISTS blockchain_cache.temp_cbqu_body;
        SET returnCode_o = 511;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    SET returnMsg_o = 'check hashsign null data error.';
    IF IFNULL(v_hashsign,'') = '' THEN
        COMMIT;
        SELECT '' success_handled_tids,GROUP_CONCAT(queue_id) fail_handled_tids FROM blockchain_cache.temp_cbqu_body;
        TRUNCATE TABLE blockchain_cache.temp_cbqu_body;
        DROP TABLE IF EXISTS blockchain_cache.temp_cbqu_body;
        SET returnCode_o = 511;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'check is_create null data error.';
    IF v_is_create IS NULL THEN
        COMMIT;
        SELECT '' success_handled_tids,GROUP_CONCAT(queue_id) fail_handled_tids FROM blockchain_cache.temp_cbqu_body;
        TRUNCATE TABLE blockchain_cache.temp_cbqu_body;
        DROP TABLE IF EXISTS blockchain_cache.temp_cbqu_body;    
        SET returnCode_o = 511;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'check node_dns null data error.';
    IF IFNULL(v_node_dns,'') = '' THEN
        COMMIT;
        SELECT '' success_handled_tids,GROUP_CONCAT(queue_id) fail_handled_tids FROM blockchain_cache.temp_cbqu_body;
        TRUNCATE TABLE blockchain_cache.temp_cbqu_body;
        DROP TABLE IF EXISTS blockchain_cache.temp_cbqu_body;    
        SET returnCode_o = 511;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    SET returnMsg_o = 'check blockObject json format error.';
    IF IFNULL(JSON_VALID(v_blockobject),0) = 0 THEN
        COMMIT;
        SELECT '' success_handled_tids,GROUP_CONCAT(queue_id) fail_handled_tids FROM blockchain_cache.temp_cbqu_body;
        TRUNCATE TABLE blockchain_cache.temp_cbqu_body;
        DROP TABLE IF EXISTS blockchain_cache.temp_cbqu_body;    
        SET returnCode_o = 512;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    SELECT TRIM(BOTH '"' FROM v_blockobject->"$.User"),
           TRIM(BOTH '"' FROM v_blockobject->"$.Type"),
           TRIM(BOTH '"' FROM v_blockobject->"$.Quantity"),
           TRIM(BOTH '"' FROM v_blockobject->"$.countryOfIssuingLocation"),
           TRIM(BOTH '"' FROM v_blockobject->"$.provinceOfIssuingLocation"),
           TRIM(BOTH '"' FROM v_blockobject->"$.cityOfIssuingLocation"),
           TRIM(BOTH '"' FROM v_blockobject->"$.zoneOfIssuingLocation"),
           TRIM(BOTH '"' FROM v_blockobject->"$.addressOfIssuingLocation"),
           TRIM(BOTH '"' FROM v_blockobject->"$.request_timestemp"),
           TRIM(BOTH '"' FROM v_blockobject->"$.Comments")
	  INTO v_username,
           v_type,
           v_quantity,
           v_countryofissuinglocation,
           v_provinceofissuinglocation,
           v_cityofissuinglocation,
           v_zoneofissuinglocation,
           v_addressofissuinglocation,
           v_request_timestemp,
           v_comments;
           
    SET returnMsg_o = 'check modify blockObject user null data.';
    IF IFNULL(v_username,'') = '' THEN
        COMMIT;
        SELECT '' success_handled_tids,GROUP_CONCAT(queue_id) fail_handled_tids FROM blockchain_cache.temp_cbqu_body;
        TRUNCATE TABLE blockchain_cache.temp_cbqu_body;
        DROP TABLE IF EXISTS blockchain_cache.temp_cbqu_body;
        SET returnCode_o = 513;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;       

    SET returnMsg_o = 'check modify blockObject type null data.';
    IF IFNULL(v_type,'') = '' THEN
        COMMIT;
        SELECT '' success_handled_tids,GROUP_CONCAT(queue_id) fail_handled_tids FROM blockchain_cache.temp_cbqu_body;
        TRUNCATE TABLE blockchain_cache.temp_cbqu_body;
        DROP TABLE IF EXISTS blockchain_cache.temp_cbqu_body;
        SET returnCode_o = 513;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;       

    SET returnMsg_o = 'check modify blockObject quantity null data.';
    IF v_quantity IS NULL THEN
        COMMIT;
        SELECT '' success_handled_tids,GROUP_CONCAT(queue_id) fail_handled_tids FROM blockchain_cache.temp_cbqu_body;
        TRUNCATE TABLE blockchain_cache.temp_cbqu_body;
        DROP TABLE IF EXISTS blockchain_cache.temp_cbqu_body;
        SET returnCode_o = 513;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;        

    SET returnMsg_o = 'check modify blockObject countryofissuinglocation null data.';
    IF IFNULL(v_countryofissuinglocation,'') = '' THEN
        COMMIT;
        SELECT '' success_handled_tids,GROUP_CONCAT(queue_id) fail_handled_tids FROM blockchain_cache.temp_cbqu_body;
        TRUNCATE TABLE blockchain_cache.temp_cbqu_body;
        DROP TABLE IF EXISTS blockchain_cache.temp_cbqu_body;
        SET returnCode_o = 513;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;       

    SET returnMsg_o = 'check modify blockObject provinceofissuinglocation null data.';
    IF IFNULL(v_provinceofissuinglocation,'') = '' THEN
        COMMIT;
        SELECT '' success_handled_tids,GROUP_CONCAT(queue_id) fail_handled_tids FROM blockchain_cache.temp_cbqu_body;
        TRUNCATE TABLE blockchain_cache.temp_cbqu_body;
        DROP TABLE IF EXISTS blockchain_cache.temp_cbqu_body;
        SET returnCode_o = 513;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    SET returnMsg_o = 'check modify blockObject zoneofissuinglocation null data.';
    IF IFNULL(v_zoneofissuinglocation,'') = '' THEN
        COMMIT;
        SELECT '' success_handled_tids,GROUP_CONCAT(queue_id) fail_handled_tids FROM blockchain_cache.temp_cbqu_body;
        TRUNCATE TABLE blockchain_cache.temp_cbqu_body;
        DROP TABLE IF EXISTS blockchain_cache.temp_cbqu_body;
        SET returnCode_o = 513;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'check modify blockObject addressofissuinglocation null data.';
    IF IFNULL(v_addressofissuinglocation,'') = '' THEN
        COMMIT;
        SELECT '' success_handled_tids,GROUP_CONCAT(queue_id) fail_handled_tids FROM blockchain_cache.temp_cbqu_body;
        TRUNCATE TABLE blockchain_cache.temp_cbqu_body;
        DROP TABLE IF EXISTS blockchain_cache.temp_cbqu_body;
        SET returnCode_o = 513;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'check modify blockObject request_timestemp null data.';
    IF v_request_timestemp IS NULL THEN
        COMMIT;
        SELECT '' success_handled_tids,GROUP_CONCAT(queue_id) fail_handled_tids FROM blockchain_cache.temp_cbqu_body;
        TRUNCATE TABLE blockchain_cache.temp_cbqu_body;
        DROP TABLE IF EXISTS blockchain_cache.temp_cbqu_body;
        SET returnCode_o = 513;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    SET returnMsg_o = 'check modify blockObject comments null data.';
    IF IFNULL(v_comments,'') = '' THEN
        COMMIT;
        SELECT '' success_handled_tids,GROUP_CONCAT(queue_id) fail_handled_tids FROM blockchain_cache.temp_cbqu_body;
        TRUNCATE TABLE blockchain_cache.temp_cbqu_body;
        DROP TABLE IF EXISTS blockchain_cache.temp_cbqu_body;
        SET returnCode_o = 513;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'check modify blockObject user and orignal user data error.';
    SELECT `user` INTO v_goods_user FROM blockchain_cache.`block` WHERE `hashsign` = v_goods_batch_id;
    IF IFNULL(v_goods_user,'') <> IFNULL(v_username,'') OR IFNULL(v_username,'') <> IFNULL(v_user,'') THEN
        COMMIT;
        SELECT '' success_handled_tids,GROUP_CONCAT(queue_id) fail_handled_tids FROM blockchain_cache.temp_cbqu_body;
        TRUNCATE TABLE blockchain_cache.temp_cbqu_body;
        DROP TABLE IF EXISTS blockchain_cache.temp_cbqu_body;
        SET returnCode_o = 514;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;  
    
    SET returnMsg_o = 'fail to add goods_batch_id to body.';
    SET v_blockobject = json_set(v_blockobject,"$.goods_batch_id",v_goods_batch_id);
    
    SET v_queue_body = CONCAT('(null,','''','[',v_blockobject,',"',v_hashsign,'","',v_node_dns,'"]','''',',0)');
    
    SELECT COUNT(1)  INTO v_count FROM blockchain_cache.`block` WHERE `hashsign` = v_hashsign;
    IF v_count = 0 THEN 
        ##insert into queueu
        SET returnMsg_o = 'fail to insert data into queue.';
        CALL blockchain_cache.`cacheQueue.insert`('syncBlockCache',v_queue_body,v_node_dns, v_returnCode,v_returnMsg);
        IF v_returnCode <> 200 THEN
            COMMIT;
            SET returnCode_o = v_returnCode;
            SET returnMsg_o = v_returnMsg;
            SELECT '' success_handled_tids,GROUP_CONCAT(queue_id) fail_handled_tids FROM blockchain_cache.temp_cbqu_body;
            TRUNCATE TABLE blockchain_cache.temp_cbi_body;
            DROP TABLE IF EXISTS blockchain_cache.temp_cbi_body;                
            CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
            LEAVE ll;
        END IF;
        
        #sync msg
        SET returnMsg_o = 'fail to insert data into cache block.';
        INSERT INTO blockchain_cache.`block`(`user`,`transactionType`,`blockObject`,`hashsign`,`timestamp`,`comfirmedTimes`)
             VALUES (v_user,v_type,v_blockobject,v_hashsign,v_request_timestemp,0);
        
    ELSEIF v_count > 0 AND v_is_create = 0 THEN           
       SET returnMsg_o = 'fail to update cache block.';
        UPDATE blockchain_cache.`block` 
           SET `comfirmedTimes` = `comfirmedTimes` + 1 
         WHERE `hashsign` = v_hashsign;
    END IF;
    
    SELECT GROUP_CONCAT(queue_id) success_handled_tids,'' fail_handled_tids FROM blockchain_cache.temp_cbqu_body;
    
    COMMIT;
    TRUNCATE TABLE blockchain_cache.temp_cbqu_body;
    DROP TABLE IF EXISTS blockchain_cache.temp_cbqu_body;

    SET returnCode_o = 200;
    SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
    
END $$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;