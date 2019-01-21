USE `users`;

/*Procedure structure for Procedure `register` */;

DROP PROCEDURE IF EXISTS `register`;

DELIMITER $$
CREATE DEFINER=`dba`@`%` PROCEDURE `register`(id_i                  VARCHAR(50),
                                              trans_passwd_i        VARCHAR(50),
                                              body_i                LONGTEXT,
                                              OUT returnCode_o      INT,
                                              OUT returnMsg_o       LONGTEXT )
ll:BEGIN
    DECLARE v_procname               VARCHAR(100) DEFAULT 'users.register';
    DECLARE v_modulename             VARCHAR(50) DEFAULT 'userManagement';
    DECLARE v_params_body            LONGTEXT DEFAULT '';
    DECLARE v_returnCode             INT;
    DECLARE v_returnMsg              LONGTEXT;
    DECLARE v_userReg_sys_lock       INT;
    DECLARE v_checker                INT;
    
	DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        SET v_userReg_sys_lock = RELEASE_LOCK('user_register');
    END;
    
    SET returnCode_o = 400;
    SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error');
    SET v_params_body = CONCAT('{"id_i":"',IFNULL(id_i,''),'"."trans_passwd_i":"',IFNULL(trans_passwd_i,''),'"}');
    SET id_i = TRIM(id_i);
    SET body_i = TRIM(body_i);
    SET trans_passwd_i = TRIM(trans_passwd_i);
    
    SET returnMsg_o = 'get system lock fail.';
    SET v_userReg_sys_lock = GET_LOCK('user_register',180);
    IF v_userReg_sys_lock <> 1 THEN
        SET returnCode_o = 511;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'check input null data.';
    IF IFNULL(id_i,'') = '' OR IFNULL(body_i,'') = '' OR IFNULL(trans_passwd_i,'') = '' THEN
        SET returnCode_o = 512;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        SET v_userReg_sys_lock = RELEASE_LOCK('user_register');
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'This private key format is wrong.';
    SELECT body_i REGEXP '^-----BEGIN RSA PRIVATE KEY-----' AND body_i REGEXP '-----END RSA PRIVATE KEY-----$'
      INTO v_checker;
    IF v_checker = 0 THEN
        SET returnCode_o = 513;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        SET v_userReg_sys_lock = RELEASE_LOCK('user_register');
        LEAVE ll;
    END IF;
	
    INSERT INTO `users`.`private_keys`(`id`,`trans_password`, `private_key`)
         VALUES (id_i,MD5(trans_passwd_i), body_i);
    
    SET v_userReg_sys_lock = RELEASE_LOCK('user_register');
    
    SET returnCode_o = 200;
	SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
END
$$
DELIMITER ;
