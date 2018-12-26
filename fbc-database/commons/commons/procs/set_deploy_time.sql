USE `commons`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = "ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION" */;
DROP PROCEDURE IF EXISTS `set_deploy_time`;

DELIMITER $$

CREATE PROCEDURE `set_deploy_time`(user_i            INT,
                                    OUT returnCode_o  INT,
                                    OUT returnMsg_o   LONGTEXT)
ll:BEGIN
    DECLARE   v_procName            VARCHAR(50) DEFAULT 'set_deploy_time';
    DECLARE   v_params              LONGTEXT;
    DECLARE   v_returnCode          INT;
    DECLARE   v_returnMsg           LONGTEXT;

    DECLARE   v_currtime            DATETIME DEFAULT UTC_TIMESTAMP();

    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT('Workflow commons.set_deploy_time command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
    END;

    SET returnCode_o = 400;
    SET returnMsg_o = 'Workflow commons.set_deploy_time command Error.';
    SET SESSION group_concat_max_len = 4294967295;
    
    UPDATE last_deploy_time SET last_update_time=v_currtime;
    IF ROW_COUNT()=0 THEN
       INSERT INTO last_deploy_time(last_update_time) VALUES(v_currtime);
    END IF;

    SET returnCode_o = 200;
    SET returnMsg_o = 'OK';

END$$

DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;

