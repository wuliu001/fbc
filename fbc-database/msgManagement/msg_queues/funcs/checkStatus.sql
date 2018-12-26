USE `msg_queues`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Function structure for Function `checkStatus` */;

DROP FUNCTION IF EXISTS `checkStatus`;

DELIMITER $$
CREATE FUNCTION `checkStatus`(queue_type_i VARCHAR(50) ,queue_step_i TINYINT(4)) RETURNS INT(11)
BEGIN
    DECLARE v_cnt    INT;
    
    SELECT COUNT(1)
      INTO v_cnt
      FROM msg_queues.queue_workflows
     WHERE queue_type = queue_type_i
       AND (queue_step_i IS NULL OR queue_step = queue_step_i);

    IF v_cnt = 0 THEN
        RETURN 0;
    ELSE
        RETURN 1;
    END IF;
END $$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;