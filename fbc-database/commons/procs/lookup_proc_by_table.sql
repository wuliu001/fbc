USE `commons`;

/*Procedure structure for Procedure `lookup_proc_by_table` */;

DROP PROCEDURE IF EXISTS `lookup_proc_by_table`;

DELIMITER $$
CREATE DEFINER=`dba`@`%` PROCEDURE `lookup_proc_by_table`(
    table_i               VARCHAR(100),
    OUT returnCode_o      INT,
    OUT returnMsg_o       TEXT)
ll:BEGIN

    DECLARE v_sql          LONGTEXT DEFAULT '';
    DECLARE v_procname     VARCHAR(100) DEFAULT 'lookup_proc_by_table';
    DECLARE v_params_body  LONGTEXT DEFAULT NULL;
    DECLARE v_returnCode   INT;
    DECLARE v_returnMsg    LONGTEXT;

    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT('lookup_proc_by_table in exception error. ' , returnMsg_o , ' ' ,v_returnMsg);
        CALL `commons`.`log.e`(0,v_procname,v_params_body,returnMsg_o,v_returnCode,v_returnMsg);
    END;

    SET returnCode_o = 400;
    SET returnMsg_o = 'lookup_proc_by_table error';
    IF table_i IS NULL THEN
        SET returnCode_o = 400;
        SET returnMsg_o = 'table_name should not be null';
        LEAVE ll;
    END IF;

    SET v_sql = CONCAT('
    SELECT routine_schema,routine_name,routine_type FROM commons.`table_proc_rel` a
     WHERE a.table_name = ''', table_i ,''' AND a.routine_is_deprecated IS NULL');
    
    CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);
    SET returnCode_o = 200;
    SET returnMsg_o = 'OK';

END
$$
DELIMITER ;
