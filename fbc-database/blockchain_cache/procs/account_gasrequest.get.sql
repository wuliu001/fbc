USE `blockchain_cache`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `account_gasrequest.get` */;

DROP PROCEDURE IF EXISTS `account_gasrequest.get`;

DELIMITER $$
CREATE PROCEDURE `account_gasrequest.get`(
    account_addr_i               VARCHAR(256),
    OUT returnCode_o             INT,
    OUT returnMsg_o              LONGTEXT)
ll:BEGIN
    DECLARE v_procname           VARCHAR(100) DEFAULT 'account_gasrequest.get';
    DECLARE v_modulename         VARCHAR(50) DEFAULT 'blockchain_cache';
    DECLARE v_params_body        LONGTEXT DEFAULT '';
    DECLARE v_returnCode         INT;
    DECLARE v_returnMsg          LONGTEXT;
    DECLARE v_packinggasCost     FLOAT;
    DECLARE v_packinggasDeposit  FLOAT;
    DECLARE v_unmatchgasCost     FLOAT;
    DECLARE v_unmatchgasDeposit  FLOAT;
    
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

    SELECT IFNULL(SUM(gasCost),0),IFNULL(SUM(gasDeposit),0)
      INTO v_packinggasCost,v_packinggasDeposit
      FROM blockchain_cache.transactions 
     WHERE initiator = account_addr_i
       AND delete_flag = 0;

    SELECT IFNULL(SUM(gasCost),0),IFNULL(SUM(gasDeposit),0)
      INTO v_unmatchgasCost,v_unmatchgasDeposit
      FROM contract_match.transactions 
     WHERE initiator = account_addr_i
       AND status = 0;
    
    SELECT (v_packinggasCost + v_unmatchgasCost) AS gasCost,
           (v_packinggasDeposit + v_unmatchgasDeposit) AS gasDeposit;

    SET returnCode_o = 200;
	SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
END
$$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;