USE `transaction_cache`;

/*Procedure structure for Procedure `account_gasrequest.get` */;

DROP PROCEDURE IF EXISTS `account_gasrequest.get`;

DELIMITER $$
CREATE PROCEDURE `account_gasrequest.get`(
    account_addr_i           VARCHAR(256),
    OUT returnCode_o         INT,
    OUT returnMsg_o          LONGTEXT)
ll:BEGIN
    DECLARE v_procname       VARCHAR(100) DEFAULT 'account_gasrequest.get';
    DECLARE v_modulename     VARCHAR(50) DEFAULT 'transaction_cache';
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

    SET v_params_body = CONCAT('{"account_addr_i":"',IFNULL(account_addr_i,''),'"}');

    SET account_addr_i = TRIM(account_addr_i);

    # check input parameters
    IF account_addr_i = '' THEN
        SET returnCode_o = 600;
        SET returnMsg_o = 'check input parameters fail.';
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    SELECT IFNULL(SUM(gasCost),0) + IFNULL(SUM(gasDeposit),0) AS gasRequest
      FROM transaction_cache.block 
     WHERE accountAddress = account_addr_i;
    
    SET returnCode_o = 200;
	SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
END
$$
DELIMITER ;
