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

    SET v_params_body = CONCAT('{"accountAddress_i":"',IFNULL(accountAddress_i,''),'"current_user_nonce_i":"',IFNULL(current_user_nonce_i,''),'"time_diff_i":"',IFNULL(time_diff_i,''),'"}');
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
      `txAddress`       VARCHAR(256) NOT NULL,
      `accountAddress`  VARCHAR(256) NOT NULL,
      `transactionType` VARCHAR(32) NOT NULL,
      `blockObject`     LONGTEXT NOT NULL,
      `hashSign`        VARCHAR(256) NOT NULL,
      `gasCost`         FLOAT NOT NULL,
      `gasDeposit`      FLOAT NOT NULL,
      `nonce`           INT(11),
      `timestamp`       BIGINT(20) NOT NULL,
      `comfirmedTimes`  INT NOT NULL DEFAULT 0,
      KEY `idx_nonce`   (nonce)
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
    INSERT INTO tx_cache.temp_cdg_transactions(txAddress, accountAddress, transactionType, blockObject, hashSign, gasCost, gasDeposit, nonce, `timestamp`, comfirmedTimes)
    SELECT txAddress, accountAddress, transactionType, blockObject, hashSign, gasCost, gasDeposit, nonce, `timestamp`, comfirmedTimes 
      FROM tx_cache.transactions 
     WHERE accountAddress=accountAddress_i
       AND delete_flag = 0
       AND (v_cur_timestamp - `timestamp`)/1000000/60 >= time_diff_i;
    INSERT INTO tx_cache.temp_cdg_nonce(nonce) SELECT nonce FROM tx_cache.temp_cdg_transactions;
    
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
      LEFT JOIN tx_cache.temp_cdg_nonce b ON a.nonce = b.nonce-1
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
    SELECT txAddress, accountAddress, transactionType, blockObject, hashSign, gasCost, gasDeposit, nonce, `timestamp`, comfirmedTimes
      FROM tx_cache.temp_cdg_transactions
     WHERE nonce > current_user_nonce_i;
    
    SET returnMsg_o = 'fail to return cache state_object datas';
    SELECT accountAddress, publicKey, creditRating, balance, smartContractPrice, minSmartContractDeposit, nonce 
      FROM tx_cache.state_object 
     WHERE delete_flag = 0
     UNION 
    SELECT accountAddress, '' AS publicKey, NULl AS creditRating, NULL AS balance, NULL AS smartContractPrice,NULL AS minSmartContractDeposit, nonce
      FROM tx_cache.temp_cdg_transactions
     WHERE nonce > current_user_nonce_i;
      
    SET returnMsg_o = 'fail to update keystore nonce';
    UPDATE keystore.accounts SET current_packing_nonce = IFNULL(v_acutal_max_nonce,0) WHERE accountAddress = accountAddress_i;
    
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