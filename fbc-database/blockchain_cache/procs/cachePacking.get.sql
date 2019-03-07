USE `blockchain_cache`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `cachePacking.get` */;

DROP PROCEDURE IF EXISTS `cachePacking.get`;

DELIMITER $$
CREATE PROCEDURE `cachePacking.get`(
    OUT returnCode_o         INT,
    OUT returnMsg_o          LONGTEXT)
ll:BEGIN
    DECLARE v_cnt                    INT;
    DECLARE v_procname               VARCHAR(100) DEFAULT 'cachePacking.get';
    DECLARE v_modulename             VARCHAR(50) DEFAULT 'blockchain_cache';
    DECLARE v_params_body            LONGTEXT DEFAULT '';
    DECLARE v_returnCode             INT;
    DECLARE v_returnMsg              LONGTEXT;
    
	DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, '-', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
    END;

    SET v_params_body = CONCAT('{}');
    SET returnCode_o = 400;
    SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error');
    
    SET returnMsg_o = 'fail to return transaction datas';
    SELECT GROUP_CONCAT('("',txAddress,'","',
                        accountAddress, '","',
                        transactionType, '","',
                        blockObject, '","',
                        hashSign, '",',
                        gasCost, ',',
                        gasDeposit, ',',
                        IF(nonce IS NULL,'NULL',nonce), ',',
                        `timestamp`,',',
                        comfirmedTimes,')')
        AS transactionPackingCache
      FROM tx_cache.transactions
     WHERE delete_flag = 0;
    
    SET returnMsg_o = 'fail to return cache state_object datas';
    SELECT GROUP_CONCAT('("',accountAddress,'","',
                             publicKey, '",',
                             creditRating, ',',
                             balance, ',', 
                             IF(smartContractPrice IS NULL,'NULL',smartContractPrice), ',',
                             IF(minSmartContractDeposit IS NULL,'NULL',minSmartContractDeposit), ',',
                             nonce ,')')
        AS stateObjectPackingCache
      FROM tx_cache.state_object 
     WHERE delete_flag = 0;
    
    SET returnCode_o = 200;
	SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
END
$$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;