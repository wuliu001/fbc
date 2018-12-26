USE `msg_queues`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Function structure for Function `getBody` */;

DROP FUNCTION IF EXISTS `getBody`;

DELIMITER $$
CREATE FUNCTION `getBody`(queue_type_i VARCHAR(50) ,queue_step_i TINYINT(4),queues_i  LONGTEXT) RETURNS LONGTEXT
BEGIN
    DECLARE v_pos         VARCHAR(100);
    DECLARE v_pos_start   INT(11);
    DECLARE v_length      INT(11);
    DECLARE v_start       INT(11) DEFAULT 1;
    DECLARE v_return      LONGTEXT DEFAULT '';

    IF IFNULL(queue_type_i , '') = '' OR IFNULL(queues_i,'') = '' OR queue_step_i IS NULL THEN
        RETURN '';
    END IF;

    SELECT commons.`stringList.trim`(MAX(queue_val_pos),',')
      INTO v_pos
      FROM msg_queues.service_parameters
     WHERE queue_type = queue_type_i
       AND queue_step = queue_step_i
       AND var_name = 'body';

    IF IFNULL(LENGTH(v_pos),0) = 0 THEN
        RETURN '';
    END IF;

    #get body
    SET v_length = LENGTH(v_pos) - LENGTH(REPLACE(v_pos,',','')) + 1;
    WHILE v_length >= v_start DO
        SET v_pos_start = IFNULL(commons.`Util.getField`(v_pos, ',', v_start),0);
        SET v_return = CONCAT(v_return,'|$|',IFNULL(commons.`Util.getField`(queues_i, '|$|', v_pos_start),''));
        SET v_start = v_start + 1;
    END WHILE;

    RETURN SUBSTRING(v_return,4);
END $$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;