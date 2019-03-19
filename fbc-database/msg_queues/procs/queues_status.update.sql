USE `msg_queues`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `queues_status.update` */;

DROP PROCEDURE IF EXISTS `queues_status.update`;

DELIMITER $$

CREATE PROCEDURE `queues_status.update`(
    user_i                   INT,
    source_queue_type_i      VARCHAR(50),
    dst_queue_type_i         VARCHAR(50),
    dst_endpoint_info_i      VARCHAR(100),
    body_i                   LONGTEXT,
    OUT returnCode_o         INT,
    OUT returnMsg_o          LONGTEXT
    )
ll:BEGIN
    DECLARE v_procname                    VARCHAR(64) DEFAULT 'queues_status.update';
    DECLARE v_modulename                  VARCHAR(50) DEFAULT 'messageManager';
    DECLARE v_body                        LONGTEXT DEFAULT NULL;
    DECLARE v_params_body                 LONGTEXT DEFAULT NULL;
    DECLARE v_returnCode                  INT;
    DECLARE v_returnMsg                   LONGTEXT;
    DECLARE v_sql                         LONGTEXT;
    DECLARE v_source_queue_step           INT;
    DECLARE v_cnt                         INT;

    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        ROLLBACK;
        TRUNCATE TABLE msg_queues.temp_qsu_queues;
        TRUNCATE TABLE msg_queues.`temp_qsu_queues_steps`;
        DROP TABLE IF EXISTS msg_queues.temp_qsu_queues;
        DROP TABLE IF EXISTS msg_queues.`temp_qsu_queues_steps`;
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
    END;

    SET SESSION group_concat_max_len = 4294967295;
    SET returnCode_o = 400;
    SET returnMsg_o =  CONCAT(v_modulename, ' ', v_procname, ' command Error');
    SET v_params_body = CONCAT('{"user_i":"',IFNULL(user_i,'NULL'),'","dst_queue_type_i":"',IFNULL(dst_queue_type_i,'NULL'),'","source_queue_type_i":"',IFNULL(source_queue_type_i,'NULL'),'","dst_endpoint_info_i":"',IFNULL(dst_endpoint_info_i,'NULL'),'"}');
    SET v_body = TRIM(body_i);
    SET source_queue_type_i = TRIM(source_queue_type_i);
    SET dst_queue_type_i = TRIM(dst_queue_type_i);
    SET dst_endpoint_info_i = TRIM(dst_endpoint_info_i);

    SET returnMsg_o = 'check input null data Error.';
    IF IFNULL(v_body,'') = '' OR IFNULL(source_queue_type_i,'') = '' OR IFNULL(dst_queue_type_i,'') = '' OR IFNULL(dst_endpoint_info_i,'') = '' THEN
        SET returnCode_o = 600;
        CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    SET returnMsg_o = 'check input dst_queue_step_i and source_queue_step_i invalid.';
    SELECT MAX(queue_step)
      INTO v_source_queue_step
      FROM msg_queues.queue_workflows
     WHERE queue_type = source_queue_type_i
       AND dst_queue_type = dst_queue_type_i;
    IF v_source_queue_step IS NULL THEN
        SET returnCode_o = 651;
        CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    CREATE TEMPORARY TABLE IF NOT EXISTS msg_queues.`temp_qsu_queues` (
     `queue_id`                        BIGINT(20) UNSIGNED NOT NULL,
     `queue_status`                    TINYINT NOT NULL,
     KEY `idx_tqq_queue_id`            (`queue_id`)
    ) ENGINE=InnoDB;
    TRUNCATE TABLE msg_queues.temp_qsu_queues;

    CREATE TEMPORARY TABLE IF NOT EXISTS msg_queues.`temp_qsu_queues_steps` (
     `status`                          VARCHAR(20),
     `next_queue_step`                 TINYINT
    ) ENGINE=InnoDB;
    TRUNCATE TABLE msg_queues.temp_qsu_queues_steps;
    
    START TRANSACTION;
    SET SESSION innodb_lock_wait_timeout = 30;

    SET returnMsg_o = 'insert body into temp table failed.';
    SET v_sql = CONCAT('INSERT INTO msg_queues.`temp_qsu_queues` (queue_id,queue_status) VALUES ', v_body);
    CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);

    SET returnMsg_o = 'fail to query exists & queue step';
    SELECT COUNT(1)
      INTO v_cnt
      FROM msg_queues.temp_qsu_queues a
      LEFT
      JOIN msg_queues.queues b ON b.queue_id = a.queue_id AND b.queue_type = source_queue_type_i AND b.dst_endpoint_info = dst_endpoint_info_i
     WHERE b.id IS NULL OR v_source_queue_step > b.queue_step;
     IF v_cnt > 0 THEN
         COMMIT;
         TRUNCATE TABLE msg_queues.temp_qsu_queues;
         TRUNCATE TABLE msg_queues.`temp_qsu_queues_steps`;
         DROP TABLE IF EXISTS msg_queues.temp_qsu_queues;
         DROP TABLE IF EXISTS msg_queues.`temp_qsu_queues_steps`;
         SET returnCode_o = 652;
         CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
         LEAVE ll;
     END IF;

    SET returnMsg_o = 'fail to set temp_qsu_queues_steps.';
    INSERT INTO msg_queues.`temp_qsu_queues_steps` (`status`,next_queue_step)
    SELECT a.`queue_status`,msg_queues.`getNextStep`(source_queue_type_i,v_source_queue_step, a.`queue_status`)
      FROM (
             SELECT `queue_status` 
               FROM msg_queues.`temp_qsu_queues` 
              GROUP BY `queue_status`
           )a;

    SET returnMsg_o = 'failed to update queues.';
    UPDATE msg_queues.queues a,
           msg_queues.temp_qsu_queues b,
           msg_queues.`temp_qsu_queues_steps` c
       SET a.cycle_cnt = CASE WHEN a.queue_step = c.next_queue_step THEN a.cycle_cnt + 1 ELSE 0 END,
           a.queue_step = c.next_queue_step,
           a.last_update_time = UTC_TIMESTAMP(),
           a.`status` = CASE WHEN b.`queue_status` > 0 AND a.queue_step <> c.next_queue_step THEN 1 ELSE a.`status` END
     WHERE a.queue_id = b.queue_id
       AND a.queue_type = source_queue_type_i
       AND a.dst_endpoint_info = dst_endpoint_info_i
       AND a.queue_step = v_source_queue_step
       AND b.`queue_status` = c.`status`;

    COMMIT;
    
    TRUNCATE TABLE msg_queues.temp_qsu_queues;
    TRUNCATE TABLE msg_queues.`temp_qsu_queues_steps`;
    DROP TABLE IF EXISTS msg_queues.temp_qsu_queues;
    DROP TABLE IF EXISTS msg_queues.`temp_qsu_queues_steps`;

    SET returnCode_o = 200;
    SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);

END $$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;