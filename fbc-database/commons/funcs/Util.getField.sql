USE `commons`;

/*Function structure for Function `Util.getField` */;

DROP FUNCTION IF EXISTS `Util.getField`;

DELIMITER $$
CREATE DEFINER=`dba`@`%` FUNCTION `Util.getField`(in_string LONGTEXT, in_separator TEXT, in_index INT) RETURNS TEXT
BEGIN

    DECLARE v_tmp1 LONGTEXT;
    DECLARE v_tmp2 LONGTEXT;
    
    IF (in_index < 1) THEN
        RETURN NULL;
    END IF;
        
    SET v_tmp1 = SUBSTRING_INDEX(in_string, in_separator, in_index);
    SET v_tmp2 = SUBSTRING_INDEX(in_string, in_separator, in_index - 1);
    IF v_tmp1 = v_tmp2 THEN
        RETURN NULL;
    END IF;

	RETURN SUBSTRING_INDEX(SUBSTRING_INDEX(in_string, in_separator, in_index), in_separator, -1);
END
$$
DELIMITER ;
