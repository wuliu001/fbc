USE `commons`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = "ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION" */;
DROP PROCEDURE IF EXISTS `redeploy_commons`;

DELIMITER $$

CREATE PROCEDURE `redeploy_commons`(user_i            INT,
                                    OUT allDrop_o     TINYINT,
                                    OUT returnCode_o  INT,
                                    OUT returnMsg_o   LONGTEXT)
ll:BEGIN
    DECLARE   v_procName            VARCHAR(50) DEFAULT 'redeploy_commons';
    DECLARE   v_params              LONGTEXT;
    DECLARE   v_returnCode          INT;
    DECLARE   v_returnMsg           LONGTEXT;

    DECLARE   v_last_update_time    DATETIME;
    DECLARE   v_redeploy_interval   INT UNSIGNED DEFAULT 0;
    DECLARE   v_currtime            DATETIME DEFAULT UTC_TIMESTAMP();
    DECLARE   v_last_time           DATETIME DEFAULT UTC_TIMESTAMP();

    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        
        SET returnCode_o = 400;
        SET allDrop_o = 0;
        SET returnMsg_o = CONCAT('Workflow commons.redeploy_commons command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
    END;

    SET allDrop_o = 0;
    SET returnCode_o = 400;
    SET returnMsg_o = 'Workflow commons.redeploy_commons command Error.';
    SET SESSION group_concat_max_len = 4294967295;
    
    SELECT MAX(last_update_time) 
      INTO v_last_update_time
      FROM last_deploy_time;

    IF IFNULL(v_last_update_time,'')='' THEN
       SET v_last_update_time = DATE_ADD(v_currtime, INTERVAL -1 HOUR);
    END IF;

    SELECT CAST(IFNULL(MAX(`value`),'0') AS UNSIGNED)
      INTO v_redeploy_interval
      FROM config
     WHERE code='redeploy_interval';

    SET returnMsg_o = CONCAT('compute datetime which for dropping all databases. v_last_update_time:',v_last_update_time,', v_redeploy_interval: ',v_redeploy_interval);
    SET v_last_time = DATE_ADD(v_last_update_time, INTERVAL v_redeploy_interval SECOND);

    IF v_last_time < v_currtime THEN
        SET returnMsg_o = 'drop all databases...';
        CALL commons.`drop_allDB`(0,v_returnCode,v_returnMsg);
        IF v_returnCode = 200 THEN
           SET allDrop_o=1;
        ELSE
           SET returnMsg_o = v_returnMsg;
           SET allDrop_o=0;
           LEAVE ll;
        END IF;
    ELSE
        SET allDrop_o=0;
    END IF;
    
    SET returnCode_o = 200;
    SET returnMsg_o = 'OK';

END$$

DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;

