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
    SET v_state_object = IFNULL(JSON_EXTRACT(body_i,'$.state_object'),'');
    SET v_transactions = IFNULL(JSON_EXTRACT(body_i,'$.transactions'),'');

    IF v_transactions = '' THEN
        SET returnCode_o = 511;
        SET returnMsg_o = 'there is no transaction detail info in body!';
        TRUNCATE TABLE blockchain_cache.temp_cbi_state_object;
        TRUNCATE TABLE blockchain_cache.temp_cbi_transactions;
        DROP TABLE IF EXISTS blockchain_cache.temp_cbi_state_object; 
        DROP TABLE IF EXISTS blockchain_cache.temp_cbi_transactions;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
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
    END IF;

    SET returnMsg_o = 'insert temp_cbi_transactions table.';
    SET v_sql = CONCAT('INSERT INTO blockchain_cache.temp_cbi_transactions VALUES ',v_transactions);
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
           WHERE publicKey IS NULL
             AND delete_flag = 0;

    # generate the 3rd layer data in state_trie
    # alias: 3a_95
    INSERT INTO blockchain_cache.state_trie(alias,layer)
          SELECT CONCAT(SUBSTR(SUBSTR(alias,1,4),1,2),'_',SUBSTR(SUBSTR(alias,1,4),3,2)),3
            FROM blockchain_cache.state_trie
           WHERE layer = 4
           GROUP BY alias;

    # generate the 2nd layer data in state_trie
    # alias: 3a
    INSERT INTO blockchain_cache.state_trie(alias,layer)
          SELECT SUBSTR(alias,1,2),2
            FROM blockchain_cache.state_trie
           WHERE layer = 3
           GROUP BY alias;

    # get 2nd layer data from statedb.state_trie
    INSERT INTO blockchain_cache.state_trie(hash,alias,layer)
         SELECT a.hash,a.alias,a.layer
           FROM statedb.state_trie a
          WHERE a.parentHash = v_pre_stateRoot
            AND a.layer = 2
            AND NOT EXISTS (SELECT 1 FROM blockchain_cache.state_trie b WHERE b.layer = 2 AND b.alias = a.alias);

    # get 3rd layer data from statedb.state_trie
    INSERT INTO blockchain_cache.state_trie(alias,layer)
         SELECT b.alias,b.layer
           FROM statedb.state_trie a,
                statedb.state_trie b
          WHERE a.parentHash = v_pre_stateRoot
            AND a.layer = 2
            AND EXISTS (SELECT 1 FROM blockchain_cache.state_trie c WHERE c.layer = 2 AND c.alias = a.alias)
            AND b.parentHash = a.hash
            AND b.layer = 3
            AND NOT EXISTS (SELECT 1 FROM blockchain_cache.state_trie d WHERE d.layer = 3 AND d.alias = b.alias);

    # get 4th layer data from statedb.state_trie
    INSERT INTO blockchain_cache.state_trie(hash,alias,layer,address)
         SELECT c.hash,c.alias,c.layer,c.address
           FROM statedb.state_trie a,
                statedb.state_trie b,
                statedb.state_trie c
          WHERE a.parentHash = v_pre_stateRoot
            AND a.layer = 2
            AND EXISTS (SELECT 1 FROM blockchain_cache.state_trie d WHERE d.layer = 2 AND d.alias = a.alias)
            AND b.parentHash = a.hash
            AND b.layer = 3
            AND EXISTS (SELECT 1 FROM blockchain_cache.state_trie e WHERE e.layer = 3 AND e.alias = b.alias)
            AND c.parentHash = b.hash
            AND c.layer = 4
            AND NOT EXISTS (SELECT 1 FROM blockchain_cache.state_trie f WHERE f.layer = 4 AND f.alias = c.alias);

    # update the 3 layer hash value in blockchain_cache.state_trie
    UPDATE blockchain_cache.state_trie a,
           (SELECT CONCAT(SUBSTR(SUBSTR(alias,1,4),1,2),'_',SUBSTR(SUBSTR(alias,1,4),3,2)) AS pre_alias,
                   MD5(GROUP_CONCAT(hash)) AS hash
              FROM blockchain_cache.state_trie
             WHERE layer = 4
             GROUP BY CONCAT(SUBSTR(SUBSTR(alias,1,4),1,2),'_',SUBSTR(SUBSTR(alias,1,4),3,2))) b
       SET a.hash = b.hash
     WHERE a.alias = b.pre_alias
       AND a.layer = 3;
    
    # update the 4 layer parentHash value in blockchain_cache.state_trie
    UPDATE blockchain_cache.state_trie a,
           blockchain_cache.state_trie b
       SET a.parentHash = b.hash
     WHERE a.layer = 4
       AND b.layer = 3
       AND RELACE(b.alias,'_','') = SUBSTR(a.alias,1,4);

    # update the 2 layer hash value in blockchain_cache.state_trie
    UPDATE blockchain_cache.state_trie a,
           (SELECT SUBSTR(alias,1,2) AS pre_alias,
                   MD5(GROUP_CONCAT(hash)) AS hash
              FROM blockchain_cache.state_trie
             WHERE layer = 3
             GROUP BY SUBSTR(alias,1,2)) b
       SET a.hash = b.hash
     WHERE a.alias = b.pre_alias
       AND a.layer = 2
       AND a.hash <> '';

    # update the 3 layer parentHash value in blockchain_cache.state_trie
    UPDATE blockchain_cache.state_trie a,
           blockchain_cache.state_trie b
       SET a.parentHash = b.hash
     WHERE a.layer = 3
       AND b.layer = 2
       AND b.alias = SUBSTR(a.alias,1,2);

    # generate stateRoot (1 layer) data
    INSERT INTO blockchain_cache.state_trie(hash,layer)
         SELECT MD5(GROUP_CONCAT(hash)),1
           FROM blockchain_cache.state_trie
          WHERE layer = 2;
    
    # update the 2 layer parentHash value in blockchain_cache.state_trie
    UPDATE blockchain_cache.state_trie a,
           blockchain_cache.state_trie b
       SET a.parentHash = b.hash
     WHERE a.layer = 2
       AND b.layer = 1;

    # generate header data
    INSERT INTO blockchain_cache.header(parentHash,stateRoot,nonce)
         SELECT v_header_parenthash,hash,v_new_block_nonce
           FROM blockchain_cache.state_trie
          WHERE layer = 1;

    SET returnMsg_o = 'insert state_object data from temp_cbi_transactions table.';
    INSERT INTO blockchain_cache.state_object(accountAddress,publicKey,creditRating,balance,smartContractPrice,minSmartContractDeposit,nonce)
         SELECT a.accountAddress, 
                a.publicKey,
                a.creditRating,
                a.balance - b.gasCost, 
                a.smartContractPrice,
                a.minSmartContractDeposit,
                b.nonce
           FROM statedb.state_object a,
                (SELECT initiator,
                        SUM(gasCost) gasCost, 
                        MAX(nonceForCurrentInitiator) nonce
                   FROM blockchain_cache.temp_cbi_transactions
                  GROUP BY initiator) b
          WHERE a.accountAddress = b.initiator;


    SET returnMsg_o = 'generate transaction trie info.';

    SET returnMsg_o = 'generate receipt trie info.';

    SET returnMsg_o = 'generate blockchain header data.';

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