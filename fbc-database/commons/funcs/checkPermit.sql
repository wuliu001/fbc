USE `commons`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = "ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION" */;
DROP function IF EXISTS `checkPermit`;

DELIMITER $$
USE `commons`$$
CREATE FUNCTION `checkPermit`(user_i            INT,
                              roleCode_i        VARCHAR(100)) RETURNS VARCHAR(100)
BEGIN
    RETURN TRUE; 
END$$

DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;
