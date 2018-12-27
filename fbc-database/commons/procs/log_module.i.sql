USE `commons`;

/*Procedure structure for Procedure `log_module.i` */;

DROP PROCEDURE IF EXISTS `log_module.i`;

DELIMITER $$
CREATE DEFINER=`dba`@`%` PROCEDURE `log_module.i`(user_i            INT,
                         module_i          VARCHAR(50),
                         procName_i        VARCHAR(50),
                         params_i          LONGTEXT,
                         body_i            LONGTEXT,
                         returnMeg_i       LONGTEXT,
                         OUT returnCode_o  INT,
                         OUT returnMsg_o   LONGTEXT)
ll:BEGIN
    DECLARE v_module         VARCHAR(50);
    DECLARE v_procName       VARCHAR(50);
    DECLARE v_params         LONGTEXT;
    DECLARE v_body           LONGTEXT;
    DECLARE v_returnMeg      LONGTEXT;
    DECLARE v_code  INT;
    DECLARE v_msg   LONGTEXT;

    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        SET returnCode_o = 400;
        SET returnMsg_o = 'Insert Log Error.'; 
    END;
    
    SET returnCode_o = 400;
    SET returnMsg_o = 'Insert Log Error.';
        
    SET v_module = IFNULL(TRIM(module_i),'');
    SET v_procName = IFNULL(TRIM(procName_i),'');
    SET v_params = IFNULL(TRIM(params_i),'');
    SET v_body = IFNULL(TRIM(body_i),'');
    SET v_returnMeg = IFNULL(TRIM(returnMeg_i),'');

    IF NOT `commons`.`checkPermit`(user_i,'ADMIN') THEN
        SET returnMsg_o = 'Not Enough Permissions.';
        LEAVE ll;
    END IF;
    
    IF v_module = '' THEN
        SET returnMsg_o = 'module is null.';
        LEAVE ll;
    END IF;

    IF v_procName = '' THEN
        SET returnMsg_o = 'proc name is null.';
        LEAVE ll;
    END IF;
    
    IF v_returnMeg = '' THEN
        SET returnMsg_o = 'return message is null.';
        LEAVE ll;
    END IF;
    
    IF JSON_VALID(v_params) <> 1 THEN
        CALL commons.`log_module._insert`(user_i,2,v_module,v_procName,'{}',v_body,v_returnMeg,v_code,v_msg);
    ELSE
        CALL commons.`log_module._insert`(user_i,2,v_module,v_procName,v_params,v_body,v_returnMeg,v_code,v_msg);
    END IF;

    IF v_code <> 200 THEN
        SET returnCode_o = v_code;
        SET returnMsg_o = v_msg;
        LEAVE ll;
    END IF;
    
    SET returnCode_o = 200;
    SET returnMsg_o = 'Insert Log Success';
END
$$
DELIMITER ;
