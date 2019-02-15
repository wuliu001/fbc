
USE msg_queues;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Function structure for Function `getNextStep` */;

DROP FUNCTION IF EXISTS `getNextStep`;

DELIMITER $$
CREATE FUNCTION `getNextStep`( queue_type_i    VARCHAR(50),
                               queue_step_i    TINYINT(4),
                               queue_status_i  INT(11)) RETURNS INT(11)
BEGIN
    
    DECLARE v_special_step  JSON;
    DECLARE v_cnt           INT;
    DECLARE v_is_end        INT;
    DECLARE v_end_step      INT;
    DECLARE v_json_exp      VARCHAR(20);
    
    IF IFNULL(queue_type_i , '') = '' OR queue_step_i IS NULL OR queue_status_i IS NULL THEN
        RETURN NULL;
    END IF;
    
    SELECT COUNT(1),MAX(special_step),MAX(is_end_step)
      INTO v_cnt,v_special_step ,v_is_end
      FROM msg_queues.queue_workflows 
     WHERE queue_type = queue_type_i 
       AND queue_step = queue_step_i;

    IF v_cnt = 0 THEN
        RETURN NULL;
    END IF;
    
    IF v_special_step IS NULL THEN
        IF v_is_end = 1 THEN
            RETURN queue_step_i;
        ELSE 
            RETURN queue_step_i + 1;
        END IF;
    ELSE
        SET v_json_exp = CONCAT('$."',queue_status_i,'"');
        RETURN JSON_EXTRACT(v_special_step,v_json_exp);
    END IF;
END $$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;