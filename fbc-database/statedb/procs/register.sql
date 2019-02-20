USE `statedb`;

/*Procedure structure for Procedure `register` */;

DROP PROCEDURE IF EXISTS `register`;

DELIMITER $$
CREATE DEFINER=`dba`@`%` PROCEDURE `register`(accountAddress_i      VARCHAR(256),
                                              body_i                LONGTEXT,
                                              OUT returnCode_o      INT,
                                              OUT returnMsg_o       LONGTEXT )
ll:BEGIN
    DECLARE v_procname                VARCHAR(100) DEFAULT 'statedb.register';
    DECLARE v_modulename              VARCHAR(50) DEFAULT 'statedb';
    DECLARE v_params_body             LONGTEXT DEFAULT '';
    DECLARE v_returnCode              INT;
    DECLARE v_returnMsg               LONGTEXT;
    DECLARE v_userReg_sys_lock        INT;
    DECLARE v_publicKey               TEXT;
    DECLARE v_creditRating            FLOAT;
    DECLARE v_balance                 FLOAT;
    DECLARE v_smartContractPrice      FLOAT;
    DECLARE v_minSmartContractDeposit FLOAT;
    DECLARE v_nonce                   FLOAT;
    DECLARE v_checker                 INT;
    
	DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        SET v_userReg_sys_lock = RELEASE_LOCK('statedb_register');
    END;
    
    SET returnCode_o = 400;
    SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error');
    SET v_params_body = CONCAT('{}');
    SET body_i = TRIM(body_i);
    SET accountAddress_i = TRIM(accountAddress_i);
    
    SET returnMsg_o = 'get system lock fail.';
    SET v_userReg_sys_lock = GET_LOCK('statedb_register',180);

    IF v_userReg_sys_lock <> 1 THEN
        SET returnCode_o = 511;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'check input data validation error.';
    IF IFNULL(JSON_VALID(body_i),0) = 0 OR IFNULL(body_i,'') = '' OR IFNULL(accountAddress_i,'') = '' THEN
        SET returnCode_o = 512;
        SET v_userReg_sys_lock = RELEASE_LOCK('statedb_register');
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    SELECT TRIM(BOTH '"' FROM body_i->"$.publicKey"),
           TRIM(BOTH '"' FROM body_i->"$.creditRating"),
           TRIM(BOTH '"' FROM body_i->"$.balance"),
           TRIM(BOTH '"' FROM body_i->"$.smartContractPrice"),
           TRIM(BOTH '"' FROM body_i->"$.minSmartContractDeposit"),
           TRIM(BOTH '"' FROM body_i->"$.nonce")
	  INTO v_publicKey,
           v_creditRating,
           v_balance,
           v_smartContractPrice,
           v_minSmartContractDeposit,
           v_nonce;

    IF IFNULL(v_publicKey,'') = '' OR v_creditRating IS NULL OR v_balance IS NULL OR v_smartContractPrice IS NULL
       OR v_minSmartContractDeposit IS NULL OR v_nonce IS NULL  THEN
        SET returnCode_o = 512;
        SET returnMsg_o = 'Body format is mismatch for register.';
        SET v_userReg_sys_lock = RELEASE_LOCK('statedb_register');
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SELECT COUNT(*)
      INTO v_checker
      FROM statedb.state_object
	 WHERE accountAddress = accountAddress_i;
    IF v_checker > 0 THEN
        SET returnCode_o = 513;
        SET returnMsg_o = 'This user account exist in this node, please change another user account and try again.';
        SET v_userReg_sys_lock = RELEASE_LOCK('statedb_register');
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'This public key format is wrong.';
    SELECT v_publicKey REGEXP '^-----BEGIN RSA PUBLIC KEY-----' AND v_publicKey REGEXP '-----END RSA PUBLIC KEY-----$'
      INTO v_checker;
    IF v_checker = 0 THEN
        SET returnCode_o = 514;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
        SET v_userReg_sys_lock = RELEASE_LOCK('statedb_register');
        LEAVE ll;
    END IF;
    
    INSERT INTO `statedb`.`state_object`(accountAddress, publicKey, creditRating, balance, smartContractPrice, minSmartContractDeposit, nonce)
         VALUES (accountAddress_i, v_publicKey, v_creditRating, v_balance, v_smartContractPrice, v_minSmartContractDeposit, v_nonce);
    
    SET v_userReg_sys_lock = RELEASE_LOCK('statedb_register');
    
    SET returnCode_o = 200;
	SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,body_i,returnMsg_o,v_returnCode,v_returnMsg);
END
$$
DELIMITER ;
