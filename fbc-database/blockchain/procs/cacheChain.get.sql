USE `blockchain`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `cacheChain.get` */;

DROP PROCEDURE IF EXISTS `cacheChain.get`;

DELIMITER $$
USE `blockchain`$$
CREATE PROCEDURE `cacheChain.get`( 
    OUT returnCode_o            INT,
    OUT returnMsg_o             LONGTEXT
    )
ll:BEGIN
    DECLARE v_procname                      VARCHAR(64) DEFAULT 'cacheChain.get';
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
    
    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;    
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
    END;
    
    SET returnCode_o = 400;
    SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error');
    SET v_params_body = CONCAT('{}');
    
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
                        IFNULL(`closeTime`,''),'")')
      INTO v_blockCacheTransaction
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
    
    SELECT IFNULL(v_blockCacheBody,'') AS blockCacheBody,
           IFNULL(v_blockCacheAddress,'') AS blockCacheAddress,
           IFNULL(v_blockCacheHeader,'') AS blockCacheHeader,
           IFNULL(v_blockCacheReceipt,'') AS blockCacheReceipt,
           IFNULL(v_blockCacheReceiptTrie,'') AS blockCacheReceiptTrie,
           IFNULL(v_blockCacheStateObject,'') AS blockCacheStateObject,
           IFNULL(v_blockCacheStateTrie,'') AS blockCacheStateTrie,
           IFNULL(v_blockCacheTransaction,'') AS blockCacheTransaction,
           IFNULL(v_blockCacheTransactionTrie,'') blockCacheTransactionTrie;

    SET returnCode_o = 200;
    SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
    
END $$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;