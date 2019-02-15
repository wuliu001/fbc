
USE `msg_queues`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Event structure for Event `unlock_queues_handle` */;

DROP EVENT IF EXISTS `unlock_queues_handle`;

DELIMITER $$

CREATE EVENT `unlock_queues_handle` ON SCHEDULE EVERY 1 MINUTE STARTS '2016-01-01 00:00:00' ON COMPLETION PRESERVE ENABLE DO ll:BEGIN
    DECLARE v_returnCode                 INT;
    DECLARE v_returnMsg                  LONGTEXT;
    DECLARE v_curMsg                     LONGTEXT;
    DECLARE imp_lock                     INT;
    DECLARE v_procname                   VARCHAR(50) DEFAULT 'unlock_queues_handle.job';
    DECLARE v_modulename                 VARCHAR(50) DEFAULT 'messageManager';
    DECLARE v_body                       LONGTEXT DEFAULT NULL;
    DECLARE v_lock_name                  VARCHAR(50) DEFAULT 'unlock_queues_handle';
    DECLARE v_params_body                LONGTEXT DEFAULT '{}';
    DECLARE v_id                         LONGTEXT;
    DECLARE v_queue_id                   BIGINT;
    DECLARE v_cnt                        BIGINT;
    DECLARE done                         INT DEFAULT 0;
    DECLARE v_queue_type                 VARCHAR(50);
    DECLARE v_queue_step                 TINYINT;
    DECLARE v_proc_name                  VARCHAR(100);

    DECLARE cur1 CURSOR FOR SELECT queue_type, queue_step, proc_name
                              FROM msg_queues.`job_config`
                             WHERE `type` = 'unlock';
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        SET v_curMsg = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', v_curMsg, ' | ', IFNULL(v_returnMsg,''));
        SET imp_lock = RELEASE_LOCK(v_lock_name);
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,v_curMsg,v_returnCode,v_returnMsg);
    END;

    SET v_curMsg = 'fail to get system lock.';
    SET imp_lock = GET_LOCK(v_lock_name,180);
    IF imp_lock <> 1 THEN
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,v_curMsg,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    OPEN cur1;
    myrepeat:REPEAT
        FETCH cur1 INTO v_queue_type,v_queue_step,v_proc_name;
        IF NOT done THEN
            SET v_curMsg = 'fail to get min queue_id.';
            SELECT GROUP_CONCAT('(', id, ')') ,MIN(queue_id)
              INTO v_id, v_queue_id
              FROM msg_queues.queues
             WHERE queue_type = v_queue_type
               AND queue_step = v_queue_step;

            IF v_id IS NULL THEN
                ITERATE myrepeat;
            END IF;

            SET v_curMsg = 'fail to get todo queues.';
            SELECT COUNT(1)
              INTO v_cnt
              FROM msg_queues.queues a,
                   msg_queues.queue_workflows b
             WHERE a.queue_type =  v_queue_type
               AND a.queue_id < v_queue_id
               AND b.queue_type = v_queue_type
               AND b.is_end_step = 1
               AND a.queue_step <> b.queue_step;

            IF v_cnt > 0 THEN
                CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,v_curMsg,v_returnCode,v_returnMsg);
                ITERATE myrepeat;
            END IF;

            SET v_curMsg = 'fail to get deal with real queues.';
            SET @v_sql = CONCAT('CALL ' , v_proc_name , '(0,''' , v_id, ''', @v_returnCode, @v_returnMsg)');
            PREPARE stmt2 FROM @v_sql;
            EXECUTE stmt2;
            DEALLOCATE PREPARE stmt2;

            IF @v_returnCode <> 200 THEN
                SET v_curMsg = CONCAT(v_curMsg,' ',IFNULL(@v_returnMsg,''));
                CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,v_curMsg,v_returnCode,v_returnMsg);
            END IF;
        END IF;
    UNTIL done END REPEAT;
    CLOSE cur1;

    SET imp_lock = RELEASE_LOCK(v_lock_name);
    SET v_curMsg = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,v_body,v_curMsg,v_returnCode,v_returnMsg);
END
$$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;