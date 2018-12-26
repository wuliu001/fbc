USE `commons`;

/*Procedure structure for Procedure `analyze_schema_tables` */;

DROP PROCEDURE IF EXISTS `analyze_schema_tables`;

DELIMITER $$
CREATE DEFINER=`dba`@`%` PROCEDURE `analyze_schema_tables`(
    schema_i               VARCHAR(100),
    exclude_tab_i          LONGTEXT,
    data_cnt_i             BIGINT(20),
    OUT returnCode_o       INT,
    OUT returnMsg_o        TEXT)
ll:BEGIN

    DECLARE v_schema       VARCHAR(100);
    DECLARE v_exclude_tab  LONGTEXT;
    DECLARE done           INT DEFAULT 0;
    DECLARE col_sch        VARCHAR(100);
    DECLARE col_tab        VARCHAR(100);
    DECLARE v_sql          LONGTEXT DEFAULT 'ANALYZE TABLE ';
    DECLARE v_tabs         LONGTEXT DEFAULT '';
    DECLARE v_procname     VARCHAR(100) DEFAULT 'analyze_schema_tables';
    DECLARE v_params_body  LONGTEXT DEFAULT NULL;
    DECLARE v_data_level   BIGINT(20);

    DECLARE cur_tables CURSOR FOR SELECT TABLE_SCHEMA, `TABLE_NAME` FROM information_schema.`TABLES` 
      WHERE TABLE_TYPE='BASE TABLE' AND TABLE_SCHEMA = v_schema;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT('Analyze schema ',v_schema,' failed');
        CALL `commons`.`log.e`(0,v_procname,v_params_body,returnMsg_o,@a,@b);
    END;

    SET returnCode_o = 200;
    SET returnMsg_o = 'OK';
    SET v_params_body = CONCAT('{"schema_i":"',IFNULL(schema_i,''),'","exclude_tab_i":"',IFNULL(exclude_tab_i,''),'"}');

    SET v_schema = TRIM(schema_i);
    SET v_exclude_tab = commons.`stringList.distinct`(commons.`stringList.trim`(exclude_tab_i,','),',');

    SET v_data_level = LENGTH(data_cnt_i) - 1;

    IF data_cnt_i <> POW(10,v_data_level) THEN
        CALL `commons`.`log.i`(0,v_procname,v_params_body,returnMsg_o,@a,@b);
        LEAVE ll;
    END IF;

    OPEN cur_tables;
    REPEAT
        FETCH cur_tables INTO col_sch, col_tab;
        IF NOT done AND commons.`stringLists.is_contain2`(col_tab,v_exclude_tab,',') = 0 THEN
            SET v_tabs = CONCAT(v_tabs,'`',col_sch,'`.`',col_tab,'`,');
        END IF;
    UNTIL done END REPEAT;
    CLOSE cur_tables;

    SET v_tabs = LEFT(v_tabs,LENGTH(v_tabs)-1);
    SET v_sql = CONCAT(v_sql,v_tabs);

    SET @first_sql=v_sql;
    PREPARE stmt FROM @first_sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    CALL `commons`.`log.i`(0,v_procname,v_params_body,returnMsg_o,@a,@b);

END
$$
DELIMITER ;
