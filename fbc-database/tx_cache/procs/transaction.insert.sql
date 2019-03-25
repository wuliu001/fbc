USE `tx_cache`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `transaction.insert` */;

DROP PROCEDURE IF EXISTS `transaction.insert`;

DELIMITER $$
CREATE PROCEDURE `transaction.insert`( 
    account_addr_i              VARCHAR(256),
    type_i                      VARCHAR(32), 
    hashsign_i                  VARCHAR(256),
    gascost_i                   FLOAT,
    gasdeposit_i                FLOAT,
    receiver_i                  VARCHAR(256),
    original_nonce_i            TINYINT(4),
    current_nonce_i             TINYINT(4),
    is_broadcast_i              TINYINT(4),
    old_txAddress_i             VARCHAR(256),
    body_i                      LONGTEXT,
    OUT returnCode_o            INT,
    OUT returnMsg_o             LONGTEXT)
ll:BEGIN
    DECLARE v_procname          VARCHAR(64) DEFAULT 'transaction.insert';
    DECLARE v_modulename        VARCHAR(50) DEFAULT 'tx_cache';
    DECLARE v_timestamp         BIGINT(20);
    DECLARE v_cnt               INT;
    DECLARE v_newtxAddress      VARCHAR(256);
    DECLARE v_params_body       LONGTEXT DEFAULT NULL;
    DECLARE v_returnCode        INT DEFAULT 0;
    DECLARE v_returnMsg         LONGTEXT DEFAULT '';
    
    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
      
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
    END;
    
    SET returnCode_o = 400;
    SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error');
    SET v_params_body = CONCAT('{"account_addr_i":"',IFNULL(account_addr_i,''),'","type_i":"',IFNULL(type_i,''),'","hashsign_i":"',IFNULL(hashsign_i,'')
                                 ,'","gascost_i":"',IFNULL(gascost_i,''),'","gasdeposit_i":"',IFNULL(gasdeposit_i,''),'","receiver_i":"',IFNULL(receiver_i,''),'","original_nonce_i":"',IFNULL(original_nonce_i,'')
                                 ,'","current_nonce_i":"',IFNULL(current_nonce_i,''),'","is_broadcast_i":"',IFNULL(is_broadcast_i,''),'","old_txAddress_i":"',IFNULL(old_txAddress_i,''),'"}');

    SET account_addr_i = TRIM(account_addr_i);
    SET type_i = TRIM(type_i);
    SET hashsign_i = TRIM(hashsign_i);
    SET receiver_i = TRIM(receiver_i);
    SET old_txAddress_i = TRIM(old_txAddress_i);
    SET body_i = TRIM(body_i);

    # check input parameter
    # check account_addr_i parameter
    IF IFNULL(account_addr_i,'') = '' THEN
        SET returnCode_o = 600;
        SET returnMsg_o = 'check account_addr fail.';
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    # check type_i parameter
    IF IFNULL(type_i,'') = '' THEN
        SET returnCode_o = 600;
        SET returnMsg_o = 'check type fail.';
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    # check hashsign_i parameter
    IF IFNULL(hashsign_i,'') = '' THEN
        SET returnCode_o = 600;
        SET returnMsg_o = 'check hashsign fail.';
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    # check receiver_i parameter
    IF IFNULL(receiver_i,'') = '' THEN
        SET returnCode_o = 600;
        SET returnMsg_o = 'check receiver fail.';
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    # check body_i parameter
    IF IFNULL(body_i,'') = '' OR JSON_VALID(body_i) = 0 THEN
        SET returnCode_o = 600;
        SET returnMsg_o = 'check body fail.';
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    # check nonce parameter
    IF IFNULL(old_txAddress_i,'') = '' AND current_nonce_i = 0 THEN
        SET returnCode_o = 600;
        SET returnMsg_o = 'check nonce fail.';
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    # extract request_timestemp from body
    SET v_timestamp = TRIM(BOTH '"' FROM body_i->"$.request_timestemp");
    IF v_timestamp IS NULL THEN   
        SET returnCode_o = 651;
        SET returnMsg_o = 'check request_timestemp in body fail.';
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET v_newtxAddress = md5(hashsign_i);
    IF old_txAddress_i <> '' THEN
        # update data in transactions table
        SELECT COUNT(1) 
          INTO v_cnt 
          FROM tx_cache.transactions
         WHERE address = old_txAddress_i
           AND initiator = account_addr_i
           AND txType = type_i;

        IF v_cnt = 0 THEN
            SET returnCode_o = 651;
            SET returnMsg_o = 'No record exist.';
            CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
            LEAVE ll;
        END IF;

        UPDATE tx_cache.transactions
           SET address = v_newtxAddress,
               detail = body_i,
               hashSign = hashsign_i,
               `timestamp` = v_timestamp
         WHERE address = old_txAddress_i
           AND initiator = account_addr_i
           AND txType = type_i;
    ELSE
        # insert data into transactions table
        INSERT INTO tx_cache.transactions (address,initiator,nonceForCurrentInitiator,nonceForOriginInitiator,receiver,txType,detail,gasCost,gasDeposit,hashSign,receiptAddress,`timestamp`)
             VALUES (v_newtxAddress,account_addr_i,current_nonce_i,original_nonce_i,receiver_i,type_i,body_i,gascost_i,gascost_i,hashsign_i,'',v_timestamp);
    END IF;

    SELECT v_newtxAddress AS txAddress;  

    SET returnCode_o = 200;
    SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
    
END $$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;