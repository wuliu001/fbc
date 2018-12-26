USE `msg_queues`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Event structure for Event `sync_processing_file_end` */;

DROP EVENT IF EXISTS `sync_processing_file_end`;

DELIMITER $$

CREATE EVENT `sync_processing_file_end` ON SCHEDULE EVERY 1 MINUTE STARTS '2016-01-01 00:00:00' ON COMPLETION PRESERVE ENABLE DO ll:BEGIN
    DECLARE v_returnCode                 INT;
    DECLARE v_returnMsg                  LONGTEXT;
    DECLARE imp_lock                     INT;
    DECLARE v_procname                   VARCHAR(50) DEFAULT 'sync_processing_file_end.job';
    DECLARE v_modulename                 VARCHAR(50) DEFAULT 'messageManager';
    DECLARE v_body                       LONGTEXT DEFAULT NULL;
    DECLARE v_lock_name                  VARCHAR(50) DEFAULT 'sync_processing_file_end';
    DECLARE v_params_body                LONGTEXT DEFAULT '{}';
    DECLARE v_id                         LONGTEXT;
    DECLARE v_processing_files_id        LONGTEXT;
    DECLARE v_queue_id                   BIGINT;
    DECLARE v_cnt                        BIGINT;
    DECLARE v_queue_type                 VARCHAR(50) DEFAULT 'PROCESSING_FILE_SYNC';
    DECLARE v_queue_step                 TINYINT DEFAULT 2;
    DECLARE v_queue_next_step            TINYINT;
    DECLARE v_curMsg                     LONGTEXT;
    DECLARE v_sql                        LONGTEXT;

    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        ROLLBACK;
        SET v_returnMsg = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', v_curMsg, ' | ', IFNULL(v_returnMsg,''));
        SET imp_lock = RELEASE_LOCK(v_lock_name);
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,v_returnMsg,v_returnCode,v_returnMsg);
    END;

    SET v_curMsg = 'fail to get system lock.';
    SET imp_lock = GET_LOCK(v_lock_name,1);
    IF imp_lock <> 1 THEN
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,v_curMsg,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    SET v_curMsg = 'fail to get min queue_id.';
    SELECT GROUP_CONCAT(commons.`Util.getField2`( commons.`Util.getField2`(queues, '|$|', 2), ',',1) ) , MIN(queue_id),
           GROUP_CONCAT(id)
        INTO v_processing_files_id, v_queue_id, v_id
        FROM msg_queues.queues
        WHERE queue_type = v_queue_type
        AND queue_step = v_queue_step;

    IF IFNULL(v_processing_files_id,'') <> '' THEN
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
            SET imp_lock = RELEASE_LOCK(v_lock_name);
            CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,v_curMsg,v_returnCode,v_returnMsg);
            LEAVE ll;
        END IF;

        SET v_queue_next_step = msg_queues.`getNextStep`(v_queue_type, v_queue_step, 0);

        START TRANSACTION;
        SET SESSION innodb_lock_wait_timeout = 120;

        SET v_curMsg = 'update devices.`processing_files`.';
        SET v_sql = CONCAT('UPDATE devices.`processing_files`
                               SET sync_flag = 1,last_update_time = UTC_TIMESTAMP()
                             WHERE id IN (', v_processing_files_id, ')');
        CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);

        SET v_curMsg = 'update queue_step to end_step.';
        SET v_sql = CONCAT('
            UPDATE msg_queues.queues 
               SET queue_step =', v_queue_next_step, ',cycle_cnt = 0,last_update_time = UTC_TIMESTAMP()
             WHERE id IN (', v_id, ') 
               AND queue_type =''' , v_queue_type, '''
               AND queue_step = ', v_queue_step );
        CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);
        COMMIT;
    END IF;

    SET imp_lock = RELEASE_LOCK(v_lock_name);

END
$$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;