USE `commons`;

/*Procedure structure for Procedure `perf_statis.begin` */;

DROP PROCEDURE IF EXISTS `perf_statis.begin`;

DELIMITER $$
CREATE DEFINER=`dba`@`%` PROCEDURE `perf_statis.begin`(
    proc_name_i      VARCHAR(100),
    OUT statis_begin_time_o DATETIME(3),
    OUT returnCode_o INT,
    OUT returnMsg_o  TEXT)
ll:BEGIN
    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        SET returnCode_o = 400;
        SET returnMsg_o = 'perf_statis.begin Error.';
        SET @statis_begin_failed = 1;
    END;
    
    SET statis_begin_time_o = UTC_TIMESTAMP(3);
    SET proc_name_i = TRIM(proc_name_i);
    
    SET returnCode_o = 200;
    SET returnMsg_o = 'ok';
    SET @statis_begin_failed = 0;
END
$$
DELIMITER ;
