USE `blockchain`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `blockchain.insert` */;

DROP PROCEDURE IF EXISTS `blockchain.insert`;

DELIMITER $$
USE `blockchain`$$
CREATE PROCEDURE `blockchain.insert`( 
    body_i                      LONGTEXT,
    OUT returnCode_o            INT,
    OUT returnMsg_o             LONGTEXT
    )
ll:BEGIN
    DECLARE v_procname                      VARCHAR(64) DEFAULT 'blockchain.insert';
    DECLARE v_modulename                    VARCHAR(50) DEFAULT 'blockchainCache';
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
    DECLARE v_txAddress_id                  VARCHAR(256);
    
    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        ROLLBACK;
        TRUNCATE TABLE blockchain.temp_transactions;
        DROP TABLE IF EXISTS blockchain.temp_transactions;      
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
    END;
    
    SET returnCode_o = 400;
    SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error');
    SET v_params_body = CONCAT('{}');
    SET body_i = TRIM(body_i);
    
    SET returnMsg_o = 'check input nnull data';
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
    SELECT TRIM(BOTH '"' FROM body_i->"$.blockCacheBody"),
           TRIM(BOTH '"' FROM body_i->"$.blockCacheAddress"),
           TRIM(BOTH '"' FROM body_i->"$.blockCacheHeader"),
           TRIM(BOTH '"' FROM body_i->"$.blockCacheReceipt"),
           TRIM(BOTH '"' FROM body_i->"$.blockCacheReceiptTrie"),
           TRIM(BOTH '"' FROM body_i->"$.blockCacheStateObject"),
           TRIM(BOTH '"' FROM body_i->"$.blockCacheStateTrie"),
           TRIM(BOTH '"' FROM body_i->"$.blockCacheTransaction"),
           TRIM(BOTH '"' FROM body_i->"$.blockCacheTransactionTrie")
	  INTO v_blockCacheBody,
           v_blockCacheAddress,
           v_blockCacheHeader,
           v_blockCacheReceipt,
           v_blockCacheReceiptTrie,
           v_blockCacheStateObject,
           v_blockCacheStateTrie,
           v_blockCacheTransaction,
           v_blockCacheTransactionTrie;
    
    CREATE TEMPORARY TABLE IF NOT EXISTS blockchain.temp_transactions LIKE transactions.transactions;
    TRUNCATE TABLE blockchain.temp_transactions;

    START TRANSACTION;
    SET SESSION innodb_lock_wait_timeout = 30;
    
    SET returnMsg_o = 'fail to insert into body data';
    IF IFNULL(v_blockCacheBody,'') <> '' THEN
        SET v_sql = CONCAT('INSERT INTO blockchain.body (header, hash) 
                            VALUES ',from_base64(v_blockCacheBody) ,'
                                ON DUPLICATE KEY UPDATE hash = hash');
        CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);                
    END IF;
    
    SET returnMsg_o = 'fail to insert into body_tx_address data';
    IF IFNULL(v_blockCacheAddress,'') <> '' THEN
        SET v_sql = CONCAT('INSERT INTO blockchain.body_tx_address (id, hash, tx_address) 
                            VALUES ',from_base64(v_blockCacheAddress) ,'
                                ON DUPLICATE KEY UPDATE hash = hash');
        CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);                
    END IF;
    
    SET returnMsg_o = 'fail to insert into header data';
    IF IFNULL(v_blockCacheHeader,'') <> '' THEN
        SET v_sql = CONCAT('INSERT INTO blockchain.header (parentHash,hash, stateRoot, txRoot, receiptRoot, bloom, time, nonce) 
                            VALUES ',from_base64(v_blockCacheHeader) ,'
                                ON DUPLICATE KEY UPDATE parentHash = parentHash');
        CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);                
    END IF;
                                                                        
    SET returnMsg_o = 'fail to insert into receipt data';
    IF IFNULL(v_blockCacheReceipt,'') <> '' THEN
        SET v_sql = CONCAT('INSERT INTO receipt.receipt (address, accountAddress, txAddress, gasCost, creditRating) 
                            VALUES ',from_base64(v_blockCacheReceipt) ,'
                                ON DUPLICATE KEY UPDATE accountAddress = accountAddress');
        CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);                
    END IF;
                                                                      
    SET returnMsg_o = 'fail to insert into receipt_trie data';
    IF IFNULL(v_blockCacheReceiptTrie,'') <> '' THEN
        SET v_sql = CONCAT('INSERT INTO receipt.receipt_trie ( id, parentHash, hash, alias, layer, address) 
                            VALUES ',from_base64(v_blockCacheReceiptTrie) ,'
                                ON DUPLICATE KEY UPDATE parentHash = parentHash');
        CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);                
    END IF;
    
    SET returnMsg_o = 'fail to insert into state_object data';
    IF IFNULL(v_blockCacheStateObject,'') <> '' THEN
        SET v_sql = CONCAT('INSERT INTO statedb.state_object (accountAddress, publicKey, creditRating, balance, smartContractPrice, minSmartContractDeposit, nonce) 
                            VALUES ',from_base64(v_blockCacheStateObject) ,'
                                ON DUPLICATE KEY UPDATE publicKey = publicKey');
        CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);                
    END IF;
                                   
    SET returnMsg_o = 'fail to insert into state_trie data';
    IF IFNULL(v_blockCacheStateTrie,'') <> '' THEN
        SET v_sql = CONCAT('INSERT INTO statedb.state_trie (id, parentHash, hash, alias, layer, address) 
                            VALUES ',from_base64(v_blockCacheStateTrie) ,'
                                ON DUPLICATE KEY UPDATE parentHash = parentHash');
        CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);                
    END IF;
    
    SET returnMsg_o = 'fail to insert into transactions data';
    IF IFNULL(v_blockCacheTransaction,'') <> '' THEN
        SET v_sql = CONCAT('INSERT INTO blockchain.temp_transactions (address, initiator, nonceForCurrentInitiator, nonceForOriginInitiator, nonceForSmartContract, receiver, txType, detail, gasCost, gasDeposit, hashSign, receiptAddress, request_timestamp, createTime, last_update_time) 
                            VALUES ',from_base64(v_blockCacheTransaction));
        CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);
        
        UPDATE blockchain.temp_transactions SET detail = REPLACE(detail,'''','"');

        INSERT INTO transactions.transactions (address, initiator, nonceForCurrentInitiator, nonceForOriginInitiator, nonceForSmartContract, receiver, txType, detail, gasCost, gasDeposit, hashSign, receiptAddress, request_timestamp, createTime, last_update_time)
             SELECT a.address,a.initiator,a.nonceForCurrentInitiator,a.nonceForOriginInitiator,a.nonceForSmartContract,a.receiver,a.txType,
                    a.detail,a.gasCost,a.gasDeposit,a.hashSign,a.receiptAddress,a.request_timestamp,a.createTime,a.last_update_time
               FROM blockchain.temp_transactions a
                 ON DUPLICATE KEY UPDATE last_update_time = a.last_update_time;

        INSERT INTO contract_match.transactions (address, initiator, nonceForCurrentInitiator, nonceForOriginInitiator, nonceForSmartContract, receiver, txType, variety, placeOfProduction, dateOfMature, dateOfProduction, appearanceRating, sizeRating, sweetnessRating, minQuantity, maxQuantity, price, countryOfLocation, provinceOfLocation, cityOfLocation, zoneOfLocation, addressOfLocation, request_begin_time, request_end_time, gasCost, gasDeposit, request_timestamp, createTime, last_update_time) 
             SELECT a.address, 
                    a.initiator, 
					a.nonceForCurrentInitiator,
                    a.nonceForOriginInitiator,
                    a.nonceForSmartContract,
                    a.receiver,
                    a.txType,
                    IFNULL(TRIM(BOTH '"' FROM a.detail->"$.Varieties"),''),
                    IFNULL(TRIM(BOTH '"' FROM a.detail->"$.placeOfProduction"),''),
                    IFNULL(TRIM(BOTH '"' FROM a.detail->"$.dateOfMature"),''),
                    IFNULL(TRIM(BOTH '"' FROM a.detail->"$.dateOfProduction"),''),
                    IFNULL(TRIM(BOTH '"' FROM a.detail->"$.appearanceRating"),''),
                    IFNULL(TRIM(BOTH '"' FROM a.detail->"$.sizeRating"),''),
                    IFNULL(TRIM(BOTH '"' FROM a.detail->"$.sweetnessRating"),''),
                    IFNULL(TRIM(BOTH '"' FROM a.detail->"$.minQuantity"),''),
                    IFNULL(TRIM(BOTH '"' FROM a.detail->"$.maxQuantity"),''),
                    IFNULL(TRIM(BOTH '"' FROM a.detail->"$.Price"),''),
					CASE WHEN a.txType = 'purchase' THEN IFNULL(TRIM(BOTH '"' FROM a.detail->"$.countryOfDeliveryLocation"),'')
                         ELSE IFNULL(TRIM(BOTH '"' FROM a.detail->"$.countryOfIssuingLocation"),'') END,
                    CASE WHEN a.txType = 'purchase' THEN IFNULL(TRIM(BOTH '"' FROM a.detail->"$.provinceOfDeliveryLocation"),'')
                         ELSE IFNULL(TRIM(BOTH '"' FROM a.detail->"$.provinceOfIssuingLocation"),'') END,
                    CASE WHEN a.txType = 'purchase' THEN IFNULL(TRIM(BOTH '"' FROM a.detail->"$.cityOfDeliveryLocation"),'')
                         ELSE IFNULL(TRIM(BOTH '"' FROM a.detail->"$.cityOfIssuingLocation"),'') END,
                    CASE WHEN a.txType = 'purchase' THEN IFNULL(TRIM(BOTH '"' FROM a.detail->"$.zoneOfDeliveryLocation"),'')
                         ELSE IFNULL(TRIM(BOTH '"' FROM a.detail->"$.zoneOfIssuingLocation"),'') END,
                    CASE WHEN a.txType = 'purchase' THEN IFNULL(TRIM(BOTH '"' FROM a.detail->"$.addressOfDeliveryLocation"),'')
                         ELSE IFNULL(TRIM(BOTH '"' FROM a.detail->"$.addressOfIssuingLocation"),'') END,
                    IFNULL(TRIM(BOTH '"' FROM a.detail->"$.dateOfReqBegin"),''),
                    IFNULL(TRIM(BOTH '"' FROM a.detail->"$.dateOfReqEnd"),''),
                    a.gasCost,
                    a.gasDeposit,
                    a.request_timestamp,
                    a.createTime,
                    a.last_update_time
               FROM blockchain.temp_transactions a
                 ON DUPLICATE KEY UPDATE last_update_time = a.last_update_time;
    END IF;

    SET returnMsg_o = 'fail to insert into transaction_trie data';
    IF IFNULL(v_blockCacheTransactionTrie,'') <> '' THEN
        SET v_sql = CONCAT('INSERT INTO transactions.transaction_trie (id, parentHash, hash, alias, layer, address) 
                            VALUES ',from_base64(v_blockCacheTransactionTrie) ,'
                                ON DUPLICATE KEY UPDATE address = address');
        CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);       
    END IF;
    
    COMMIT;

    TRUNCATE TABLE blockchain.temp_transactions;
    DROP TABLE IF EXISTS blockchain.temp_transactions;
    SET returnCode_o = 200;
    SET returnMsg_o = 'OK';

    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
    
END $$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;