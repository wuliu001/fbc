USE `commons`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = "ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION" */;

/*Procedure structure for Procedure `dynamic_sql_execute` */;

DROP PROCEDURE IF EXISTS `dynamic_sql_execute`;

DELIMITER $$
CREATE PROCEDURE `dynamic_sql_execute`(
    sql_i                 LONGTEXT,
    OUT returnCode_o      INT,
    OUT returnMsg_o       LONGTEXT
)
ll:BEGIN

    SET @sqlstr = TRIM(sql_i);
    PREPARE stmt FROM @sqlstr;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt; 

END$$

DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;
