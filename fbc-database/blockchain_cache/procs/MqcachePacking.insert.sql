USE `blockchain_cache`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `MqcachePacking.insert` */;

DROP PROCEDURE IF EXISTS `MqcachePacking.insert`;

DELIMITER $$
USE `blockchain_cache`$$
CREATE PROCEDURE `MqcachePacking.insert`( 
    body_i                      LONGTEXT,
    OUT returnCode_o            INT,
    OUT returnMsg_o             LONGTEXT
    )
ll:BEGIN
    DECLARE v_procname                      VARCHAR(64) DEFAULT 'MqcachePacking.insert';
    DECLARE v_modulename                    VARCHAR(50) DEFAULT 'blockchain_cacheCache';
    DECLARE v_user                          VARCHAR(50);
    DECLARE v_params_body                   LONGTEXT DEFAULT NULL;
    DECLARE v_returnCode                    INT DEFAULT 0;
    DECLARE v_returnMsg                     LONGTEXT DEFAULT '';
    DECLARE v_blockCacheBody                LONGTEXT DEFAULT NULL;
    DECLARE v_blockCacheAddress             LONGTEXT DEFAULT NULL;
    DECLARE v_blockCacheHeader              LONGTEXT DEFAULT NULL;
    DECLARE v_blockCacheReceipt             LONGTEXT DEFAULT NULL;
    DECLARE v_blockCacheReceiptTrie         LONGTEXT DEFAULT NULL;
    DECLARE v_blockCacheStateObject         LONGTEXT DEFAULT NULL;
    DECLARE v_blockCacheStateTrie           LONGTEXT DEFAULT NULL;
    DECLARE v_blockCacheTransaction         LONGTEXT DEFAULT NULL;
    DECLARE v_blockCacheTransactionTrie     LONGTEXT DEFAULT NULL;
    DECLARE v_sql                           LONGTEXT;
    
    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        ROLLBACK;      
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
    END;
    
    SET returnCode_o = 400;
    SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error');
    SET v_params_body = CONCAT('{}');
    SET body_i = TRIM(body_i);
    
    SET returnMsg_o = 'check input body null data';
    IF IFNULL(body_i,'') = '' THEN
        SET returnCode_o = 511;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'fail to parase body';
    SELECT commons.`Util.getField2`(body_i,':;',1),
           commons.`Util.getField2`(body_i,':;',2),
           commons.`Util.getField2`(body_i,':;',3),
           commons.`Util.getField2`(body_i,':;',4),
           commons.`Util.getField2`(body_i,':;',5),
           commons.`Util.getField2`(body_i,':;',6),
           commons.`Util.getField2`(body_i,':;',7),
           commons.`Util.getField2`(body_i,':;',8),
           commons.`Util.getField2`(body_i,':;',9)
	  INTO v_blockCacheBody,
           v_blockCacheAddress,
           v_blockCacheHeader,
           v_blockCacheReceipt,
           v_blockCacheReceiptTrie,
           v_blockCacheStateObject,
           v_blockCacheStateTrie,
           v_blockCacheTransaction,
           v_blockCacheTransactionTrie;
    
    START TRANSACTION;
    SET SESSION innodb_lock_wait_timeout = 30;
    
    SET returnMsg_o = 'fail to insert into body data';
    IF IFNULL(v_blockCacheBody,'') <> '' THEN
        SET v_sql = CONCAT('INSERT INTO blockchain_cache.body (header, hash) 
                            VALUES ',v_blockCacheBody ,'
                                ON DUPLICATE KEY UPDATE delete_flag = 0');
        CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);                
    END IF;
    
    SET returnMsg_o = 'fail to insert into body_tx_address data';
    IF IFNULL(v_blockCacheAddress,'') <> '' THEN
        SET v_sql = CONCAT('INSERT INTO blockchain_cache.body_tx_address (id, hash, tx_address) 
                            VALUES ',v_blockCacheAddress ,'
                                ON DUPLICATE KEY UPDATE delete_flag = 0');
        CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);                
    END IF;
    
    SET returnMsg_o = 'fail to insert into header data';
    IF IFNULL(v_blockCacheHeader,'') <> '' THEN
        SET v_sql = CONCAT('INSERT INTO blockchain_cache.header (parentHash,hash, stateRoot, txRoot, receiptRoot, bloom, time, nonce) 
                            VALUES ',v_blockCacheHeader ,'
                                ON DUPLICATE KEY UPDATE delete_flag = 0');
        CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);                
    END IF;
                                                                        
    SET returnMsg_o = 'fail to insert into receipt data';
    IF IFNULL(v_blockCacheReceipt,'') <> '' THEN
        SET v_sql = CONCAT('INSERT INTO blockchain_cache.receipt (address, accountAddress, txAddress, gasCost, creditRating) 
                            VALUES ',v_blockCacheReceipt ,'
                                ON DUPLICATE KEY UPDATE delete_flag = 0');
        CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);                
    END IF;
                                                                      
    SET returnMsg_o = 'fail to insert into receipt_trie data';
    IF IFNULL(v_blockCacheReceiptTrie,'') <> '' THEN
        SET v_sql = CONCAT('INSERT INTO blockchain_cache.receipt_trie ( id, parentHash, hash, alias, layer, address) 
                            VALUES ',v_blockCacheReceiptTrie ,'
                                ON DUPLICATE KEY UPDATE delete_flag = 0');
        CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);                
    END IF;
    
    SET returnMsg_o = 'fail to insert into state_object data';
    IF IFNULL(v_blockCacheStateObject,'') <> '' THEN
        SET v_sql = CONCAT('INSERT INTO blockchain_cache.state_object (accountAddress, publicKey, creditRating, balance, smartContractPrice, minSmartContractDeposit, nonce) 
                            VALUES ',v_blockCacheStateObject ,'
                                ON DUPLICATE KEY UPDATE delete_flag = 0');
        CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);                
    END IF;
                                   
    SET returnMsg_o = 'fail to insert into state_trie data';
    IF IFNULL(v_blockCacheStateTrie,'') <> '' THEN
        SET v_sql = CONCAT('INSERT INTO blockchain_cache.state_trie (id, parentHash, hash, alias, layer, address) 
                            VALUES ',v_blockCacheStateTrie ,'
                                ON DUPLICATE KEY UPDATE delete_flag = 0');
        CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);                
    END IF;
    
    SET returnMsg_o = 'fail to insert into transactions data';
    IF IFNULL(v_blockCacheTransaction,'') <> '' THEN
        SET v_sql = CONCAT('INSERT INTO blockchain_cache.transactions ( address, initiator, nonceForCurrentInitiator, nonceForOriginInitiator, nonceForSmartContract, receiver, txType, detail, gasCost, gasDeposit, hashSign, receiptAddress, createTime, closeTime) 
                            VALUES ',v_blockCacheTransaction ,'
                                ON DUPLICATE KEY UPDATE delete_flag = 0');
        CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);                
    END IF;
                                                                    
    SET returnMsg_o = 'fail to insert into transaction_trie data';
    IF IFNULL(v_blockCacheTransactionTrie,'') <> '' THEN
        SET v_sql = CONCAT('INSERT INTO blockchain_cache.transaction_trie (id, parentHash, hash, alias, layer, address) 
                            VALUES ',v_blockCacheTransactionTrie ,'
                                ON DUPLICATE KEY UPDATE delete_flag = 0');
        CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);       
    END IF;
    
    COMMIT;

    SET returnCode_o = 200;
    SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
    
END $$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;