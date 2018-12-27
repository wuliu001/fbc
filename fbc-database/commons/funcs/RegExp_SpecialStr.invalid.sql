USE `commons`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = "ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION" */;
DROP function IF EXISTS `RegExp_SpecialStr.invalid`;

DELIMITER $$
USE `commons`$$
CREATE FUNCTION `RegExp_SpecialStr.invalid`(string_i LONGTEXT,keepstr_i LONGTEXT) RETURNS LONGTEXT
BEGIN
    
    IF IFNULL(string_i,'') = ''  THEN
        RETURN IFNULL(string_i,'');
    END IF;
    
    SET keepstr_i = IFNULL(keepstr_i,'');

    IF INSTR(string_i,'\\') > 0  AND INSTR(keepstr_i,'\\') = 0  THEN
        SET string_i = REPLACE(string_i,'\\','\\\\');
    END IF; 

    IF INSTR(string_i,'*') > 0 AND INSTR(keepstr_i,'*') = 0  THEN
        SET string_i = REPLACE(string_i,'*','\\*');
    END IF;

    IF INSTR(string_i,'.') > 0 AND INSTR(keepstr_i,'.') = 0 THEN
        SET string_i = REPLACE(string_i,'.','\\.');
    END IF;        
    
    IF INSTR(string_i,'?') > 0 AND INSTR(keepstr_i,'?') = 0 THEN
        SET string_i = REPLACE(string_i,'?','\\?');
    END IF;

    IF INSTR(string_i,'+') > 0 AND INSTR(keepstr_i,'+') = 0 THEN
        SET string_i = REPLACE(string_i,'+','\\+');
    END IF;    
    
    IF INSTR(string_i,'$') > 0 AND INSTR(keepstr_i,'$') = 0 THEN
        SET string_i = REPLACE(string_i,'$','\\$');
    END IF;

    IF INSTR(string_i,'^') > 0 AND INSTR(keepstr_i,'^') = 0 THEN
        SET string_i = REPLACE(string_i,'^','\\^');
    END IF;
    
    IF INSTR(string_i,'[') > 0 AND INSTR(keepstr_i,'[') = 0 THEN
        SET string_i = REPLACE(string_i,'[','\\[');
    END IF;        
    
    IF INSTR(string_i,']') > 0 AND INSTR(keepstr_i,']') = 0 THEN
        SET string_i = REPLACE(string_i,']','\\]');
    END IF;

    IF INSTR(string_i,'(') > 0 AND INSTR(keepstr_i,'(') = 0 THEN
        SET string_i = REPLACE(string_i,'(','\\(');
    END IF;    
    
    IF INSTR(string_i,')') > 0 AND INSTR(keepstr_i,')') = 0 THEN
        SET string_i = REPLACE(string_i,')','\\)');
    END IF;    

    IF INSTR(string_i,'{') > 0 AND INSTR(keepstr_i,'{') = 0 THEN
        SET string_i = REPLACE(string_i,'{','\\{');
    END IF;    
    
    IF INSTR(string_i,'}') > 0  AND INSTR(keepstr_i,'}') = 0 THEN
        SET string_i = REPLACE(string_i,'}','\\}');
    END IF; 

    IF INSTR(string_i,'|') > 0 AND INSTR(keepstr_i,'|') = 0 THEN
        SET string_i = REPLACE(string_i,'|','\\|');
    END IF; 
    
    IF INSTR(string_i,'/') > 0 AND INSTR(keepstr_i,'/') = 0 THEN
        SET string_i = REPLACE(string_i,'/','\\/');
    END IF;     
    
    RETURN IFNULL(string_i,''); 
END$$

DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;