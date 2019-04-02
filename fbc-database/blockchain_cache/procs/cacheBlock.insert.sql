USE `blockchain_cache`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `cacheBlock.insert` */;

DROP PROCEDURE IF EXISTS `cacheBlock.insert`;

DELIMITER $$

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
    DECLARE v_all_trans_hash    VARCHAR(256);
    DECLARE v_trie_returnCode   INT;
    DECLARE v_trie_returnMsg    LONGTEXT;
    
    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        ROLLBACK;
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
      `timestamp`                 DATETIME NOT NULL,
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

    SET returnMsg_o = 'get the latest block info from blockchain.header.';
    SELECT IFNULL(MAX(nonce),0) INTO v_curr_block_nonce FROM blockchain.header;
    SET v_new_block_nonce = v_curr_block_nonce + 1;
    SELECT IFNULL(MAX(hash),'') INTO v_header_parenthash FROM blockchain.header WHERE nonce = v_curr_block_nonce;
    SELECT IFNULL(MAX(stateRoot),'') INTO v_pre_stateRoot FROM blockchain.header WHERE nonce = v_curr_block_nonce;
    SELECT IFNULL(MAX(txRoot),'') INTO v_pre_txRoot FROM blockchain.header WHERE nonce = v_curr_block_nonce;
    SELECT IFNULL(MAX(receiptRoot),'') INTO v_pre_receiptRoot FROM blockchain.header WHERE nonce = v_curr_block_nonce;

    # handle state_object data
    IF v_state_object <> '' THEN
        SET returnMsg_o = 'insert temp_cbi_state_object table.';
        SET v_sql = CONCAT('INSERT INTO blockchain_cache.temp_cbi_state_object VALUES ',from_base64(v_state_object));
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

        # generate state_object trie info
        CALL blockchain_cache.`state_trie.insert`(v_pre_stateRoot,v_trie_returnCode,v_trie_returnMsg);
        IF v_trie_returnCode <> 200 THEN
            ROLLBACK;
            SET returnMsg_o = v_trie_returnMsg;
            TRUNCATE TABLE blockchain_cache.temp_cbi_state_object;
            TRUNCATE TABLE blockchain_cache.temp_cbi_transactions;
            DROP TABLE IF EXISTS blockchain_cache.temp_cbi_state_object; 
            DROP TABLE IF EXISTS blockchain_cache.temp_cbi_transactions;
            CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
            LEAVE ll;
        END IF;

        SET returnMsg_o = 'generate header data.';
        INSERT INTO blockchain_cache.header(hash,parentHash,stateRoot,receiptRoot,nonce,time)
             SELECT MD5(hash),v_header_parenthash,hash,v_pre_receiptRoot,v_new_block_nonce,UTC_TIMESTAMP()
               FROM blockchain_cache.state_trie
              WHERE layer = 1
                AND delete_flag = 0;
    ELSE
        SET returnMsg_o = 'generate header data.';
        INSERT INTO blockchain_cache.header(hash,parentHash,stateRoot,receiptRoot,nonce,time)
             VALUES ('',v_header_parenthash,v_pre_stateRoot,v_pre_receiptRoot,v_new_block_nonce,UTC_TIMESTAMP());
    END IF;

    # handle transactions data
    IF v_transactions <> '' THEN
        SET returnMsg_o = 'insert temp_cbi_transactions table.';
        SET v_sql = CONCAT('INSERT INTO blockchain_cache.temp_cbi_transactions VALUES ',from_base64(v_transactions);
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

        # generate transaction trie info
        CALL blockchain_cache.`transaction_trie.insert`(v_pre_txRoot,v_trie_returnCode,v_trie_returnMsg);
        IF v_trie_returnCode <> 200 THEN
            ROLLBACK;
            SET returnMsg_o = v_trie_returnMsg;
            TRUNCATE TABLE blockchain_cache.temp_cbi_state_object;
            TRUNCATE TABLE blockchain_cache.temp_cbi_transactions;
            DROP TABLE IF EXISTS blockchain_cache.temp_cbi_state_object; 
            DROP TABLE IF EXISTS blockchain_cache.temp_cbi_transactions;
            CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
            LEAVE ll;
        END IF;

        SET returnMsg_o = 'update txRoot in header data.';
        UPDATE blockchain_cache.header a,
               blockchain_cache.transaction_trie b
           SET a.txRoot = b.hash
         WHERE a.parentHash = v_header_parenthash
           AND a.delete_flag = 0
           AND b.layer = 1
           AND b.delete_flag = 0;

        SET returnMsg_o = 'generate blockchain body data.';
        SELECT MD5(GROUP_CONCAT(address))
          INTO v_all_trans_hash
          FROM blockchain_cache.transaction_trie
         WHERE layer = 7
           AND delete_flag = 0;

        INSERT INTO blockchain_cache.body(header,hash) VALUES (v_new_block_nonce,v_all_trans_hash);

        SET returnMsg_o = 'generate blockchain body_tx_address data.';
        INSERT INTO blockchain_cache.body_tx_address(hash,tx_address)
             SELECT v_all_trans_hash,address
               FROM blockchain_cache.transaction_trie
              WHERE layer = 7
                AND delete_flag = 0;

    ELSE
        SET returnMsg_o = 'update txRoot in header data.';
        UPDATE blockchain_cache.header
           SET txRoot = v_pre_txRoot
         WHERE parentHash = v_header_parenthash
           AND delete_flag = 0;

    END IF;

    SET returnMsg_o = 'update hash value in blockchain_cache header data.';
    UPDATE blockchain_cache.header
       SET hash = MD5(CONCAT(stateRoot,',',txRoot,',',receiptRoot))
     WHERE parentHash = v_header_parenthash
       AND delete_flag = 0;
    
    # insert into queue
    CALL blockchain_cache.`cacheBlockQueue.insert`(v_returnCode,v_returnMsg);
    IF v_returnCode <> 200 THEN
        ROLLBACK;
        SET returnMsg_o = v_returnMsg;
        TRUNCATE TABLE blockchain_cache.temp_cbi_state_object;
        TRUNCATE TABLE blockchain_cache.temp_cbi_transactions;
        DROP TABLE IF EXISTS blockchain_cache.temp_cbi_state_object; 
        DROP TABLE IF EXISTS blockchain_cache.temp_cbi_transactions;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF; 
    
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