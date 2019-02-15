USE `keystore`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `account_privatekey.get` */;

DROP PROCEDURE IF EXISTS `account_privatekey.get`;

DELIMITER $$
CREATE PROCEDURE `account_privatekey.get`(
    account_addr_i           VARCHAR(256),
    tx_passwd_i              VARCHAR(50),
    OUT returnCode_o         INT,
    OUT returnMsg_o          LONGTEXT)
ll:BEGIN
    DECLARE v_tx_passwd      VARCHAR(50);
    DECLARE v_private_key    TEXT;
    DECLARE v_procname       VARCHAR(100) DEFAULT 'account_privatekey.get';
    DECLARE v_modulename     VARCHAR(50) DEFAULT 'keystore';
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

    SET v_params_body = CONCAT('{"account_addr_i":"',IFNULL(account_addr_i,''),'","tx_passwd_i":"',IFNULL(tx_passwd_i,''),'"}');

    SET account_addr_i = TRIM(account_addr_i);
    SET tx_passwd_i = TRIM(tx_passwd_i);
    
    # check input parameters
    IF account_addr_i = '' OR tx_passwd_i = '' THEN
        SET returnCode_o = 600;
        SET returnMsg_o = 'check input parameters fail.';
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    SELECT IFNULL(MAX(txPassword),''), IFNULL(MAX(private_key),'') 
      INTO v_tx_passwd, v_private_key 
      FROM keystore.accounts 
     WHERE accountAddress = account_addr_i;

    # check account if exist or not
    IF v_tx_passwd = '' THEN
        SET returnCode_o = 651;
        SET returnMsg_o = 'account not exist.';
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    # check account transaction password if match or not
    IF MD5(tx_passwd_i) <> v_tx_passwd THEN
        SET returnCode_o = 652;
        SET returnMsg_o = 'account transaction password not match.';
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    SELECT v_private_key AS private_key;
    
    SET returnCode_o = 200;
	SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
END
$$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;