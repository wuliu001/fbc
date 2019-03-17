USE `blockchain_cache`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `cachePacking.delete` */;

DROP PROCEDURE IF EXISTS `cachePacking.delete`;

DELIMITER $$
CREATE PROCEDURE `cachePacking.delete`(
    OUT returnCode_o         INT,
    OUT returnMsg_o          LONGTEXT)
ll:BEGIN
    DECLARE v_procname                      VARCHAR(64) DEFAULT 'cachePacking.delete';
    DECLARE v_modulename                    VARCHAR(50) DEFAULT 'blockchainCache';
    DECLARE v_user                          VARCHAR(50);
    DECLARE v_params_body                   LONGTEXT DEFAULT NULL;
    DECLARE v_returnCode                    INT DEFAULT 0;
    DECLARE v_returnMsg                     LONGTEXT DEFAULT '';
    
    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;    
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
    END;
    
    SET returnCode_o = 400;
    SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error');
    SET v_params_body = CONCAT('{}');
    
    UPDATE blockchain_cache.body SET delete_flag = 1 WHERE delete_flag = 0;                          
    UPDATE blockchain_cache.body_tx_address SET delete_flag = 1 WHERE delete_flag = 0;
    UPDATE blockchain_cache.header SET delete_flag = 1 WHERE delete_flag = 0;
    UPDATE blockchain_cache.receipt SET delete_flag = 1 WHERE delete_flag = 0;                    
    UPDATE blockchain_cache.receipt_trie SET delete_flag = 1 WHERE delete_flag = 0;                        
    UPDATE blockchain_cache.state_object SET delete_flag = 1 WHERE delete_flag = 0;                   
    UPDATE blockchain_cache.state_trie SET delete_flag = 1 WHERE delete_flag = 0;                  
    UPDATE blockchain_cache.transactions SET delete_flag = 1 WHERE delete_flag = 0;
    UPDATE blockchain_cache.transaction_trie SET delete_flag = 1 WHERE delete_flag = 0;
    
    SET returnCode_o = 200;
	SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
END
$$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;