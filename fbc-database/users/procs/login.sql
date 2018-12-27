USE `users`;

/*Procedure structure for Procedure `login` */;

DROP PROCEDURE IF EXISTS `login`;

DELIMITER $$
CREATE DEFINER=`dba`@`%` PROCEDURE `login`( user_i                INT,
						   username_i            VARCHAR(50),
                           password_i            VARCHAR(100),
						   OUT returnCode_o      INT,
						   OUT returnMsg_o       LONGTEXT)
BEGIN
    DECLARE v_procname               VARCHAR(100) DEFAULT 'users.login';
    DECLARE v_params_body            LONGTEXT DEFAULT '';
    DECLARE v_returnCode             INT;
    DECLARE v_returnMsg              TEXT;
    DECLARE v_is_valid               INT;
    
	DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT('User Manager Login Command Error: ',IFNULL(returnMsg_o,''),' | ',v_returnMsg);
        #CALL `commons`.`log_module.e`(0,'debugData',v_procname,v_params_body,NULL,returnMsg_o, v_returnCode, v_returnMsg);
    END;
    
    SELECT COUNT(*)
      INTO v_is_valid
      FROM users.public_info
	 WHERE username = username_i
       AND `password` = MD5(password_i);
	
    IF v_is_valid = 0 THEN
        SET returnCode_o = 511;
        SET returnMsg_o = 'Login Failed, Please check username or password.';
    ELSE
        UPDATE users.public_info
           SET last_login_time = UTC_TIMESTAMP()
		 WHERE username = username_i;
		
        SELECT id
          FROM users.public_info
		 WHERE username = username_i;
		
        SET returnCode_o = 200;
        SET returnMsg_o = 'OK';
    END IF;
END
$$
DELIMITER ;
