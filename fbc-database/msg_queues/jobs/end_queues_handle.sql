USE `msg_queues`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Event structure for Event `end_queues_handle` */;

DROP EVENT IF EXISTS `end_queues_handle`;

DELIMITER $$

CREATE EVENT `end_queues_handle` ON SCHEDULE EVERY 1 MINUTE STARTS '2016-01-01 00:00:00' ON COMPLETION PRESERVE ENABLE DO ll:BEGIN
    DECLARE v_returnCode                 INT;
    DECLARE v_returnMsg                  LONGTEXT;
    DECLARE v_curMsg                     LONGTEXT;
    DECLARE v_procname                   VARCHAR(50) DEFAULT 'end_queues_handle.job';
    DECLARE v_modulename                 VARCHAR(50) DEFAULT 'messageManager';
    DECLARE v_body                       LONGTEXT DEFAULT NULL;
    DECLARE v_lock_name                  VARCHAR(50) DEFAULT 'end_queues_handle';
    DECLARE v_params_body                LONGTEXT DEFAULT '{}';
    DECLARE imp_lock                     INT;

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

    UPDATE msg_queues.queues a,
           msg_queues.queue_workflows b
       SET a.is_delete = 1
     WHERE a.is_delete = 0
       AND a.queue_step = b.queue_step
       AND a.queue_type = b.queue_type
       AND b.is_end_step = 1;
    
    SET imp_lock = RELEASE_LOCK(v_lock_name);
    SET v_curMsg = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,v_body,v_curMsg,v_returnCode,v_returnMsg);
END
$$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;