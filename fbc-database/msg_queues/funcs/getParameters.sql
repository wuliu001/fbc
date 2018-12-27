USE `msg_queues`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Function structure for Function `getParameters` */;

DROP FUNCTION IF EXISTS `getParameters`;

DELIMITER $$
CREATE FUNCTION `getParameters`(queue_type_i VARCHAR(50) ,queue_step_i TINYINT(4),queues_i  LONGTEXT) RETURNS LONGTEXT
BEGIN
    DECLARE col_vname    VARCHAR(50);
    DECLARE col_pos      VARCHAR(100);
    DECLARE col_is_rep   INT;
    DECLARE v_pos_value  LONGTEXT DEFAULT '';
    DECLARE v_start      INT(11);
    DECLARE v_length     INT(11);
    DECLARE v_final      LONGTEXT DEFAULT '';
    DECLARE v_pos_start  INT(11);

    DECLARE done         INT DEFAULT FALSE;
    DECLARE cur CURSOR FOR SELECT var_name, queue_val_pos, is_replace_resource
                             FROM msg_queues.service_parameters
                            WHERE queue_type = queue_type_i
                              AND queue_step = queue_step_i
                              AND var_name <> 'body';
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    IF IFNULL(queue_type_i , '') = '' OR IFNULL(queues_i,'') = '' OR queue_step_i IS NULL THEN
        RETURN '';
    END IF;

    OPEN cur;
    REPEAT
        FETCH cur INTO col_vname, col_pos, col_is_rep;
        IF NOT done THEN
            SET v_start = 1;
            SET v_pos_value = '';
            SET v_length = LENGTH(col_pos) - LENGTH(REPLACE(col_pos,',','')) + 1;
            WHILE v_length >= v_start DO
                SET v_pos_start = IFNULL(commons.`Util.getField`(col_pos, ',', v_start),0);
                SET v_pos_value = CONCAT(v_pos_value,'|$|',IFNULL(commons.`Util.getField`(queues_i, '|$|', v_pos_start),''));
                SET v_start = v_start + 1;
            END WHILE;
            SET v_pos_value = SUBSTRING(v_pos_value,4);

            IF col_is_rep = 0 THEN
                IF IFNULL(v_pos_value ,'') = '' THEN
                    SET v_final = v_final;
                ELSEIF v_pos_value <> '' THEN
                    SET v_final = CONCAT(v_final, col_vname, '=', v_pos_value, '&');
                END IF;
            ELSE
                IF IFNULL(v_pos_value,'') = '' THEN
                    SET v_final = NULL;
                    SET done = TRUE;
                ELSE
                    SET v_final = REPLACE(v_final,col_vname,v_pos_value);
                END IF;
            END IF;
        END IF;
        UNTIL done END REPEAT;
    CLOSE cur;

    RETURN TRIM(BOTH '&' FROM v_final);
END $$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;