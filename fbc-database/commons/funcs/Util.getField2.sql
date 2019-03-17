USE `commons`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = "ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION" */;


DROP FUNCTION IF EXISTS `Util.getField2`;

DELIMITER $$
CREATE FUNCTION `Util.getField2`(in_string LONGTEXT, in_separator TEXT, in_index INT) RETURNS TEXT
BEGIN
        IF (in_index < 1) THEN
            RETURN NULL;
        END IF;

        RETURN SUBSTRING_INDEX(SUBSTRING_INDEX(in_string, in_separator, in_index), in_separator, -1);
    END
$$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;
