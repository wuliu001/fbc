USE `contract_match`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `logistic_detail.get` */;

DROP PROCEDURE IF EXISTS `logistic_detail.get`;

DELIMITER $$
CREATE PROCEDURE `logistic_detail.get`(
    account_addr_i           VARCHAR(256),
    logistic_id_i            VARCHAR(32),
    OUT returnCode_o         INT,
    OUT returnMsg_o          LONGTEXT)
ll:BEGIN
    DECLARE v_cnt            BIGINT(20);
    DECLARE v_carNo          VARCHAR(50);
    DECLARE v_procname       VARCHAR(100) DEFAULT 'logistic_detail.get';
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

    SELECT IFNULL(carNo,'') 
      INTO v_carNo
      FROM contract_match.logistics_events
     WHERE logisticNo = logistic_id_i
     ORDER BY recordTime DESC
      LIMIT 1;

    SELECT b.variety,b.fromLocation,b.toLocation,b.weight,v_carNo
      FROM contract_match.transactions a,
           contract_match.logistics b
     WHERE a.initiator = account_addr_i
       AND a.logisticNo = logistic_id_i
       AND a.logisticNo = b.logisticNo;
    
    SELECT recordTime,detail
      FROM contract_match.logistics_events
     WHERE logisticNo = logistic_id_i
     ORDER BY recordTime DESC;
    
    SET returnCode_o = 200;
	SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
END
$$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;