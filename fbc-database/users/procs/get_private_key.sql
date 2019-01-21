USE `users`;

/*Procedure structure for Procedure `get_private_key` */;

DROP PROCEDURE IF EXISTS `get_private_key`;

DELIMITER $$
CREATE DEFINER=`dba`@`%` PROCEDURE `get_private_key`(id_i           VARCHAR(50),
                                              trans_passwd_i        VARCHAR(50),
                                              OUT private_key_o     VARCHAR(50),
                                              OUT returnCode_o      INT,
                                              OUT returnMsg_o       LONGTEXT )
ll:BEGIN
    DECLARE v_procname               VARCHAR(100) DEFAULT 'users.get_private_key';
    DECLARE v_modulename             VARCHAR(50) DEFAULT 'userManagement';
    DECLARE v_params_body            LONGTEXT DEFAULT '';
    DECLARE v_returnCode             INT;
    DECLARE v_returnMsg              LONGTEXT;
    DECLARE v_private_key            VARCHAR(50);
    
	DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
    END;
    
    SET returnCode_o = 400;
    SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error');
    SET v_params_body = CONCAT('{"id_i":"',IFNULL(id_i,''),'"."trans_passwd_i":"',IFNULL(trans_passwd_i,''),'"}');
    SET id_i = TRIM(id_i);
    SET trans_passwd_i = TRIM(trans_passwd_i);
    
    SET returnMsg_o = 'check input null data.';
    IF IFNULL(id_i,'') = '' OR IFNULL(trans_passwd_i,'') = '' THEN
        SET returnCode_o = 511;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'check user and trans_password fail.';
    SELECT MAX(private_key) INTO v_private_key FROM `users`.`private_keys` WHERE id = id_i AND trans_password = MD5(trans_passwd_i);
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
