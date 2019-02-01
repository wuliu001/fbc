USE `transaction_cache`;

/*Procedure structure for Procedure `transaction.modify` */;

DROP PROCEDURE IF EXISTS `transaction.modify`;

DELIMITER $$
CREATE PROCEDURE `transaction.modify`(
    type_i                   VARCHAR(32),
    original_tx_address_i    VARCHAR(256),
    new_tx_address_i         VARCHAR(256),
    body_i                   LONGTEXT,
    OUT returnCode_o         INT,
    OUT returnMsg_o          LONGTEXT)
ll:BEGIN
    DECLARE v_cnt            INT;
    DECLARE v_procname       VARCHAR(100) DEFAULT 'transaction.modify';
    DECLARE v_modulename     VARCHAR(50) DEFAULT 'transaction_cache';
    DECLARE v_params_body    LONGTEXT DEFAULT '';
    DECLARE v_returnCode     INT;
    DECLARE v_returnMsg      LONGTEXT;
    
	DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, '-', v_procname, ' execute Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
    END;

    SET v_params_body = CONCAT('{"type_i":"',IFNULL(type_i,''),'","original_tx_address_i":"',IFNULL(original_tx_address_i,''),'","new_tx_address_i":"',IFNULL(new_tx_address_i,''),'"}');

    SET type_i = TRIM(IFNULL(type_i),'');
    SET original_tx_address_i = TRIM(IFNULL(original_tx_address_i),'');
    SET new_tx_address_i = TRIM(IFNULL(new_tx_address_i),'');
    SET body_i = TRIM(IFNULL(body_i),'');

    # check input parameters
    IF type_i = '' OR original_tx_address_i = '' OR new_tx_address_i = '' OR body_i = '' OR JSON_VALID(body_i) = 0 THEN
        SET returnCode_o = 600;
        SET returnMsg_o = 'check input parameters fail.';
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    # check record exists
    SELECT COUNT(1) 
      INTO v_cnt 
      FROM transaction_cache.transactions
     WHERE transactionType = type_i
       AND hashSign = original_tx_address_i;

    IF v_cnt = 0 THEN
        SET returnCode_o = 651;
        SET returnMsg_o = 'No record exist.';
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    UPDATE transaction_cache.transactions
       SET blockObject = body_i,
           hashSign = new_tx_address_i
     WHERE transactionType = type_i
       AND hashSign = original_tx_address_i;
    
    SELECT new_tx_address_i AS txAddress;
    
    SET returnCode_o = 200;
	SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
END
$$
DELIMITER ;
