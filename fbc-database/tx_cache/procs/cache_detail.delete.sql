USE `tx_cache`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `cache_detail.delete` */;

DROP PROCEDURE IF EXISTS `cache_detail.delete`;
DELIMITER $$
CREATE PROCEDURE `cache_detail.delete`(
    body_i                   LONGTEXT,
    current_account_nonce_i  INT,
    accountAddress_i         VARCHAR(256),
    OUT returnCode_o         INT,
    OUT returnMsg_o          LONGTEXT)
ll:BEGIN
    DECLARE v_cnt            INT;
    DECLARE v_procname       VARCHAR(100) DEFAULT 'cache_detail.delete';
    DECLARE v_modulename     VARCHAR(50) DEFAULT 'tx_cache';
    DECLARE v_params_body    LONGTEXT DEFAULT '';
    DECLARE v_returnCode     INT;
    DECLARE v_returnMsg      LONGTEXT;
    DECLARE v_statecache     LONGTEXT;
    DECLARE v_trancache      LONGTEXT;
    DECLARE v_sql            LONGTEXT;
    
	DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        ROLLBACK;
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, '-', v_procname, ' execute Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
    END;

    SET v_params_body = CONCAT('{"current_account_nonce_i":"',IFNULL(current_account_nonce_i,''),'","accountAddress_i":"',IFNULL(accountAddress_i,''),'"}');
    SET returnCode_o = 400;
    SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error');
    SET body_i = TRIM(body_i);
    SET accountAddress_i = TRIM(accountAddress_i);

    SET returnMsg_o = 'check input null data';
    IF current_account_nonce_i IS NULL OR IFNULL(accountAddress_i,'') = '' THEN
        SET returnCode_o = 511;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    START TRANSACTION;
    SET SESSION innodb_lock_wait_timeout = 30;
    
    SET returnMsg_o = 'fail to delete tx_cache.state_object';
    IF IFNULL(body_i,'')<> '' THEN
        SET v_sql = CONCAT('UPDATE tx_cache.state_object SET delete_flag = 1 WHERE accountAddress IN (',from_base64(body_i),')');
        CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg); 
    END IF; 
    
    SET returnMsg_o = 'fail to delete tx_cache.transactions';
    UPDATE tx_cache.transactions a,
           keystore.accounts b
       SET a.delete_flag = 1    
     WHERE a.initiator = accountAddress_i
       AND a.initiator = b.accountAddress
       AND a.nonceForCurrentInitiator > current_account_nonce_i
       AND a.nonceForCurrentInitiator <= b.current_packing_nonce;                                                                          
    
    COMMIT;
    
    SET returnCode_o = 200;
	SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
END
$$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;