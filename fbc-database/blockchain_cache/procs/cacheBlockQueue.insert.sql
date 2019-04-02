USE `blockchain_cache`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

DROP PROCEDURE IF EXISTS `cacheBlockQueue.insert`;

DELIMITER $$
USE `blockchain_cache`$$
CREATE PROCEDURE `cacheBlockQueue.insert`( 
    OUT returnCode_o            INT,
    OUT returnMsg_o             LONGTEXT
    )
ll:BEGIN
    DECLARE v_procname                      VARCHAR(64) DEFAULT 'cacheBlockQueue.insert';
    DECLARE v_modulename                    VARCHAR(50) DEFAULT 'blockchainCache';
    DECLARE v_params_body                   LONGTEXT DEFAULT '{}';
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
    DECLARE v_blockCache                    LONGTEXT DEFAULT NULL;
    DECLARE v_queues                        LONGTEXT DEFAULT NULL;
    
    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,'',returnMsg_o,v_returnCode,v_returnMsg);
    END;
    
    SET returnCode_o = 400;
    SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error');
    
    SET returnMsg_o = 'fail to get body info';       
    SELECT GROUP_CONCAT('(',header,',"',
                        `hash`,'")')
      INTO v_blockCacheBody
      FROM blockchain_cache.`body`
     WHERE delete_flag = 0;

    SET returnMsg_o = 'fail to get body_tx_address info';
    SELECT GROUP_CONCAT('(',id,',"',
                        `hash`,'","',
                        `tx_address`,'")')
      INTO v_blockCacheAddress
      FROM blockchain_cache.`body_tx_address`
     WHERE delete_flag = 0;    

    SET returnMsg_o = 'fail to get header info';
    SELECT GROUP_CONCAT('("',`parentHash`,'","',
                        `hash`,'","',
                        `stateRoot`,'","',
                        `txRoot`,'","',
                        `receiptRoot`,'","',
                        IFNULL(`bloom`,''),'","',
                        IFNULL(`time`,''),'",',
                        `nonce`,')')
      INTO v_blockCacheHeader
      FROM blockchain_cache.`header`
     WHERE delete_flag = 0;  
   
    SET returnMsg_o = 'fail to get receipt info';
    SELECT GROUP_CONCAT('("',address,'","',
                        `accountAddress`,'","',
                        `txAddress`,'",',
                        `gasCost`,',',
                        `creditRating`,')')
      INTO v_blockCacheReceipt                  
      FROM blockchain_cache.`receipt`
     WHERE delete_flag = 0;

    SET returnMsg_o = 'fail to get receipt info';
    SELECT GROUP_CONCAT('(',id,',"',
                        IFNULL(`parentHash`,''),'","',
                        `hash`,'","',
                        `alias`,'",',
                        `layer`,',"',
                        IFNULL(`address`,''),'")')
      INTO v_blockCacheReceiptTrie                                   
      FROM blockchain_cache.`receipt_trie`
     WHERE delete_flag = 0;
     
    SET returnMsg_o = 'fail to get state_object info';
    SELECT GROUP_CONCAT('("',`accountAddress`,'","',
                        `publicKey`,'",',
                        `creditRating`,',',
                        `balance`,',',
                        IF(`smartContractPrice` IS NULL,'NULL',`smartContractPrice`),',',
                        IF(`minSmartContractDeposit` IS NULL,'NULL',`minSmartContractDeposit`),',',
                        `nonce`,')')
      INTO v_blockCacheStateObject
      FROM blockchain_cache.`state_object`           
     WHERE delete_flag = 0;                                          
    
    SET returnMsg_o = 'fail to get state_trie info';
    SELECT GROUP_CONCAT('(',id,',"',
                        `parentHash`,'","',
                        `hash`,'","',
                        `alias`,'",',
                        `layer`,',"',
                        IFNULL(`address`,''),'")')
      INTO v_blockCacheStateTrie
      FROM blockchain_cache.`state_trie`
     WHERE delete_flag = 0;
     
    SET returnMsg_o = 'fail to get transactions info';
    SELECT GROUP_CONCAT('("',address,'","',
                        `initiator`,'",',
                        `nonceForCurrentInitiator`,',',
                        `nonceForOriginInitiator`,',',
                        IF(`nonceForSmartContract` IS NULL ,'NULL',`nonceForSmartContract`),',"',                                 
                        `receiver`,'","', 
                        `txType`,'","', 
                        `detail`,'",', 
                        `gasCost`,',',
                        `gasDeposit`,',"',
                        `hashSign`,'","',
                        `receiptAddress`,'","',
                        `createTime`,'","',
                        IFNULL(`closeTime`,''),'")'),
           GROUP_CONCAT('("',address,'")')             
      INTO v_blockCacheTransaction,v_blockCache
      FROM blockchain_cache.`transactions`
     WHERE delete_flag = 0;
     
    SET returnMsg_o = 'fail to get transaction_trie info';
    SELECT GROUP_CONCAT('(',id,',"',
                        IFNULL(`parentHash`,''),'","',
                        `hash`,'","',
                        `alias`,'",',
                        `layer`,',"',                                 
                        IFNULL(`address`,''),'")')
      INTO v_blockCacheTransactionTrie                               
      FROM blockchain_cache.`transaction_trie`
     WHERE delete_flag = 0;
     
    SELECT CONCAT(IFNULL(v_blockCacheBody,''),':;',
                  IFNULL(v_blockCacheAddress,''),':;',
                  IFNULL(v_blockCacheHeader,''),':;',
                  IFNULL(v_blockCacheReceipt,''),':;',
                  IFNULL(v_blockCacheReceiptTrie,''),':;',
                  IFNULL(v_blockCacheStateObject,''),':;',
                  IFNULL(v_blockCacheStateTrie,''),':;',
                  IFNULL(v_blockCacheTransaction,''),':;',
                  IFNULL(v_blockCacheTransactionTrie,''),':;'
                  '|$|',IFNULL(v_blockCache,'')) 
     INTO v_queues;
    
    IF REPLACE(REPLACE(v_queues,'|$|',''),':;','') <> '' THEN 
        CALL msg_queues.`queues.insert`(0,CONCAT('(NULL,NULL,''',v_queues,''',0)'),'packingCache',0,NULL,v_returnCode,v_returnMsg);
        IF v_returnCode <> 200 THEN
           SET returnCode_o = 400;
           SET returnMsg_o = 'fail to insert into queue';
           LEAVE ll;
        END IF;
    END IF;

    SET returnCode_o = 200;
    SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,'',returnMsg_o,v_returnCode,v_returnMsg);
    
END $$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;