USE `contract_match`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `logistic_status.update` */;

DROP PROCEDURE IF EXISTS `logistic_status.update`;

DELIMITER $$
CREATE PROCEDURE `logistic_status.update`(
    account_addr_i           VARCHAR(256),
    logistic_id_i            VARCHAR(32),
    OUT returnCode_o         INT,
    OUT returnMsg_o          LONGTEXT)
ll:BEGIN
    DECLARE v_cnt            BIGINT(20);
    DECLARE v_procname       VARCHAR(100) DEFAULT 'logistic_status.update';
    DECLARE v_modulename     VARCHAR(50) DEFAULT 'contract_match';
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

    SET v_params_body = CONCAT('{"account_addr_i":"',IFNULL(account_addr_i,''),'","logistic_id_i":"',IFNULL(logistic_id_i,''),'"}');

    SET account_addr_i = TRIM(account_addr_i);
    SET logistic_id_i = TRIM(logistic_id_i);
    
    # check input parameters
    IF account_addr_i = '' or logistic_id_i = '' THEN
        SET returnCode_o = 600;
        SET returnMsg_o = 'check input parameters fail.';
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    SELECT COUNT(1) 
      INTO v_cnt
      FROM contract_match.transactions 
     WHERE initiator = account_addr_i
       AND logisticNo = logistic_id_i;

    # check account if exist or not
    IF v_cnt = 0 THEN
        SET returnCode_o = 651;
        SET returnMsg_o = 'no matched logistic info.';
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    UPDATE contract_match.transactions
       SET status = 2,
           last_update_time = UTC_TIMESTAMP()
     WHERE initiator = account_addr_i
       AND logisticNo = logistic_id_i;
    
    SET returnCode_o = 200;
	SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
END
$$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;