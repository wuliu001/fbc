USE `centerdb`;

/*Procedure structure for Procedure `account_info.get` */;

DROP PROCEDURE IF EXISTS `account_info.get`;

DELIMITER $$
CREATE DEFINER=`dba`@`%` PROCEDURE `account_info.get`(
						   accountAddress_i      VARCHAR(256),
						   OUT returnCode_o      INT,
						   OUT returnMsg_o       LONGTEXT)
ll:BEGIN
    DECLARE v_procname               VARCHAR(100) DEFAULT 'centerdb.account_info.get';
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
    SET v_params_body = CONCAT('{"accountAddress_i":"',IFNULL(accountAddress_i,''),'"}');
    SET accountAddress_i = TRIM(accountAddress_i);
    
    SET returnMsg_o = 'check input null data error.';
    IF IFNULL(accountAddress_i,'') = '' THEN
        SET returnCode_o = 511;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SELECT COUNT(*)
      INTO v_is_valid
      FROM centerdb.accounts
	 WHERE accountAddress = accountAddress_i;
       
    SET returnMsg_o = 'account_info.get Failed, Please check accountAddress.';   
    IF v_is_valid = 0 THEN
        SET returnCode_o = 512;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SELECT registeredCapital,telNum,annualIncome,companyRegisterDate,`owner`,address,corporationName,userAccount,email
      FROM centerdb.accounts
     WHERE accountAddress = accountAddress_i;
    
    SET returnCode_o = 200;
    SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
END
$$
DELIMITER ;
