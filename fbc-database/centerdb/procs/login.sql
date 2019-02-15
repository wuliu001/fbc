USE `centerdb`;

/*Procedure structure for Procedure `login` */;

DROP PROCEDURE IF EXISTS `login`;

DELIMITER $$
CREATE DEFINER=`dba`@`%` PROCEDURE `login`(
						   userAccount_i         VARCHAR(50),
                           password_i            VARCHAR(100),
						   OUT returnCode_o      INT,
						   OUT returnMsg_o       LONGTEXT)
ll:BEGIN
    DECLARE v_procname               VARCHAR(100) DEFAULT 'centerdb.login';
    DECLARE v_params_body            LONGTEXT DEFAULT '';
    DECLARE v_modulename             VARCHAR(50) DEFAULT 'centerdb';
    DECLARE v_returnCode             INT;
    DECLARE v_returnMsg              LONGTEXT;
    DECLARE v_is_valid               INT;
    
	DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
    END;
    
    SET returnCode_o = 400;
    SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error');
    SET v_params_body = CONCAT('{"userAccount_i":"',IFNULL(userAccount_i,''),'","password_i":"',IFNULL(password_i,''),'"}');
    SET userAccount_i = TRIM(userAccount_i);
    SET password_i = TRIM(password_i);
    
    SET returnMsg_o = 'check input null data error.';
    IF IFNULL(userAccount_i,'') = '' OR IFNULL(password_i,'') = '' THEN
        SET returnCode_o = 511;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SELECT COUNT(*)
      INTO v_is_valid
      FROM centerdb.accounts
	 WHERE userAccount = userAccount_i
       AND `loginPassword` = MD5(password_i);
       
    SET returnMsg_o = 'Login Failed, Please check username or password.';   
    IF v_is_valid = 0 THEN
        SET returnCode_o = 512;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    UPDATE centerdb.accounts
       SET last_login_time = UTC_TIMESTAMP()
     WHERE userAccount = userAccount_i;
    
    SELECT accountAddress
      FROM centerdb.accounts
     WHERE userAccount = userAccount_i;
    
    SET returnCode_o = 200;
    SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
END
$$
DELIMITER ;
