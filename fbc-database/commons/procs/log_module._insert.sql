USE `commons`;

/*Procedure structure for Procedure `log_module._insert` */;

DROP PROCEDURE IF EXISTS `log_module._insert`;

DELIMITER $$
CREATE DEFINER=`dba`@`%` PROCEDURE `log_module._insert`(user_i           INT,
                               level_i          INT,
                               module_i         VARCHAR(50),
                               procName_i       VARCHAR(50),
                               params_i         LONGTEXT,
                               body_i           LONGTEXT,
                               returnMeg_i      LONGTEXT,
                               OUT returnCode_o INT,
                               OUT returnMsg_o  LONGTEXT)
BEGIN
    DECLARE v_type VARCHAR(4);
    DECLARE v_log_level INT DEFAULT 1;

    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        SET returnCode_o = 400;
        SET returnMsg_o = 'Rec log failed.';
    END;
    
    SET returnCode_o = 400;
    SET returnMsg_o = 'Rec log failed.';

    SELECT IFNULL(MAX(`value`),1) INTO v_log_level FROM commons.`config` WHERE `code` = module_i AND `description` = 'log_level';
    
    IF level_i = 1 AND v_log_level >= 1 THEN
        SET v_type = 'E';
    ELSEIF level_i = 2 AND v_log_level >= 2 THEN
        SET v_type = 'I';
    ELSEIF level_i = 3 AND v_log_level >= 3 THEN
        SET v_type = 'D';
    ELSE
        SET v_type = NULL;
    END IF;
    
    IF v_type IS NOT NULL AND TRIM(v_type) <> '' THEN
        INSERT INTO commons.`logs_module`(`type`,user_id,module,proc_name,params,body,return_message,log_time)
            VALUES (v_type,user_i,module_i,procName_i,params_i,body_i,returnMeg_i,UTC_TIMESTAMP());
    END IF;

    SET returnCode_o = 200;
    SET returnMsg_o = 'Rec Log Success';
END
$$
DELIMITER ;
