USE `blockchain_cache`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `cacheBlock.insert` */;

DROP PROCEDURE IF EXISTS `cacheBlock.insert`;

DELIMITER $$
USE `blockchain_cache`$$
CREATE PROCEDURE `cacheBlock.insert`( 
    body_i                      LONGTEXT,
    OUT returnCode_o            INT,
    OUT returnMsg_o             LONGTEXT
    )
ll:BEGIN
    DECLARE v_procname          VARCHAR(64) DEFAULT 'cacheBlock.insert';
    DECLARE v_modulename        VARCHAR(50) DEFAULT 'blockchainCache';
    DECLARE v_params_body       LONGTEXT DEFAULT '{}';
    DECLARE v_returnCode        INT DEFAULT 0;
    DECLARE v_returnMsg         LONGTEXT DEFAULT '';
    DECLARE v_state_object      LONGTEXT;
    DECLARE v_transactions      LONGTEXT;
    DECLARE v_sql               LONGTEXT;
    DECLARE v_curr_block_nonce  INT;
    DECLARE v_new_block_nonce   INT;
    DECLARE v_pre_stateRoot     VARCHAR(256);
    DECLARE v_pre_txRoot        VARCHAR(256);
    DECLARE v_pre_receiptRoot   VARCHAR(256);
    DECLARE v_header_parenthash VARCHAR(256);
    
    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        COMMIT;
        TRUNCATE TABLE blockchain_cache.temp_cbi_state_object;
        TRUNCATE TABLE blockchain_cache.temp_cbi_transactions;
        DROP TABLE IF EXISTS blockchain_cache.temp_cbi_state_object; 
        DROP TABLE IF EXISTS blockchain_cache.temp_cbi_transactions;
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
    END;
    
    SET returnCode_o = 400;
    SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error');

    IF IFNULL(body_i,'') = '' THEN
        SET returnCode_o = 511;
        SET returnMsg_o = 'check input body null data error';
        CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    IF IFNULL(json_valid(body_i),0) = 0 THEN
        SET returnCode_o = 512;
        SET returnMsg_o = 'check input body json invalid';
        CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    SET returnMsg_o = 'create temp_cbi_state_object table.';
    CREATE TEMPORARY TABLE IF NOT EXISTS blockchain_cache.temp_cbi_state_object (
      `accountAddress`          VARCHAR(256) NOT NULL,
      `publicKey`               TEXT NOT NULL,
      `creditRating`            FLOAT NOT NULL,
      `balance`                 FLOAT NOT NULL,
      `smartContractPrice`      FLOAT DEFAULT NULL,
      `minSmartContractDeposit` FLOAT DEFAULT NULL,
      `nonce`                   INT(11) NOT NULL,
      KEY `key_cbi_addr`        (`accountAddress`)
    ) ENGINE=InnoDB;
    TRUNCATE TABLE blockchain_cache.temp_cbi_state_object;

    SET returnMsg_o = 'create temp_cbi_transactions table.';
    CREATE TEMPORARY TABLE IF NOT EXISTS blockchain_cache.temp_cbi_transactions (
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
      `timestamp`                 BIGINT(20) NOT NULL,
      KEY `key_cbi_addr`          (`address`)
    ) ENGINE=InnoDB;
    TRUNCATE TABLE blockchain_cache.temp_cbi_transactions;

    SET returnMsg_o = 'extract state_object & transactions info from body.';
    SET v_state_object = IFNULL(TRIM(BOTH '"' FROM body_i->"$.stateObjectPackingCache"),'');
	  SET v_transactions = IFNULL(TRIM(BOTH '"' FROM body_i->"$.transactionPackingCache"),'');

    IF v_transactions = '' AND v_state_object = '' THEN
        SET returnCode_o = 200;
        SET returnMsg_o = 'OK';
        TRUNCATE TABLE blockchain_cache.temp_cbi_state_object;
        TRUNCATE TABLE blockchain_cache.temp_cbi_transactions;
        DROP TABLE IF EXISTS blockchain_cache.temp_cbi_state_object; 
        DROP TABLE IF EXISTS blockchain_cache.temp_cbi_transactions;
        CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    START TRANSACTION;
    SET SESSION innodb_lock_wait_timeout = 30;

    SELECT IFNULL(MAX(nonce),0) INTO v_curr_block_nonce FROM blockchain.header;
    SET v_new_block_nonce = v_curr_block_nonce + 1;
    SELECT IFNULL(hash,'') INTO v_header_parenthash FROM blockchain.header WHERE nonce = v_curr_block_nonce;
    SELECT IFNULL(stateRoot,'') INTO v_pre_stateRoot FROM blockchain.header WHERE nonce = v_curr_block_nonce;
    SELECT IFNULL(txRoot,'') INTO v_pre_txRoot FROM blockchain.header WHERE nonce = v_curr_block_nonce;
    SELECT IFNULL(receiptRoot,'') INTO v_pre_receiptRoot FROM blockchain.header WHERE nonce = v_curr_block_nonce;

    SET returnMsg_o = 'insert temp_cbi_state_object table.';
    IF v_state_object <> '' THEN
        SET v_sql = CONCAT('INSERT INTO blockchain_cache.temp_cbi_state_object VALUES ',v_state_object);
        CALL commons.dynamic_sql_execute(v_sql,v_returnCode,v_returnMsg);

        SET returnMsg_o = 'insert state_object data from temp_cbi_state_object table.';
        INSERT INTO blockchain_cache.state_object(accountAddress,publicKey,creditRating,balance,smartContractPrice,minSmartContractDeposit,nonce)
             SELECT accountAddress,
                    publicKey,
                    creditRating,
                    balance,
                    smartContractPrice,
                    minSmartContractDeposit,
                    nonce
               FROM blockchain_cache.temp_cbi_state_object;
    
        SET returnMsg_o = 'generate state_object trie info.';
        # example: accountAddress: 3a95cdadfbe8b62a18f333c38b515085
        # generate the 4th layer data in state_trie
        # alias: 3a95cdadfbe8b62a18f333c38b515085
        INSERT INTO blockchain_cache.state_trie(hash,alias,layer,address)
             SELECT MD5(accountAddress),accountAddress,4,accountAddress
               FROM blockchain_cache.state_object
              WHERE delete_flag = 0;

        # generate the 3rd layer data in state_trie
        # alias: 3a_95
        INSERT INTO blockchain_cache.state_trie(alias,layer)
             SELECT CONCAT(SUBSTR(SUBSTR(alias,1,4),1,2),'_',SUBSTR(SUBSTR(alias,1,4),3,2)),3
               FROM blockchain_cache.state_trie
              WHERE layer = 4
                AND delete_flag = 0
              GROUP BY SUBSTR(alias,1,4);

        # generate the 2nd layer data in state_trie
        # alias: 3a
        INSERT INTO blockchain_cache.state_trie(alias,layer)
             SELECT SUBSTR(alias,1,2),2
               FROM blockchain_cache.state_trie
              WHERE layer = 3
                AND delete_flag = 0
              GROUP BY SUBSTR(alias,1,2);

        # get 2nd layer data from statedb.state_trie
        INSERT INTO blockchain_cache.state_trie(hash,alias,layer)
             SELECT a.hash,a.alias,a.layer
               FROM statedb.state_trie a
              WHERE a.parentHash = v_pre_stateRoot
                AND a.layer = 2
                AND a.delete_flag = 0
                AND NOT EXISTS (SELECT 1 FROM blockchain_cache.state_trie b WHERE b.layer = 2 AND b.alias = a.alias AND b.delete_flag = 0);

        # get 3rd layer data from statedb.state_trie
        INSERT INTO blockchain_cache.state_trie(alias,layer)
             SELECT b.alias,b.layer
               FROM statedb.state_trie a,
                    statedb.state_trie b
              WHERE a.parentHash = v_pre_stateRoot
                AND a.layer = 2
                AND EXISTS (SELECT 1 FROM blockchain_cache.state_trie c WHERE c.layer = 2 AND c.alias = a.alias AND c.delete_flag = 0)
                AND b.parentHash = a.hash
                AND b.layer = 3
                AND NOT EXISTS (SELECT 1 FROM blockchain_cache.state_trie d WHERE d.layer = 3 AND d.alias = b.alias AND d.delete_flag = 0);

        # get 4th layer data from statedb.state_trie
        INSERT INTO blockchain_cache.state_trie(hash,alias,layer,address)
             SELECT c.hash,c.alias,c.layer,c.address
               FROM statedb.state_trie a,
                    statedb.state_trie b,
                    statedb.state_trie c
              WHERE a.parentHash = v_pre_stateRoot
                AND a.layer = 2
                AND EXISTS (SELECT 1 FROM blockchain_cache.state_trie d WHERE d.layer = 2 AND d.alias = a.alias AND d.delete_flag = 0)
                AND b.parentHash = a.hash
                AND b.layer = 3
                AND EXISTS (SELECT 1 FROM blockchain_cache.state_trie e WHERE e.layer = 3 AND e.alias = b.alias AND e.delete_flag = 0)
                AND c.parentHash = b.hash
                AND c.layer = 4
                AND NOT EXISTS (SELECT 1 FROM blockchain_cache.state_trie f WHERE f.layer = 4 AND f.alias = c.alias AND f.delete_flag = 0);

        # update the 3 layer hash value in blockchain_cache.state_trie
        UPDATE blockchain_cache.state_trie a,
               (SELECT CONCAT(SUBSTR(SUBSTR(alias,1,4),1,2),'_',SUBSTR(SUBSTR(alias,1,4),3,2)) AS pre_alias,
                       MD5(GROUP_CONCAT(hash)) AS hash
                  FROM blockchain_cache.state_trie
                 WHERE layer = 4
                   AND delete_flag = 0
                 GROUP BY SUBSTR(alias,1,4)) b
           SET a.hash = b.hash
         WHERE a.alias = b.pre_alias
           AND a.delete_flag = 0
           AND a.layer = 3;
    
        # update the 4 layer parentHash value in blockchain_cache.state_trie
        UPDATE blockchain_cache.state_trie a,
               blockchain_cache.state_trie b
           SET a.parentHash = b.hash
         WHERE a.layer = 4
           AND a.delete_flag = 0
           AND b.layer = 3
           AND b.delete_flag = 0
           AND RELACE(b.alias,'_','') = SUBSTR(a.alias,1,4);

        # update the 2 layer hash value in blockchain_cache.state_trie
        UPDATE blockchain_cache.state_trie a,
               (SELECT SUBSTR(alias,1,2) AS pre_alias,
                       MD5(GROUP_CONCAT(hash)) AS hash
                  FROM blockchain_cache.state_trie
                 WHERE layer = 3
                   AND delete_flag = 0
                 GROUP BY SUBSTR(alias,1,2)) b
           SET a.hash = b.hash
         WHERE a.alias = b.pre_alias
           AND a.delete_flag = 0
           AND a.layer = 2
           AND a.hash <> '';

        # update the 3 layer parentHash value in blockchain_cache.state_trie
        UPDATE blockchain_cache.state_trie a,
               blockchain_cache.state_trie b
           SET a.parentHash = b.hash
         WHERE a.layer = 3
           AND a.delete_flag = 0
           AND b.layer = 2
           AND b.delete_flag = 0
           AND b.alias = SUBSTR(a.alias,1,2);

        # generate stateRoot (1 layer) data
        INSERT INTO blockchain_cache.state_trie(hash,layer)
             SELECT MD5(GROUP_CONCAT(hash)),1
               FROM blockchain_cache.state_trie
              WHERE layer = 2
                AND delete_flag = 0;
    
        # update the 2 layer parentHash value in blockchain_cache.state_trie
        UPDATE blockchain_cache.state_trie a,
               blockchain_cache.state_trie b
           SET a.parentHash = b.hash
         WHERE a.layer = 2
           AND a.delete_flag = 0
           AND b.layer = 1
           AND b.delete_flag = 0;

        # generate header data
        INSERT INTO blockchain_cache.header(parentHash,stateRoot,nonce,time)
             SELECT v_header_parenthash,hash,v_new_block_nonce,UTC_TIMESTAMP()
               FROM blockchain_cache.state_trie
              WHERE layer = 1
                AND delete_flag = 0;
    ELSE
        # generate header data
        INSERT INTO blockchain_cache.header(parentHash,stateRoot,nonce,time)
             VALUES (v_header_parenthash,v_pre_stateRoot,v_new_block_nonce,UTC_TIMESTAMP());
    END IF;


    IF v_transactions <> '' THEN
        SET returnMsg_o = 'insert temp_cbi_transactions table.';
        SET v_sql = CONCAT('INSERT INTO blockchain_cache.temp_cbi_transactions VALUES ',v_transactions);
        CALL commons.dynamic_sql_execute(v_sql,v_returnCode,v_returnMsg);

        SET returnMsg_o = 'insert state_object data from temp_cbi_transactions table.';
        INSERT INTO blockchain_cache.state_object(accountAddress,publicKey,creditRating,balance,smartContractPrice,minSmartContractDeposit,nonce)
             SELECT a.accountAddress, 
                    a.publicKey,
                    a.creditRating,
                    a.balance,
                    a.smartContractPrice,
                    a.minSmartContractDeposit,
                    b.nonce
               FROM statedb.state_object a,
                    (SELECT initiator,
                            MAX(nonceForCurrentInitiator) nonce
                       FROM blockchain_cache.temp_cbi_transactions
                      GROUP BY initiator) b
               WHERE a.accountAddress = b.initiator;

        SET returnMsg_o = 'insert transactions data into blockchain_cache.transactions.';
        INSERT INTO blockchain_cache.transactions(address,initiator,nonceForCurrentInitiator,nonceForOriginInitiator,nonceForSmartContract,receiver,txType,detail,gasCost,gasDeposit,hashSign,receiptAddress,createTime,closeTime)
             SELECT address,
                    initiator,
                    nonceForCurrentInitiator,
                    nonceForOriginInitiator,
                    nonceForSmartContract,
                    receiver,
                    txType,
                    detail,
                    gasCost,
                    gasDeposit,
                    hashSign,
                    receiptAddress,
                    timestamp,
                    UTC_TIMESTAMP()
               FROM blockchain_cache.temp_cbi_transactions;

        SET returnMsg_o = 'generate transaction trie info.';
        # example: receiver accountAddress: 3a95cdadfbe8b62a18f333c38b515085, request_timestamp: 2017-03-19 07:06:49
        # generate the 7th layer data in state_trie
        # alias: 3a95cdadfbe8b62a18f333c38b515085
        INSERT INTO blockchain_cache.transaction_trie(hash,alias,layer,address)
             SELECT MD5(address),receiver,7,address
               FROM blockchain_cache.transactions
              WHERE delete_flag = 0;
        
        # generate the 6th layer data in state_trie
        # alias: 3b_78_3b78cdadfbe8b62a18f333c38b515085_201703_19
        INSERT INTO blockchain_cache.transaction_trie(alias,layer)
             SELECT CONCAT(SUBSTR(b.receiver,1,2),'_',SUBSTR(b.receiver,3,2),'_',b.receiver,'_',DATE_FORMAT(timestamp,'%Y%m_%d')),6
               FROM blockchain_cache.transaction_trie a,
                    blockchain_cache.transactions b
              WHERE a.layer = 7
                AND a.delete_flag = 0
                AND a.address = b.address
                AND b.delete_flag = 0
              GROUP BY b.receiver,b.timestamp;
        
        # generate the 5th layer data in state_trie
        # alias: 3b_78_3b78cdadfbe8b62a18f333c38b515085_201703
        INSERT INTO blockchain_cache.transaction_trie(alias,layer)
             SELECT SUBSTR(alias,1,LENGTH(alias)-3),5
               FROM blockchain_cache.transaction_trie
              WHERE layer = 6
                AND delete_flag = 0
              GROUP BY SUBSTR(alias,1,LENGTH(alias)-3);
        
        # generate the 4th layer data in state_trie
        # alias: 3b_78_3b78cdadfbe8b62a18f333c38b515085
        INSERT INTO blockchain_cache.transaction_trie(alias,layer)
             SELECT SUBSTR(alias,1,LENGTH(alias)-7),4
               FROM blockchain_cache.transaction_trie
              WHERE layer = 5
                AND delete_flag = 0
              GROUP BY SUBSTR(alias,1,LENGTH(alias)-7);

        # generate the 3th layer data in state_trie
        # alias: 3b_78
        INSERT INTO blockchain_cache.transaction_trie(alias,layer)
             SELECT SUBSTR(alias,1,5),3
               FROM blockchain_cache.transaction_trie
              WHERE layer = 4
                AND delete_flag = 0
              GROUP BY SUBSTR(alias,1,5);
        
        # generate the 2th layer data in state_trie
        # alias: 3b
        INSERT INTO blockchain_cache.transaction_trie(alias,layer)
             SELECT SUBSTR(alias,1,2),2
               FROM blockchain_cache.transaction_trie
              WHERE layer = 3
                AND delete_flag = 0
              GROUP BY SUBSTR(alias,1,2);
        
        # get 2nd layer data from transactions.transaction_trie
        INSERT INTO blockchain_cache.transaction_trie(hash,alias,layer)
             SELECT a.hash,a.alias,a.layer
               FROM transactions.transaction_trie a
              WHERE a.parentHash = v_pre_txRoot
                AND a.layer = 2
                AND NOT EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie b WHERE b.layer = 2 AND b.alias = a.alias AND b.delete_flag = 0);
        
        # get 3rd layer data from transactions.transaction_trie
        INSERT INTO blockchain_cache.transaction_trie(alias,layer)
             SELECT b.alias,b.layer
               FROM transactions.transaction_trie a,
                    transactions.transaction_trie b
              WHERE a.parentHash = v_pre_txRoot
                AND a.layer = 2
                AND EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie c WHERE c.layer = 2 AND c.alias = a.alias AND c.delete_flag = 0)
                AND b.parentHash = a.hash
                AND b.layer = 3
                AND NOT EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie d WHERE d.layer = 3 AND d.alias = b.alias AND d.delete_flag = 0);
        
        # get 4th layer data from transactions.transaction_trie
        INSERT INTO blockchain_cache.transaction_trie(hash,alias,layer,address)
             SELECT c.hash,c.alias,c.layer,c.address
               FROM transactions.transaction_trie a,
                    transactions.transaction_trie b,
                    transactions.transaction_trie c
              WHERE a.parentHash = v_pre_txRoot
                AND a.layer = 2
                AND EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie d WHERE d.layer = 2 AND d.alias = a.alias AND d.delete_flag = 0)
                AND b.parentHash = a.hash
                AND b.layer = 3
                AND EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie e WHERE e.layer = 3 AND e.alias = b.alias AND e.delete_flag = 0)
                AND c.parentHash = b.hash
                AND c.layer = 4
                AND NOT EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie f WHERE f.layer = 4 AND f.alias = c.alias AND f.delete_flag = 0);
        
        # get 5th layer data from transactions.transaction_trie
        INSERT INTO blockchain_cache.transaction_trie(hash,alias,layer,address)
             SELECT c.hash,c.alias,c.layer,c.address
               FROM transactions.transaction_trie a,
                    transactions.transaction_trie b,
                    transactions.transaction_trie c,
                    transactions.transaction_trie d
              WHERE a.parentHash = v_pre_txRoot
                AND a.layer = 2
                AND EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie e WHERE e.layer = 2 AND e.alias = a.alias AND e.delete_flag = 0)
                AND b.parentHash = a.hash
                AND b.layer = 3
                AND EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie f WHERE f.layer = 3 AND f.alias = b.alias AND f.delete_flag = 0)
                AND c.parentHash = b.hash
                AND c.layer = 4
                AND EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie g WHERE g.layer = 4 AND g.alias = c.alias AND g.delete_flag = 0)
                AND d.parentHash = c.hash
                AND d.layer = 5
                AND NOT EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie h WHERE h.layer = 5 AND h.alias = d.alias AND h.delete_flag = 0);

        # get 6th layer data from transactions.transaction_trie
        INSERT INTO blockchain_cache.transaction_trie(hash,alias,layer,address)
             SELECT c.hash,c.alias,c.layer,c.address
               FROM transactions.transaction_trie a,
                    transactions.transaction_trie b,
                    transactions.transaction_trie c,
                    transactions.transaction_trie d,
                    transactions.transaction_trie e
              WHERE a.parentHash = v_pre_txRoot
                AND a.layer = 2
                AND EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie f WHERE f.layer = 2 AND f.alias = a.alias AND f.delete_flag = 0)
                AND b.parentHash = a.hash
                AND b.layer = 3
                AND EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie g WHERE g.layer = 3 AND g.alias = b.alias AND g.delete_flag = 0)
                AND c.parentHash = b.hash
                AND c.layer = 4
                AND EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie h WHERE h.layer = 4 AND h.alias = c.alias AND h.delete_flag = 0)
                AND d.parentHash = c.hash
                AND d.layer = 5
                AND EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie i WHERE i.layer = 5 AND i.alias = d.alias AND i.delete_flag = 0)
                AND e.parentHash = d.hash
                AND e.layer = 6
                AND NOT EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie j WHERE j.layer = 6 AND j.alias = e.alias AND j.delete_flag = 0);

        # get 7th layer data from transactions.transaction_trie
        INSERT INTO blockchain_cache.transaction_trie(hash,alias,layer,address)
             SELECT c.hash,c.alias,c.layer,c.address
               FROM transactions.transaction_trie a,
                    transactions.transaction_trie b,
                    transactions.transaction_trie c,
                    transactions.transaction_trie d,
                    transactions.transaction_trie e,
                    transactions.transaction_trie f
              WHERE a.parentHash = v_pre_txRoot
                AND a.layer = 2
                AND EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie g WHERE g.layer = 2 AND g.alias = a.alias AND g.delete_flag = 0)
                AND b.parentHash = a.hash
                AND b.layer = 3
                AND EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie h WHERE h.layer = 3 AND h.alias = b.alias AND h.delete_flag = 0)
                AND c.parentHash = b.hash
                AND c.layer = 4
                AND EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie i WHERE i.layer = 4 AND i.alias = c.alias AND i.delete_flag = 0)
                AND d.parentHash = c.hash
                AND d.layer = 5
                AND EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie j WHERE j.layer = 5 AND j.alias = d.alias AND j.delete_flag = 0)
                AND e.parentHash = d.hash
                AND e.layer = 6
                AND EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie k WHERE k.layer = 6 AND k.alias = e.alias AND k.delete_flag = 0)
                AND f.parentHash = e.hash
                AND f.layer = 7
                AND NOT EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie l WHERE l.layer = 7 AND l.alias = f.alias AND l.delete_flag = 0);

        # update the 6 layer hash value in blockchain_cache.transaction_trie
        UPDATE blockchain_cache.transaction_trie a,
               (SELECT CONCAT(SUBSTR(c.receiver,1,2),'_',SUBSTR(c.receiver,3,2),'_',c.receiver,'_',DATE_FORMAT(timestamp,'%Y%m_%d')) AS pre_alias,
                       MD5(GROUP_CONCAT(b.hash)) AS hash
                  FROM blockchain_cache.transaction_trie b,
                       blockchain_cache.transactions c
                 WHERE b.layer = 7
                   AND b.delete_flag = 0
                   AND b.address = c.address
                   AND c.delete_flag = 0
                 GROUP BY c.receiver,c.timestamp) d
           SET a.hash = d.hash
         WHERE a.alias = d.pre_alias
           AND a.layer = 6
           AND a.delete_flag = 0;

        # update the 7 layer parentHash value in blockchain_cache.transaction_trie
        UPDATE blockchain_cache.transaction_trie a,
               blockchain_cache.transaction_trie b,
               (SELECT address,
                       CONCAT(SUBSTR(c.receiver,1,2),'_',SUBSTR(c.receiver,3,2),'_',c.receiver,'_',DATE_FORMAT(timestamp,'%Y%m_%d')) as pre_alias
                  FROM blockchain_cache.transactions c)
           SET a.parentHash = b.hash
         WHERE a.layer = 7
           AND a.delete_flag = 0
           AND b.layer = 6
           AND b.delete_flag = 0
           AND c.delete_flag = 0
           AND b.alias = ;



    END IF;

    SET returnMsg_o = 'update blockchain header data.';

    SET returnMsg_o = 'generate blockchain body data.';

    SET returnMsg_o = 'generate blockchain body_tx_address data.';

    COMMIT;

    TRUNCATE TABLE blockchain_cache.temp_cbi_state_object;
    TRUNCATE TABLE blockchain_cache.temp_cbi_transactions;
    DROP TABLE IF EXISTS blockchain_cache.temp_cbi_state_object; 
    DROP TABLE IF EXISTS blockchain_cache.temp_cbi_transactions;

    SET returnCode_o = 200;
    SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
    
END $$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;