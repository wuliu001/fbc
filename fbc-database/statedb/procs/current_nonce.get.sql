USE `statedb`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `current_nonce.get` */;

DROP PROCEDURE IF EXISTS `current_nonce.get`;

DELIMITER $$
CREATE PROCEDURE `current_nonce.get`(
    account_addr_i           VARCHAR(256),
    OUT returnCode_o         INT,
    OUT returnMsg_o          LONGTEXT)
ll:BEGIN
    DECLARE v_cnt            INT;
    DECLARE v_procname       VARCHAR(100) DEFAULT 'current_nonce.get';
    DECLARE v_modulename     VARCHAR(50) DEFAULT 'statedb';
    DECLARE v_params_body    LONGTEXT DEFAULT '';
    DECLARE v_returnCode     INT;
    DECLARE v_returnMsg      LONGTEXT;
    DECLARE v_state_nonce    INT;
    DECLARE v_tx_trans_nonce INT;
    
	DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, '-', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
    END;
    
    SET returnCode_o = 400;
    SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error');
    SET v_params_body = CONCAT('{"account_addr_i":"',IFNULL(account_addr_i,''),'"}');
    SET account_addr_i = TRIM(account_addr_i);
    
    SET returnMsg_o = 'check input data validation error.';
    IF IFNULL(account_addr_i,'') = '' THEN
        SET returnCode_o = 511;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'check account_addr_i not exists.';
    SELECT COUNT(1) INTO v_cnt FROM statedb.state_object  WHERE accountAddress = account_addr_i;
    IF v_cnt = 0 THEN
        SET returnCode_o = 512;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;    
    
    SELECT IFNULL(MAX(GREATEST(a.nonce,IFNULL(b.nonce,0))),0) AS current_user_nonce
      FROM statedb.state_object a
      LEFT 
      JOIN tx_cache.transactions b ON a.accountAddress = b.initiator AND a.accountAddress = account_addr_i AND b.delete_flag = 0;
    
    /*
    SELECT IFNULL(MAX(nonce),0) 
      INTO v_state_nonce
      FROM statedb.state_object 
     WHERE accountAddress = account_addr_i;

    SELECT IFNULL(MAX(nonce),0) 
      INTO v_tx_trans_nonce
      FROM tx_cache.transactions 
     WHERE accountAddress = account_addr_i;
    
    
    SELECT IFNULL(v_state_nonce,v_tx_trans_nonce) AS  current_user_nonce;
    
    */
    
    SET returnCode_o = 200;
	SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
END
$$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;