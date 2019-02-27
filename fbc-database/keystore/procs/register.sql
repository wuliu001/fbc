USE `keystore`;

/*Procedure structure for Procedure `register` */;

DROP PROCEDURE IF EXISTS `register`;

DELIMITER $$
CREATE DEFINER=`dba`@`%` PROCEDURE `register`(accountAddress_i        VARCHAR(256),
                                              txPassword_i            VARCHAR(50),
                                              body_i                  LONGTEXT,
                                              current_packing_nonce_i INT,
                                              OUT returnCode_o        INT,
                                              OUT returnMsg_o         LONGTEXT )
ll:BEGIN
    DECLARE v_procname               VARCHAR(100) DEFAULT 'keystore.register';
    DECLARE v_modulename             VARCHAR(50) DEFAULT 'keystore';
    DECLARE v_params_body            LONGTEXT DEFAULT '';
    DECLARE v_returnCode             INT;
    DECLARE v_returnMsg              LONGTEXT;
    DECLARE v_keyReg_sys_lock        INT;
    DECLARE v_checker                INT;
    
	DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        SET v_keyReg_sys_lock = RELEASE_LOCK('keystore_register');
    END;
    
    SET returnCode_o = 400;
    SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error');
    SET v_params_body = CONCAT('{"accountAddress_i":"',IFNULL(accountAddress_i,''),'"."current_packing_nonce_i":"',IFNULL(current_packing_nonce_i,''),'"."txPassword_i":"',IFNULL(txPassword_i,''),'"}');
    SET accountAddress_i = TRIM(accountAddress_i);
    SET body_i = TRIM(body_i);
    SET txPassword_i = TRIM(txPassword_i);
    #SET current_packing_nonce_i = IF(current_packing_nonce_i IS NULL,0,current_packing_nonce_i);
    
    SET returnMsg_o = 'get system lock fail.';
    SET v_keyReg_sys_lock = GET_LOCK('keystore_register',180);
    IF v_keyReg_sys_lock <> 1 THEN
        SET returnCode_o = 511;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'check input null data.';
    IF IFNULL(accountAddress_i,'') = '' OR IFNULL(body_i,'') = '' OR IFNULL(txPassword_i,'') = '' OR current_packing_nonce_i IS NULL THEN
        SET returnCode_o = 512;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        SET v_keyReg_sys_lock = RELEASE_LOCK('keystore_register');
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'This private key format is wrong.';
    SELECT body_i REGEXP '^-----BEGIN RSA PRIVATE KEY-----' AND body_i REGEXP '-----END RSA PRIVATE KEY-----$'
      INTO v_checker;
    IF v_checker = 0 THEN
        SET returnCode_o = 513;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        SET v_keyReg_sys_lock = RELEASE_LOCK('keystore_register');
        LEAVE ll;
    END IF;
	
    INSERT INTO `keystore`.`accounts`(`accountAddress`,`txPassword`, `private_key`,current_packing_nonce)
         VALUES (accountAddress_i,MD5(txPassword_i), body_i,current_packing_nonce_i);
    
    SET v_keyReg_sys_lock = RELEASE_LOCK('keystore_register');
    
    SET returnCode_o = 200;
	SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
END
$$
DELIMITER ;
