USE `commons`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = "ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION" */;
DROP PROCEDURE IF EXISTS `drop_allDB`;

DELIMITER $$

CREATE PROCEDURE `drop_allDB`(user_i            INT,
                              OUT returnCode_o  INT,
                              OUT returnMsg_o   LONGTEXT)
ll:BEGIN
    DECLARE   v_procName       VARCHAR(50) DEFAULT 'drop_allDB';
    DECLARE   v_params         LONGTEXT;
    DECLARE   v_returnCode     INT;
    DECLARE   v_returnMsg      LONGTEXT;
    DECLARE   v_database       VARCHAR(200);

    DECLARE   done             INT DEFAULT FALSE;
    DECLARE   v_cursor         CURSOR FOR SELECT schema_name
                                            FROM INFORMATION_SCHEMA.`SCHEMATA`
                                           WHERE SCHEMA_NAME NOT IN ('information_schema', 'performance_schema', 'mysql', 'sys', 'commons');
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT('Workflow commons.drop_allDB command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
    END;

    SET returnCode_o = 400;
    SET returnMsg_o = 'Workflow commons.drop_allDB command Error.';
    SET SESSION group_concat_max_len = 4294967295;

    OPEN v_cursor;
    read_loop: LOOP
       FETCH v_cursor INTO v_database;
       IF done THEN
         LEAVE read_loop;
       END IF;
       SET returnMsg_o = CONCAT('drop database ',v_database,' ..');
       CALL commons.`dynamic_sql_execute`(CONCAT('DROP DATABASE IF EXISTS ',v_database),v_returnCode, v_returnMsg);
    END LOOP;
    CLOSE v_cursor;

    DROP DATABASE IF EXISTS commons;
    
    SET returnCode_o = 200;
    SET returnMsg_o = 'OK';

END$$

DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;

