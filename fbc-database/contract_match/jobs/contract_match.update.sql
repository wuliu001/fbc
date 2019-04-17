USE `contract_match`;

/*Event structure for Event `contract_match.update` */;

DROP EVENT IF EXISTS `contract_match.update`;

DELIMITER $$

CREATE EVENT `contract_match.update` ON SCHEDULE EVERY 1 MINUTE STARTS '2016-01-01 00:00:00' ON COMPLETION PRESERVE ENABLE DO
ll:BEGIN
    DECLARE imp_lock           INT;
    DECLARE v_sys_table_lock   INT;
    DECLARE v_procname         VARCHAR(50) DEFAULT 'contract_match.update.job';
    DECLARE v_modulename       VARCHAR(50) DEFAULT 'contract_match';
    DECLARE v_body             LONGTEXT DEFAULT NULL;
    DECLARE v_params_body      LONGTEXT DEFAULT NULL;
    DECLARE v_curMsg           LONGTEXT;
    DECLARE v_returnCode       INT;
    DECLARE v_returnMsg        LONGTEXT;

    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        SET imp_lock = RELEASE_LOCK('contract_match.update');
        SET v_returnMsg = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', v_curMsg, ' | ', IFNULL(v_returnMsg,''));
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,v_curMsg,v_returnCode,v_returnMsg);
    END;

    SET v_curMsg = 'fail to get system lock.';
    SET imp_lock = GET_LOCK('contract_match.update',1);
    IF imp_lock <> 1 THEN
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,v_curMsg,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    CALL contract_match.`contract_match.update`(v_returnCode,v_returnMsg);

    SET v_curMsg = 'release lock.';
    SET imp_lock = RELEASE_LOCK('contract_match.update');

END
$$
DELIMITER ;
