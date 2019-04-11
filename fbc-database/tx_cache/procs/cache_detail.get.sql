USE `tx_cache`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `cache_detail.get` */;

DROP PROCEDURE IF EXISTS `cache_detail.get`;

DELIMITER $$
CREATE PROCEDURE `cache_detail.get`(
    accountAddress_i         VARCHAR(256),
    current_user_nonce_i     INT,
    time_diff_i              INT,
    OUT returnCode_o         INT,
    OUT returnMsg_o          LONGTEXT)
ll:BEGIN
    DECLARE v_cnt                    INT;
    DECLARE v_procname               VARCHAR(100) DEFAULT 'cache_detail.get';
    DECLARE v_modulename             VARCHAR(50) DEFAULT 'tx_cache';
    DECLARE v_params_body            LONGTEXT DEFAULT '';
    DECLARE v_returnCode             INT;
    DECLARE v_returnMsg              LONGTEXT;
    DECLARE v_cur_timestamp          BIGINT(20) UNSIGNED DEFAULT FLOOR(UNIX_TIMESTAMP(CURRENT_TIMESTAMP(6))*1000000);
    DECLARE v_acutal_min_nonce       BIGINT(20);
    DECLARE v_acutal_max_nonce       BIGINT(20);
    DECLARE v_transactionCache       LONGTEXT;
    DECLARE v_stateObjectCache       LONGTEXT;
    DECLARE v_newaddStateObject      LONGTEXT;
    
	DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        ROLLBACK;
        TRUNCATE TABLE tx_cache.temp_cdg_transactions;
        TRUNCATE TABLE tx_cache.temp_cdg_nonce;
        DROP TABLE IF EXISTS tx_cache.temp_cdg_transactions;
        DROP TABLE IF EXISTS tx_cache.temp_cdg_nonce;
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, '-', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
    END;

    SET v_params_body = CONCAT('{"accountAddress_i":"',IFNULL(accountAddress_i,''),'","current_user_nonce_i":"',IFNULL(current_user_nonce_i,''),'","time_diff_i":"',IFNULL(time_diff_i,''),'"}');
    SET returnCode_o = 400;
    SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error');
    SET accountAddress_i = TRIM(accountAddress_i);
    #SET current_user_nonce_i = IF(current_user_nonce_i IS NULL,0,current_user_nonce_i);
    #SET time_diff_i = IF(time_diff_i IS NULL,0,time_diff_i);

    SET returnMsg_o = 'check input null data';
    IF IFNULL(accountAddress_i,'') = '' OR current_user_nonce_i IS NULL OR time_diff_i IS NULL THEN
        SET returnCode_o = 511;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'fail to create temp tables';
    CREATE TEMPORARY TABLE IF NOT EXISTS tx_cache.temp_cdg_transactions (
      `address`                   VARCHAR(256) NOT NULL,
      `initiator`                 VARCHAR(256) NOT NULL,
      `nonceForCurrentInitiator`  BIGINT(20) NOT NULL,
      `nonceForOriginInitiator`   BIGINT(20) NOT NULL,
      `nonceForSmartContract`     BIGINT(20) DEFAULT NULL,
      `receiver`                  VARCHAR(256) NOT NULL,
      `txType`                    VARCHAR(32) NOT NULL,
      `detail`                    LONGTEXT NOT NULL,
      `gasCost`                   FLOAT NOT NULL,
      `gasDeposit`                FLOAT NOT NULL,
      `hashSign`                  VARCHAR(256) NOT NULL,
      `receiptAddress`            VARCHAR(256) NOT NULL,
      `request_timestamp`         DATETIME NOT NULL,
      `createTime`                DATETIME NOT NULL,
      `last_update_time`          DATETIME NOT NULL,
      `status`                    TINYINT(4) NOT NULL DEFAULT 0 COMMENT '0:waiting match; 1:matched; 2:logstic confirmed; 3:closed',
      KEY `idx_nonce`             (`nonceForCurrentInitiator`)
    ) ENGINE=InnoDB;
    TRUNCATE TABLE tx_cache.temp_cdg_transactions;

    CREATE TEMPORARY TABLE IF NOT EXISTS tx_cache.temp_cdg_nonce (
      `nonce`           INT(11),
      KEY `idx_nonce`   (nonce)
    ) ENGINE=InnoDB;
    TRUNCATE TABLE tx_cache.temp_cdg_nonce;
    
    START TRANSACTION;
    SET SESSION innodb_lock_wait_timeout = 30;
    
    SET returnMsg_o = 'fail to insert data into temp tables';
    INSERT INTO tx_cache.temp_cdg_transactions(address, initiator, nonceForCurrentInitiator, nonceForOriginInitiator, nonceForSmartContract, receiver, txType, detail, gasCost, gasDeposit, hashSign, receiptAddress, request_timestamp, createTime, last_update_time, status)
    SELECT address, initiator, nonceForCurrentInitiator, nonceForOriginInitiator, nonceForSmartContract, receiver, txType, detail, gasCost, gasDeposit, hashSign, receiptAddress, request_timestamp, createTime, last_update_time, status
      FROM tx_cache.transactions 
     WHERE initiator=accountAddress_i
       AND delete_flag = 0
       AND status = 0
       AND (v_cur_timestamp - createTime)/1000000/60 >= time_diff_i;
    INSERT INTO tx_cache.temp_cdg_nonce(nonce) SELECT nonceForCurrentInitiator FROM tx_cache.temp_cdg_transactions;
    
    SET returnMsg_o = 'fail to check nonce continuity with current_user_nonce';
    SELECT MIN(nonce),MAX(nonce) INTO v_acutal_min_nonce,v_acutal_max_nonce FROM tx_cache.temp_cdg_nonce;
    IF (current_user_nonce_i+1) <> v_acutal_min_nonce AND current_user_nonce_i <> v_acutal_max_nonce THEN
        COMMIT;
        TRUNCATE TABLE tx_cache.temp_cdg_transactions;
        TRUNCATE TABLE tx_cache.temp_cdg_nonce;
        DROP TABLE IF EXISTS tx_cache.temp_cdg_transactions;
        DROP TABLE IF EXISTS tx_cache.temp_cdg_nonce;
        SET returnCode_o = 512;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'fail to check internal nonce continuity';
    SELECT COUNT(1)
      INTO v_cnt
      FROM tx_cache.temp_cdg_transactions a
      LEFT JOIN tx_cache.temp_cdg_nonce b ON a.nonceForCurrentInitiator = b.nonce-1
     WHERE b.nonce IS NULL;
    IF v_cnt > 1 THEN
        COMMIT;
        TRUNCATE TABLE tx_cache.temp_cdg_transactions;
        TRUNCATE TABLE tx_cache.temp_cdg_nonce;
        DROP TABLE IF EXISTS tx_cache.temp_cdg_transactions;
        DROP TABLE IF EXISTS tx_cache.temp_cdg_nonce;
        SET returnCode_o = 513;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'fail to return transaction datas';
    SELECT GROUP_CONCAT('("',address,'","',
                        initiator, '",',
                        nonceForCurrentInitiator, ',',
                        nonceForOriginInitiator, ',',
                        IF(nonceForSmartContract IS NULL ,'NULL',nonceForSmartContract), ',"',
                        receiver, '","',
                        txType, '","',
                        REPLACE(detail,'"',''''), '",',
                        gasCost,',',
                        gasDeposit,',"',
                        hashSign,'","',
                        receiptAddress,'","',
                        request_timestamp,'","',
                        createTime,'","',
                        last_update_time,'",',
                        `status`,')')
      INTO v_transactionCache
      FROM tx_cache.temp_cdg_transactions
     WHERE nonceForCurrentInitiator > current_user_nonce_i;
    
    SET returnMsg_o = 'fail to return cache state_object datas';
    SELECT GROUP_CONCAT('("',accountAddress,'","',
                             publicKey, '",',
                             creditRating, ',',
                             balance, ',', 
                             IF(smartContractPrice IS NULL,'NULL',smartContractPrice), ',',
                             IF(minSmartContractDeposit IS NULL,'NULL',minSmartContractDeposit), ',',
                             nonce ,')'),
           GROUP_CONCAT('"',accountAddress,'"')                
      INTO v_stateObjectCache,v_newaddStateObject                     
      FROM tx_cache.state_object 
     WHERE delete_flag = 0;

    SELECT REPLACE(to_base64(IFNULL(v_transactionCache,'')),'\n','') AS transactionCache,
           REPLACE(to_base64(IFNULL(v_stateObjectCache,'')),'\n','') AS stateObjectCache,
           REPLACE(to_base64(IFNULL(v_newaddStateObject,'')),'\n','') AS newaddStateObject;
    
    SET returnMsg_o = 'fail to update keystore nonce';
    UPDATE keystore.accounts SET current_packing_nonce = IFNULL(v_acutal_max_nonce,current_packing_nonce) WHERE accountAddress = accountAddress_i;
    
    COMMIT;
    
    TRUNCATE TABLE tx_cache.temp_cdg_transactions;
    TRUNCATE TABLE tx_cache.temp_cdg_nonce;
    DROP TABLE IF EXISTS tx_cache.temp_cdg_transactions;
    DROP TABLE IF EXISTS tx_cache.temp_cdg_nonce;
    
    SET returnCode_o = 200;
	SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
END
$$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;