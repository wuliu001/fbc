USE `tx_cache`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `cache_detail.insert` */;

DROP PROCEDURE IF EXISTS `cache_detail.insert`;

DELIMITER $$
CREATE PROCEDURE `cache_detail.insert`(
    body_i                   LONGTEXT,
    OUT returnCode_o         INT,
    OUT returnMsg_o          LONGTEXT)
ll:BEGIN
    DECLARE v_cnt            INT;
    DECLARE v_procname       VARCHAR(100) DEFAULT 'cache_detail.insert';
    DECLARE v_modulename     VARCHAR(50) DEFAULT 'tx_cache';
    DECLARE v_params_body    LONGTEXT DEFAULT '';
    DECLARE v_returnCode     INT;
    DECLARE v_returnMsg      LONGTEXT;
    DECLARE v_statecache     LONGTEXT;
    DECLARE v_trancache      LONGTEXT;
    DECLARE v_sql            LONGTEXT;
    
	DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        ROLLBACK;
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, '-', v_procname, ' execute Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
    END;

    SET v_params_body = CONCAT('{}');
    SET returnCode_o = 400;
    SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error');
    SET body_i = TRIM(body_i);

    SET returnMsg_o = 'check input null data';
    IF IFNULL(body_i,'') = '' THEN
        SET returnCode_o = 511;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'check input body json invalid';
    IF IFNULL(json_valid(body_i),0) = 0 THEN
        SET returnCode_o = 512;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'fail to parase body';
    SELECT TRIM(BOTH '"' FROM body_i->"$.stateObjectCache"),
           TRIM(BOTH '"' FROM body_i->"$.transactionCache")
	  INTO v_statecache,
           v_trancache;
    START TRANSACTION;
    SET SESSION innodb_lock_wait_timeout = 30;
    
    SET returnMsg_o = 'fail to insert into stateCache data';
    IF IFNULL(v_statecache,'') <> '' THEN
        SET v_sql = CONCAT('INSERT INTO tx_cache.state_object (accountAddress, publicKey, creditRating, balance, smartContractPrice, minSmartContractDeposit, nonce) 
                            VALUES ',v_statecache ,'
                                ON DUPLICATE KEY UPDATE nonce = nonce');
        CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);                
    END IF;                  
    
    SET returnMsg_o = 'fail to insert into txCache data';
    IF IFNULL(v_trancache,'') <> '' THEN
        SET v_sql = CONCAT('INSERT INTO tx_cache.transactions (address, initiator, nonceForCurrentInitiator, nonceForOriginInitiator, nonceForSmartContract, receiver, txType, detail, gasCost, gasDeposit, hashSign, receiptAddress, timestamp) 
                            VALUES ',v_trancache ,'
                                ON DUPLICATE KEY UPDATE nonceForCurrentInitiator = nonceForCurrentInitiator');
        CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);
    END IF;
    
    COMMIT;
    
    SET returnCode_o = 200;
	SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
END
$$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;