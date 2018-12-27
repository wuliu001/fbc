USE `users`;

/*Procedure structure for Procedure `register` */;

DROP PROCEDURE IF EXISTS `register`;

DELIMITER $$
CREATE DEFINER=`dba`@`%` PROCEDURE `register`( user_i                INT,
                              body_i                TEXT,
                              OUT returnCode_o      INT,
							  OUT returnMsg_o       LONGTEXT )
ll:BEGIN
    DECLARE v_procname               VARCHAR(100) DEFAULT 'users.register';
    DECLARE v_params_body            LONGTEXT DEFAULT '';
    DECLARE v_returnCode             INT;
    DECLARE v_returnMsg              TEXT;
    DECLARE v_userReg_sys_lock       INT;
    
    DECLARE v_info                   TEXT;
    DECLARE v_public_key             TEXT;
    DECLARE v_private_key            TEXT;
    
    DECLARE v_json                   INT;
    DECLARE v_username               VARCHAR(50);
    DECLARE v_password               VARCHAR(50);
    DECLARE v_corporation_name       VARCHAR(100);
    DECLARE v_owner                  VARCHAR(50);
    DECLARE v_address                VARCHAR(1600);
    DECLARE v_company_register_date  VARCHAR(50);
    DECLARE v_registered_capital     INT;
    DECLARE v_annual_income          INT;
    DECLARE v_tel_num                VARCHAR(50);
    DECLARE v_email                  VARCHAR(200);
    
    DECLARE v_checker                INT;
    
    DECLARE v_id                     VARCHAR(50);
    
	DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT('User Manager Register Command Error: ',IFNULL(returnMsg_o,''),' | ',v_returnMsg);
        #CALL `commons`.`log_module.e`(0,'debugData',v_procname,v_params_body,NULL,returnMsg_o, v_returnCode, v_returnMsg);
        SET v_userReg_sys_lock = RELEASE_LOCK('user_register');
    END;
    
    # add system lock
    SET returnMsg_o = 'get system lock.';
    SET v_userReg_sys_lock = GET_LOCK('user_register',180);

    IF v_userReg_sys_lock <> 1 THEN
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'Get body.';
    SET v_info = commons.`Util.getField`(body_i, '|$|', 1);
    SET v_public_key = commons.`Util.getField`(body_i, '|$|', 2);
    SET v_private_key = commons.`Util.getField`(body_i, '|$|', 3);
    
    SET returnMsg_o = 'Body validation.';
    SELECT JSON_VALID(v_info)
      INTO v_json;
    
    IF v_json = 0 THEN
        SET returnCode_o = 511;
        SET returnMsg_o = 'Body is invalid JSON format.';
        SET v_userReg_sys_lock = RELEASE_LOCK('user_register');
        LEAVE ll;
    END IF;

    SELECT TRIM(BOTH '"' FROM v_info->"$.userAccount"),
           TRIM(BOTH '"' FROM v_info->"$.password"),
           TRIM(BOTH '"' FROM v_info->"$.corporationName"),
           TRIM(BOTH '"' FROM v_info->"$.owner"),
           TRIM(BOTH '"' FROM v_info->"$.address"),
           TRIM(BOTH '"' FROM v_info->"$.companyRegisterDate"),
           TRIM(BOTH '"' FROM v_info->"$.registeredCapital")+0,
           TRIM(BOTH '"' FROM v_info->"$.annualIncome")+0,
           TRIM(BOTH '"' FROM v_info->"$.telNum"),
           TRIM(BOTH '"' FROM v_info->"$.email")
	  INTO v_username,
           v_password,
           v_corporation_name,
           v_owner,
           v_address,
           v_company_register_date,
           v_registered_capital,
           v_annual_income,
           v_tel_num,
           v_email;
    
    IF v_username IS NULL OR v_password IS NULL OR v_corporation_name IS NULL OR v_owner IS NULL OR v_address IS NULL OR v_company_register_date IS NULL OR v_registered_capital IS NULL OR v_annual_income IS NULL OR v_tel_num IS NULL OR v_email IS NULL THEN
        SET returnCode_o = 512;
        SET returnMsg_o = 'Body format is mismatch for register.';
        SET v_userReg_sys_lock = RELEASE_LOCK('user_register');
        LEAVE ll;
    END IF;
    
    IF TRIM(v_username) = '' THEN
        SET returnCode_o = 513;
        SET returnMsg_o = 'The user account can''t be null, please fill it and try again.';
        SET v_userReg_sys_lock = RELEASE_LOCK('user_register');
        LEAVE ll;
    END IF;
    
    SELECT COUNT(*)
      INTO v_checker
      FROM users.public_info
	 WHERE username = v_username;
	
    IF v_checker > 0 THEN
        SET returnCode_o = 513;
        SET returnMsg_o = 'This user account exist in this node, please change another user account and try again.';
        SET v_userReg_sys_lock = RELEASE_LOCK('user_register');
        LEAVE ll;
    END IF;
    
    IF TRIM(v_corporation_name) = '' THEN
        SET returnCode_o = 513;
        SET returnMsg_o = 'The corporation name filed can''t be null, please fill it and try again.';
        SET v_userReg_sys_lock = RELEASE_LOCK('user_register');
        LEAVE ll;
    END IF;
    
    IF TRIM(v_owner) = '' THEN
        SET returnCode_o = 513;
        SET returnMsg_o = 'The owner filed can''t be null, please fill it and try again.';
        SET v_userReg_sys_lock = RELEASE_LOCK('user_register');
        LEAVE ll;
    END IF;
    
    IF TRIM(v_address) = '' THEN
        SET returnCode_o = 513;
        SET returnMsg_o = 'The address filed can''t be null, please fill it and try again.';
        SET v_userReg_sys_lock = RELEASE_LOCK('user_register');
        LEAVE ll;
    END IF;
    
    IF TRIM(v_company_register_date) = '' THEN
        SET returnCode_o = 513;
        SET returnMsg_o = 'The company register date filed can''t be null, please fill it and try again.';
        SET v_userReg_sys_lock = RELEASE_LOCK('user_register');
        LEAVE ll;
    END IF;
    
    IF TRIM(v_registered_capital) = '' THEN
        SET returnCode_o = 513;
        SET returnMsg_o = 'The registered capital filed can''t be null, please fill it and try again.';
        SET v_userReg_sys_lock = RELEASE_LOCK('user_register');
        LEAVE ll;
    END IF;
    
    IF TRIM(v_annual_income) = '' THEN
        SET returnCode_o = 513;
        SET returnMsg_o = 'The annual income filed can''t be null, please fill it and try again.';
        SET v_userReg_sys_lock = RELEASE_LOCK('user_register');
        LEAVE ll;
    END IF;
    
    IF TRIM(v_tel_num) = '' THEN
        SET returnCode_o = 513;
        SET returnMsg_o = 'The tel num filed can''t be null, please fill it and try again.';
        SET v_userReg_sys_lock = RELEASE_LOCK('user_register');
        LEAVE ll;
    END IF;
    
    IF TRIM(v_email) = '' THEN
        SET returnCode_o = 513;
        SET returnMsg_o = 'The email filed can''t be null, please fill it and try again.';
        SET v_userReg_sys_lock = RELEASE_LOCK('user_register');
        LEAVE ll;
    END IF;
    
    SELECT v_public_key REGEXP '^-----BEGIN PUBLIC KEY-----' AND v_public_key REGEXP '-----END PUBLIC KEY-----$'
      INTO v_checker;
	
    IF v_checker = 0 THEN
        SET returnCode_o = 513;
        SET returnMsg_o = 'This public key format is wrong.';
        SET v_userReg_sys_lock = RELEASE_LOCK('user_register');
        LEAVE ll;
    END IF;
    
    SELECT v_private_key REGEXP '^-----BEGIN RSA PRIVATE KEY-----' AND v_private_key REGEXP '-----END RSA PRIVATE KEY-----$'
      INTO v_checker;
    
    IF v_checker = 0 THEN
        SET returnCode_o = 513;
        SET returnMsg_o = 'This private key format is wrong.';
        SET v_userReg_sys_lock = RELEASE_LOCK('user_register');
        LEAVE ll;
    END IF;
    
    SET v_id = MD5(CONCAT(v_username,v_owner,v_address));
           
    INSERT INTO `users`.`public_info`(`id`, `username`, `password`, `corporation_name`, `owner`, `address`, `company_register_date`, `registered_capital`, `annual_income`, `tel_num`, `email`, `create_time`, `last_update_time`, `last_login_time`)
         VALUES (v_id, v_username, MD5(v_password), v_corporation_name, v_owner, v_address, v_company_register_date, v_registered_capital, v_annual_income, v_tel_num, v_email, UTC_TIMESTAMP(), UTC_TIMESTAMP(), UTC_TIMESTAMP());
    
    INSERT INTO `users`.`public_keys`(`id`, `public_key`, `create_time`, `is_sync`, `last_be_sync_time`)
         VALUES (v_id, v_public_key, UTC_TIMESTAMP(), 0, UTC_TIMESTAMP());
	
    INSERT INTO `users`.`private_keys`(`id`, `private_key`)
         VALUES (v_id, v_private_key);
    
    SET v_userReg_sys_lock = RELEASE_LOCK('user_register');
    
    SELECT v_private_key 'private_key';
    
    SET returnCode_o = 200;
	SET returnMsg_o = 'OK';
END
$$
DELIMITER ;
