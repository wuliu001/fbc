USE `user_center`;

/*Procedure structure for Procedure `change_pw` */;

DROP PROCEDURE IF EXISTS `change_pw`;

DELIMITER $$
CREATE DEFINER=`dba`@`%` PROCEDURE `change_pw`(
                              id_i                  VARCHAR(50),
                              body_i                TEXT,
                              OUT returnCode_o      INT,
							  OUT returnMsg_o       LONGTEXT)
ll:BEGIN
    DECLARE v_procname               VARCHAR(100) DEFAULT 'user_center.change_pw';
    DECLARE v_modulename             VARCHAR(50) DEFAULT 'userCenterManagement';
    DECLARE v_params_body            LONGTEXT DEFAULT '';
    DECLARE v_returnCode             INT;
    DECLARE v_returnMsg              LONGTEXT;
    DECLARE v_org_pw                 VARCHAR(100);
    DECLARE v_new_pw                 VARCHAR(100);
    DECLARE v_is_valid               INT;
    
	DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
    END;
    
    SET returnCode_o = 400;
    SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error');
    SET v_params_body = CONCAT('{"id_i":"',IFNULL(id_i,''),'"}');
    SET id_i = TRIM(id_i);
    SET body_i = TRIM(body_i);
    
    SET returnMsg_o = 'check input null data error.';
    IF IFNULL(id_i,'') = '' OR IFNULL(body_i,'') = '' THEN
        SET returnCode_o = 511;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'body format invalid.';
    IF IFNULL(JSON_VALID(body_i),0) = 0 THEN
        SET returnCode_o = 512;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SELECT TRIM(BOTH '"' FROM body_i->"$.original_pw"), 
           TRIM(BOTH '"' FROM body_i->"$.new_pw")
	  INTO v_org_pw, v_new_pw;
    
    SET returnMsg_o = 'Body format is mismatch for change password.';
    IF IFNULL(v_org_pw,'') = '' OR IFNULL(v_new_pw,'') = '' THEN
        SET returnCode_o = 513;
        LEAVE ll;
    END IF;
    
    SELECT COUNT(*)
      INTO v_is_valid
      FROM user_center.public_info
	 WHERE id = id_i
       AND `password` = MD5(v_org_pw);
	
    SET returnMsg_o = 'Original password mistached.';
    IF v_is_valid = 0 THEN
        SET returnCode_o = 514;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
	END IF;
    
    UPDATE user_center.public_info
       SET `password` = MD5(v_new_pw),
	       last_update_time = UTC_TIMESTAMP()
	 WHERE id = id_i;
	
    SET returnCode_o = 200;
	SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
END
$$
DELIMITER ;
