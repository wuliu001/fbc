USE `contract_match`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `transaction_detail.get` */;

DROP PROCEDURE IF EXISTS `transaction_detail.get`;

DELIMITER $$
CREATE PROCEDURE `transaction_detail.get`(
    account_addr_i           VARCHAR(256),
    OUT returnCode_o         INT,
    OUT returnMsg_o          LONGTEXT)
ll:BEGIN
    DECLARE v_cnt            BIGINT(20);
    DECLARE v_carNo          VARCHAR(50);
    DECLARE v_procname       VARCHAR(100) DEFAULT 'transaction_detail.get';
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

    SET v_params_body = CONCAT('{"account_addr_i":"',IFNULL(account_addr_i,''),'"}');

    SET account_addr_i = TRIM(account_addr_i);
    
    # select data from tx_cache.transactions
    SELECT nonceForCurrentInitiator AS nonce,
           address AS txAddress,
           txType,
           receiver AS contractType,
           IFNULL(TRIM(BOTH '"' FROM detail->"$.Varieties"),'') AS Varieties,
           IFNULL(TRIM(BOTH '"' FROM detail->"$.placeOfProduction"),'') AS placeOfProduction,
           IFNULL(TRIM(BOTH '"' FROM detail->"$.minQuantity"),'') AS minQuantity,
           IFNULL(TRIM(BOTH '"' FROM detail->"$.maxQuantity"),'') AS maxQuantity,
           NULL AS matchedQuantity,
           IFNULL(TRIM(BOTH '"' FROM detail->"$.Price"),'') AS unitPrice,
           NULL AS totalPrice,
           status, 
           NULL AS logisticNo,
           1 AS is_can_modify,
           0 AS has_matched,
           0 AS has_track
      FROM tx_cache.transactions
     WHERE initiator = account_addr_i
       AND delete_flag = 0
    UNION ALL
    # select data from blockchain_cache.transactions
    SELECT nonceForCurrentInitiator AS nonce,
           address AS txAddress,
           txType,
           receiver AS contractType,
           IFNULL(TRIM(BOTH '"' FROM detail->"$.Varieties"),'') AS Varieties,
           IFNULL(TRIM(BOTH '"' FROM detail->"$.placeOfProduction"),'') AS placeOfProduction,
           IFNULL(TRIM(BOTH '"' FROM detail->"$.minQuantity"),'') AS minQuantity,
           IFNULL(TRIM(BOTH '"' FROM detail->"$.maxQuantity"),'') AS maxQuantity,
           NULL AS matchedQuantity,
           IFNULL(TRIM(BOTH '"' FROM detail->"$.Price"),'') AS unitPrice,
           NULL AS totalPrice,
           status, 
           NULL AS logisticNo,
           0 AS is_can_modify,
           0 AS has_matched,
           0 AS has_track
      FROM blockchain_cache.transactions
     WHERE initiator = account_addr_i
       AND delete_flag = 0
    UNION ALL
    # select data from contract_match.transactions
    SELECT nonceForCurrentInitiator AS nonce,
           address AS txAddress,
           txType,
           receiver AS contractType,
           variety AS Varieties,
           placeOfProduction,
           minQuantity,
           maxQuantity,
           matchedQuantity,
           price AS unitPrice,
           totalPrice,
           status, 
           logisticNo,
           0 AS is_can_modify,
           CASE status WHEN 0 THEN 0 WHEN 1 THEN 1 END AS has_matched,
           CASE WHEN logisticNo IS NOT NULL THEN 1 ELSE 0 END AS has_track
      FROM contract_match.transactions
     WHERE initiator = account_addr_i;
    
    SET returnCode_o = 200;
	SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
END
$$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;