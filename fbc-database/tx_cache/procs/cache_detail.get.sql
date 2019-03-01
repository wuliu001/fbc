USE `tx_cache`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `cache_detail.get` */;

DROP PROCEDURE IF EXISTS `cache_detail.get`;

DELIMITER $$
CREATE PROCEDURE `cache_detail.get`(
    accountAddress_i         VARCHAR(256),
    current_user_nonce_i     INT,
    time_diff_i              INT,
    OUT returnCode_o         INT,
    OUT returnMsg_o          LONGTEXT)
ll:BEGIN
    DECLARE v_cnt            INT;
    DECLARE v_procname       VARCHAR(100) DEFAULT 'cache_detail.get';
    DECLARE v_modulename     VARCHAR(50) DEFAULT 'tx_cache';
    DECLARE v_params_body    LONGTEXT DEFAULT '';
    DECLARE v_returnCode     INT;
    DECLARE v_returnMsg      LONGTEXT;
    
	DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, '-', v_procname, ' execute Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
    END;

    SET v_params_body = CONCAT('{"accountAddress_i":"',IFNULL(accountAddress_i,''),'"current_user_nonce_i":"',IFNULL(current_user_nonce_i,''),'"time_diff_i":"',IFNULL(time_diff_i,''),'"}');
    SET returnCode_o = 400;
    SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error');
    SET accountAddress_i = TRIM(accountAddress_i);
    #SET current_user_nonce_i = IF(current_user_nonce_i IS NULL,0,current_user_nonce_i);
    #SET time_diff_i = IF(time_diff_i IS NULL,0,time_diff_i);

    SET returnMsg_o = 'check input null data';
    IF IFNULL(accountAddress_i,'') = '' OR current_user_nonce_i IS NULL OR time_diff_i IS NULL THEN
        SET returnCode_o = 511;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'fail to check nonce continuity';
    
    SELECT  txAddress, accountAddress, transactionType, blockObject, hashSign, gasCost, gasDeposit, nonce, `timestamp`, comfirmedTimes FROM tx_cache.transactions where accountAddress=accountAddress_i;
    SELECT  accountAddress, publicKey, creditRating, balance, smartContractPrice, minSmartContractDeposit, nonce FROM tx_cache.state_object where accountAddress=accountAddress_i;

    SET returnCode_o = 200;
	SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
END
$$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;