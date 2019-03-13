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
     KEY `key_queue_id`         (`accountAddress`)
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
      KEY `key_queue_id`          (`queue_id`)
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

    SET returnMsg_o = 'insert temp_cbi_state_object table.';
    IF v_state_object <> '' THEN
        SET v_sql = CONCAT('INSERT INTO blockchain_cache.temp_cbi_state_object VALUES ',v_state_object);
        CALL commons.dynamic_sql_execute(v_sql,v_returnCode,v_returnMsg);
    END IF;

    SET returnMsg_o = 'insert temp_cbi_transactions table.';
    SET v_sql = CONCAT('INSERT INTO blockchain_cache.temp_cbi_transactions VALUES ',v_transactions);
    CALL commons.dynamic_sql_execute(v_sql,v_returnCode,v_returnMsg);

    SET returnMsg_o = 'generate state_object trie info.';
    INSERT INTO blockchain_cache.state_object(accountAddress,publicKey,creditRating,balance,smartContractPrice,minSmartContractDeposit,nonce)
         SELECT a.accountAddress,
                a.publicKey,
                a.creditRating,
                a.balance,
                a.smartContractPrice,
                a.minSmartContractDeposit,
                a.nonce
           FROM blockchain_cache.temp_cbi_state_object a
             ON DUPLICATE KEY UPDATE creditRating = a.creditRating,
                                     balance = a.balance,
                                     nonce = a.nonce;

    SET returnMsg_o = 'generate transaction trie info.';

    SET returnMsg_o = 'generate receipt trie info.';

    SET returnMsg_o = 'generate blockchain header data.';

    SET returnMsg_o = 'generate blockchain body data.';

    SET returnMsg_o = 'generate blockchain body_tx_address data.';

    COMMIT;

    SET returnCode_o = 200;
    SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
    
END $$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;