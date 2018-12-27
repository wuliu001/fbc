USE `commons`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = "ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION" */;

/*Function structure for Function `stringList.trim` */;

DROP FUNCTION IF EXISTS `stringList.trim`;

DELIMITER $$

CREATE FUNCTION `stringList.trim`(string_i LONGTEXT,separator_i VARCHAR(200)) RETURNS LONGTEXT
BEGIN

    DECLARE v_string    LONGTEXT;
    DECLARE v_separator TEXT;

    IF IFNULL(LENGTH(string_i),0) = 0 OR IFNULL(LENGTH(separator_i),0) = 0 THEN
        RETURN IFNULL(string_i,'');
    END IF ;
 
    SET v_string = IFNULL(TRIM(BOTH separator_i FROM string_i),'');
    SET v_separator = commons.`RegExp_SpecialStr.invalid`(separator_i,'');

    WHILE BINARY v_string REGEXP CONCAT(v_separator,v_separator,'+') DO
        SET v_string = REPLACE(v_string,CONCAT(separator_i,separator_i),separator_i); 
    END WHILE;
    
    RETURN IFNULL(v_string,'');
    
END$$

DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;