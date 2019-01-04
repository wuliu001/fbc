USE `blockchain_cache`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `cachePurchase.update` */;

DROP PROCEDURE IF EXISTS `cachePurchase.update`;

DELIMITER $$
USE `blockchain_cache`$$
CREATE PROCEDURE `cachePurchase.update`( 
    old_purchase_batch_i             VARCHAR(256),
    body_i                           LONGTEXT,
    user_i                           VARCHAR(50),
    type_i                           VARCHAR(32), 
    hashsign_i                       VARCHAR(256),
    is_create_i                      TINYINT(4),
    node_dns_i                       VARCHAR(100),
    OUT new_purchase_id_o            VARCHAR(256),
    OUT returnCode_o                 INT,
    OUT returnMsg_o                  LONGTEXT
    )
ll:BEGIN
    DECLARE v_params_body               LONGTEXT DEFAULT NULL;
    DECLARE v_procname                  VARCHAR(64) DEFAULT 'cachePurchase.update';
    DECLARE v_modulename                VARCHAR(50) DEFAULT 'blockchainCache';
    DECLARE v_returnCode                INT DEFAULT 0;
    DECLARE v_returnMsg                 LONGTEXT DEFAULT '';
    DECLARE v_user                      VARCHAR(50);
    DECLARE v_type                      VARCHAR(32);
    DECLARE v_body                      LONGTEXT;
    DECLARE v_hashsign                  VARCHAR(256);
    DECLARE v_old_purchase_batch        VARCHAR(256);
    DECLARE v_is_create                 TINYINT(4);
    DECLARE v_node_dns                  VARCHAR(100);
    
    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
    END;
    
    SET returnCode_o = 400;
    SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error');
    SET v_params_body = CONCAT('{"user_i":"',IFNULL(user_i,''),'","type_i":"',IFNULL(type_i,''),'","hashsign_i":"',IFNULL(hashsign_i,''),'","old_purchase_batch_i":"',IFNULL(old_purchase_batch_i,'')
                                 ,'","is_create_i":"',IFNULL(is_create_i,''),'","node_dns_i":"',IFNULL(node_dns_i,''),'"}');
    SET v_user = TRIM(user_i);
    SET v_type = TRIM(type_i);
    SET v_hashsign = TRIM(hashsign_i);
    SET v_old_purchase_batch = TRIM(old_purchase_batch_i);
    SET v_body = TRIM(body_i);
    SET v_is_create = TRIM(is_create_i);
    SET v_node_dns = TRIM(node_dns_i);
    
    SET returnMsg_o = 'fail to delete old purchase batch.';
    CALL blockchain_cache.`cachePurchase.delete`(v_body,v_user,v_old_purchase_batch,v_node_dns,v_returnCode,v_returnMsg);
    IF v_returnCode <> 200 THEN
        SET returnMsg_o = CONCAT(returnMsg_o,v_returnMsg);
        SET returnCode_o = v_returnCode;               
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'fail to delete insert new purchase batch.';
    CALL blockchain_cache.`cachePurchase.insert`(v_body,v_user,v_type,v_hashsign,v_is_create,v_node_dns,new_purchase_id_o,v_returnCode,v_returnMsg);
    IF v_returnCode <> 200 THEN
        SET returnMsg_o = CONCAT(returnMsg_o,v_returnMsg);
        SET returnCode_o = v_returnCode;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    SET returnCode_o = 200;
    SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
    
END $$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;