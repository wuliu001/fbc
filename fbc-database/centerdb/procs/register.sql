USE `centerdb`;

/*Procedure structure for Procedure `register` */;

DROP PROCEDURE IF EXISTS `register`;

DELIMITER $$
CREATE DEFINER=`dba`@`%` PROCEDURE `register`(accountAddress_i      VARCHAR(256),
                                              register_ip_address_i VARCHAR(255),
                                              body_i                LONGTEXT,
                                              OUT returnCode_o      INT,
                                              OUT returnMsg_o       LONGTEXT )
ll:BEGIN
    DECLARE v_procname               VARCHAR(100) DEFAULT 'centerdb.register';
    DECLARE v_modulename             VARCHAR(50) DEFAULT 'centerdb';
    DECLARE v_params_body            LONGTEXT DEFAULT '';
    DECLARE v_returnCode             INT;
    DECLARE v_returnMsg              LONGTEXT;
    DECLARE v_userReg_sys_lock       INT;
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
    
	DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        SET v_userReg_sys_lock = RELEASE_LOCK('centerdb_register');
    END;
    
    SET returnCode_o = 400;
    SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error');
    SET v_params_body = CONCAT('{"accountAddress_i":"',IFNULL(accountAddress_i,''),'","register_ip_address_i":"',IFNULL(register_ip_address_i,''),'"}');
    SET body_i = TRIM(body_i);
    SET accountAddress_i = TRIM(accountAddress_i);
    SET register_ip_address_i = TRIM(register_ip_address_i);
    
    SET returnMsg_o = 'get system lock fail.';
    SET v_userReg_sys_lock = GET_LOCK('centerdb_register',180);

    IF v_userReg_sys_lock <> 1 THEN
        SET returnCode_o = 511;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'check input data validation error.';
    IF IFNULL(JSON_VALID(body_i),0) = 0 OR IFNULL(body_i,'') = '' OR IFNULL(accountAddress_i,'') = '' OR IFNULL(register_ip_address_i,'') = '' THEN
        SET returnCode_o = 512;
        SET v_userReg_sys_lock = RELEASE_LOCK('centerdb_register');
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    SELECT TRIM(BOTH '"' FROM body_i->"$.userAccount"),
           TRIM(BOTH '"' FROM body_i->"$.loginPassword"),
           TRIM(BOTH '"' FROM body_i->"$.corporationName"),
           TRIM(BOTH '"' FROM body_i->"$.owner"),
           TRIM(BOTH '"' FROM body_i->"$.address"),
           TRIM(BOTH '"' FROM body_i->"$.companyRegisterDate"),
           TRIM(BOTH '"' FROM body_i->"$.registeredCapital"),
           TRIM(BOTH '"' FROM body_i->"$.annualIncome"),
           TRIM(BOTH '"' FROM body_i->"$.telNum"),
           TRIM(BOTH '"' FROM body_i->"$.email")
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

    IF IFNULL(v_username,'') = '' OR IFNULL(v_password,'') = '' OR IFNULL(v_corporation_name,'') = '' OR IFNULL(v_owner,'') = ''
       OR IFNULL(v_address,'') = '' OR IFNULL(v_company_register_date,'') = '' OR v_registered_capital IS NULL
       OR v_annual_income IS NULL OR IFNULL(v_tel_num,'') = '' OR IFNULL(v_email,'') = '' THEN
        SET returnCode_o = 512;
        SET returnMsg_o = 'Body format is mismatch for register.';
        SET v_userReg_sys_lock = RELEASE_LOCK('centerdb_register');
        LEAVE ll;
    END IF;
    
    SELECT COUNT(*)
      INTO v_checker
      FROM centerdb.accounts
	 WHERE userAccount = v_username;
    IF v_checker > 0 THEN
        SET returnCode_o = 513;
        SET returnMsg_o = 'This user account exist in this node, please change another user account and try again.';
        SET v_userReg_sys_lock = RELEASE_LOCK('centerdb_register');
        LEAVE ll;
    END IF;
    
    INSERT INTO `centerdb`.`accounts`(`accountAddress`, `userAccount`, `loginPassword`, `corporationName`, `owner`, `address`, `companyRegisterDate`, `registeredCapital`, `annualIncome`, `telNum`, `email`, `create_time`, `last_update_time`, `last_login_time`,register_ip_address)
         VALUES (accountAddress_i, v_username, MD5(v_password), v_corporation_name, v_owner, v_address, v_company_register_date, v_registered_capital, v_annual_income, v_tel_num, v_email, UTC_TIMESTAMP(), UTC_TIMESTAMP(), UTC_TIMESTAMP(),register_ip_address_i);
    
    SET v_userReg_sys_lock = RELEASE_LOCK('centerdb_register');
    
    SET returnCode_o = 200;
	SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
END
$$
DELIMITER ;
