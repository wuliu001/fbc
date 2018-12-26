USE `commons`;

/*Procedure structure for Procedure `perf_statis.end` */;

DROP PROCEDURE IF EXISTS `perf_statis.end`;

DELIMITER $$
CREATE DEFINER=`dba`@`%` PROCEDURE `perf_statis.end`(
    proc_name_i      VARCHAR(100),
    statis_begin_time_i     DATETIME(3),
    OUT returnCode_o INT,
    OUT returnMsg_o  TEXT)
ll:BEGIN
    DECLARE v_duration INT DEFAULT 0;
    DECLARE v_proc_elapsed_time INT;
    DECLARE v_end_time DATETIME(3) DEFAULT UTC_TIMESTAMP(3);
    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        SET returnCode_o = 400;
        SET returnMsg_o = 'perf_statis.end Error.';
    END;
    
    SET proc_name_i = TRIM(proc_name_i); 
    SET v_duration = (UNIX_TIMESTAMP(v_end_time) - UNIX_TIMESTAMP(statis_begin_time_i))*1000;
    
    IF @statis_begin_failed = 0 THEN
        SELECT IFNULL(MAX(CAST(`value` AS SIGNED)),0) 
            INTO v_proc_elapsed_time 
        FROM commons.`config` 
        WHERE `code` = 'procedure_elapsed_time';
        IF v_duration > v_proc_elapsed_time AND v_proc_elapsed_time>0 THEN
            INSERT INTO commons.`performance_statistic`(proc_name,start_time,end_time,duration) VALUES(proc_name_i,statis_begin_time_i, v_end_time,v_duration);
        END IF;
    END IF;

    SET returnCode_o = 200;
    SET returnMsg_o = 'ok';
END
$$
DELIMITER ;
