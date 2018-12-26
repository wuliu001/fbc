USE `users`;

/*Procedure structure for Procedure `change_pw` */;

DROP PROCEDURE IF EXISTS `change_pw`;

DELIMITER $$
CREATE DEFINER=`dba`@`%` PROCEDURE `change_pw`(user_i                INT,
                              username_i            VARCHAR(50),
                              body_i                TEXT,
                              OUT returnCode_o      INT,
							  OUT returnMsg_o       LONGTEXT)
ll:BEGIN
    DECLARE v_procname               VARCHAR(100) DEFAULT 'users.login';
    DECLARE v_params_body            LONGTEXT DEFAULT '';
    DECLARE v_returnCode             INT;
    DECLARE v_returnMsg              TEXT;
    DECLARE v_json                   INT;
    DECLARE v_org_pw                 VARCHAR(100);
    DECLARE v_new_pw                 VARCHAR(100);
    DECLARE v_is_valid               INT;
    
	DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT('User Manager Change Password Command Error: ',IFNULL(returnMsg_o,''),' | ',v_returnMsg);
        #CALL `commons`.`log_module.e`(0,'debugData',v_procname,v_params_body,NULL,returnMsg_o, v_returnCode, v_returnMsg);
    END;
    
    SELECT JSON_VALID(body_i)
      INTO v_json;
    
    IF v_json = 0 THEN
        SET returnCode_o = 511;
        SET returnMsg_o = 'Body is invalid JSON format.';
        LEAVE ll;
    END IF;
    
    SELECT TRIM(BOTH '"' FROM body_i->"$.original_pw"), TRIM(BOTH '"' FROM body_i->"$.new_pw")
	  INTO v_org_pw, v_new_pw;
    
    IF v_org_pw IS NULL OR v_new_pw IS NULL THEN
        SET returnCode_o = 512;
        SET returnMsg_o = 'Body format is mismatch for change password.';
        LEAVE ll;
    END IF;
    
    SELECT COUNT(*)
      INTO v_is_valid
      FROM users.public_info
	 WHERE username = username_i
       AND `password` = MD5(v_org_pw);
	
    IF v_is_valid = 0 THEN
        SET returnCode_o = 513;
        SET returnMsg_o = 'Original password mistached.';
        LEAVE ll;
	END IF;
    
    UPDATE users.public_info
       SET `password` = MD5(v_new_pw),
	       last_update_time = UTC_TIMESTAMP()
	 WHERE username = username_i;
	
    SET returnCode_o = 200;
	SET returnMsg_o = 'OK';
END
$$
DELIMITER ;
