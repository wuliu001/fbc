USE `statedb`;

/*Procedure structure for Procedure `smartcontract_gasrequest.get` */;

DROP PROCEDURE IF EXISTS `smartcontract_gasrequest.get`;

DELIMITER $$
CREATE PROCEDURE `smartcontract_gasrequest.get`(
    account_addr_i           VARCHAR(256),
    OUT returnCode_o         INT,
    OUT returnMsg_o          LONGTEXT)
ll:BEGIN
    DECLARE v_cnt            BIGINT(20);
    DECLARE v_procname       VARCHAR(100) DEFAULT 'smartcontract_gasrequest.get';
    DECLARE v_modulename     VARCHAR(50) DEFAULT 'statedb';
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

    SELECT COUNT(1) 
      INTO v_cnt
      FROM statedb.state_object 
     WHERE accountAddress = account_addr_i;

    # check account if exist or not
    IF v_cnt = 0 THEN
        SET returnCode_o = 651;
        SET returnMsg_o = 'smart contract account not exist.';
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    SELECT IFNULL(smartContractPrice,0) AS gasCost, 
           IFNULL(minSmartContractDeposit,0) AS gasDeposit 
      FROM statedb.state_object 
     WHERE accountAddress = account_addr_i;

    SET returnCode_o = 200;
	SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
END
$$
DELIMITER ;
