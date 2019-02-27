USE `tx_cache`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `transaction_detail.get` */;

DROP PROCEDURE IF EXISTS `transaction_detail.get`;

DELIMITER $$
CREATE PROCEDURE `transaction_detail.get`(
    tx_address_i             VARCHAR(256),
    OUT returnCode_o         INT,
    OUT returnMsg_o          LONGTEXT)
ll:BEGIN
    DECLARE v_cnt            INT;
    DECLARE v_procname       VARCHAR(100) DEFAULT 'transaction_detail.get';
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

    SET v_params_body = CONCAT('{"tx_address_i":"',IFNULL(tx_address_i,''),'"}');

    SET tx_address_i = TRIM(IFNULL(tx_address_i,''));

    # check input parameters
    IF tx_address_i = '' THEN
        SET returnCode_o = 600;
        SET returnMsg_o = 'check input parameters fail.';
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    # check record exists
    SELECT COUNT(1) 
      INTO v_cnt 
      FROM tx_cache.transactions
     WHERE txAddress = tx_address_i;

    IF v_cnt = 0 THEN
        SET returnCode_o = 651;
        SET returnMsg_o = 'No record exist.';
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    SELECT blockObject 
      FROM tx_cache.transactions 
     WHERE txAddress = tx_address_i;

    SET returnCode_o = 200;
	SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
END
$$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;