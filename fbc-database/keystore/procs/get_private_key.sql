USE `keystore`;

/*Procedure structure for Procedure `get_private_key` */;

DROP PROCEDURE IF EXISTS `get_private_key`;

DELIMITER $$
CREATE DEFINER=`dba`@`%` PROCEDURE `get_private_key`(account_addr_i           VARCHAR(256),
                                              tx_passwd_i        VARCHAR(50),
                                              OUT private_key_o     TEXT,
                                              OUT returnCode_o      INT,
                                              OUT returnMsg_o       LONGTEXT )
ll:BEGIN
    DECLARE v_procname               VARCHAR(100) DEFAULT 'keystore.get_private_key';
    DECLARE v_modulename             VARCHAR(50) DEFAULT 'keystore';
    DECLARE v_params_body            LONGTEXT DEFAULT '';
    DECLARE v_returnCode             INT;
    DECLARE v_returnMsg              LONGTEXT;
    DECLARE v_private_key            TEXT;
    
	DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
    END;
    
    SET returnCode_o = 400;
    SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error');
    SET v_params_body = CONCAT('{"account_addr_i":"',IFNULL(account_addr_i,''),'"."tx_passwd_i":"',IFNULL(tx_passwd_i,''),'"}');
    SET account_addr_i = TRIM(account_addr_i);
    SET tx_passwd_i = TRIM(tx_passwd_i);
    
    SET returnMsg_o = 'check input null data.';
    IF IFNULL(account_addr_i,'') = '' OR IFNULL(tx_passwd_i,'') = '' THEN
        SET returnCode_o = 511;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'check user and trans_password fail.';
    SELECT MAX(private_key) INTO v_private_key FROM keystore.accounts WHERE accountAddress = account_addr_i AND txPassword = MD5(tx_passwd_i);
    IF IFNULL(v_private_key,'') = '' THEN
        SET returnCode_o = 512;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET private_key_o = v_private_key;
    SET returnCode_o = 200;
	SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
END
$$
DELIMITER ;
