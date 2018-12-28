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
    DECLARE v_double_side                 INT;
    DECLARE v_success_next_queue_step     INT;
    DECLARE v_fail_next_queue_step        INT;

    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        ROLLBACK;
        TRUNCATE TABLE msg_queues.temp_qsu_queues;
        TRUNCATE TABLE msg_queues.temp_qsu_queues_next_step;

        DROP TABLE IF EXISTS msg_queues.temp_qsu_queues;
        DROP TABLE IF EXISTS msg_queues.temp_qsu_queues_next_step;
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
    END;

    SET SESSION group_concat_max_len = 4294967295;
    SET returnCode_o = 400;
    SET returnMsg_o = CONCAT(v_modulename,v_procname,' command Error.');
    SET v_params_body = CONCAT('{"user_i":"',user_i,'","dst_queue_type_i":"',dst_queue_type_i,'","source_queue_type_i":"',source_queue_type_i,'","dst_endpoint_info_i":"',dst_endpoint_info_i,'"}');
    SET v_body = TRIM(body_i);
    SET source_queue_type_i = IFNULL(TRIM(source_queue_type_i),'');
    SET dst_queue_type_i = IFNULL(TRIM(dst_queue_type_i),'');
    SET dst_endpoint_info_i = IFNULL(TRIM(dst_endpoint_info_i),'');

    SET returnMsg_o = 'check input null data Error.';
    IF IFNULL(v_body,'') = '' OR IFNULL(source_queue_type_i,'') = '' THEN
        SET returnCode_o = 600;
        CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    SET returnMsg_o = 'check input dst_queue_step_i and source_queue_step_i invalid.';
    SELECT MAX(queue_step) INTO v_source_queue_step
      FROM msg_queues.queue_workflows
     WHERE queue_type = source_queue_type_i
       AND IFNULL(dst_queue_type,'') = dst_queue_type_i;
    IF v_source_queue_step IS NULL THEN
        SET returnCode_o = 600;
        CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    CREATE TEMPORARY TABLE IF NOT EXISTS msg_queues.`temp_qsu_queues` (
     `queue_id`                        BIGINT,
     `queue_type`                      VARCHAR(50),
     `queue_step`                      TINYINT,
     `next_queue_step`                 TINYINT,
     `dst_endpoint_info`               VARCHAR(100),
     `queue_status`                    TINYINT DEFAULT 0,
     `double_side`                     TINYINT,
     KEY `key_queue_id`                (`queue_id`),
     KEY `key_queue_type`              (`queue_type`),
     KEY `key_queue_step`              (`queue_step`),
     KEY `key_dst_endpoint_info`       (`dst_endpoint_info`)
    ) ENGINE=InnoDB;
    TRUNCATE TABLE msg_queues.temp_qsu_queues;

    CREATE TEMPORARY TABLE IF NOT EXISTS msg_queues.`temp_qsu_queues_next_step` (
     `queue_status`                    TINYINT,
     `next_queue_step`                 TINYINT
    ) ENGINE=InnoDB;
    TRUNCATE TABLE msg_queues.temp_qsu_queues_next_step;

    START TRANSACTION;
    SET SESSION innodb_lock_wait_timeout = 30;

    SET returnMsg_o = 'insert body into temp table failed.';
    SET v_sql = CONCAT('INSERT INTO msg_queues.`temp_qsu_queues` (queue_id,queue_status) VALUES ', v_body);

    CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);

    SET returnMsg_o = 'INSERT INTO temp_qsu_queues_next_step.';
    INSERT INTO msg_queues.`temp_qsu_queues_next_step`(queue_status)
         SELECT DISTINCT queue_status 
           FROM msg_queues.temp_qsu_queues;

    SET returnMsg_o = 'update next queue_step.';
    UPDATE msg_queues.`temp_qsu_queues_next_step`
       SET next_queue_step = msg_queues.`getNextStep`(source_queue_type_i,v_source_queue_step, queue_status);

    SELECT double_side
      INTO v_double_side
      FROM `queue_workflows`
     WHERE `queue_type` = source_queue_type_i
       AND `queue_step` = v_source_queue_step;

    SET returnMsg_o = 'get next queue_step.';
    SELECT MAX(next_queue_step) INTO v_success_next_queue_step FROM msg_queues.`temp_qsu_queues_next_step` WHERE queue_status = 0;
    SELECT MAX(next_queue_step) INTO v_fail_next_queue_step FROM msg_queues.`temp_qsu_queues_next_step` WHERE queue_status = 1;

    SET returnMsg_o = 'update queue_status success data.';
    UPDATE msg_queues.`temp_qsu_queues`
       SET `queue_type` = source_queue_type_i,
           `queue_step` = v_source_queue_step,
           `dst_endpoint_info` = dst_endpoint_info_i,
           `double_side` = v_double_side,
           `next_queue_step` = v_success_next_queue_step
     WHERE queue_status = 0;

    SET returnMsg_o = 'update queue_status fail data.';
    UPDATE msg_queues.`temp_qsu_queues`
       SET `queue_type` = source_queue_type_i,
           `queue_step` = v_source_queue_step,
           `dst_endpoint_info` = dst_endpoint_info_i,
           `double_side` = v_double_side,
           `next_queue_step` = v_fail_next_queue_step
     WHERE queue_status = 1;

     SET returnMsg_o = 'fail to query exists & queue step';
     SELECT COUNT(1)
       INTO v_cnt
       FROM msg_queues.temp_qsu_queues a
       LEFT
       JOIN msg_queues.queues b ON a.queue_id = b.queue_id AND a.queue_type = b.queue_type AND a.dst_endpoint_info = b.dst_endpoint_info
      WHERE b.id IS NULL OR a.queue_step > b.queue_step;
     IF v_cnt > 0 THEN
         SET returnCode_o = 600;
         LEAVE ll;
     END IF;

    SET returnMsg_o = 'failed to update queues.';
    /* double_side=1 and queue_status=1(fail) not need update*/
    UPDATE msg_queues.queues a,msg_queues.temp_qsu_queues b
       SET a.queue_step = b.next_queue_step,
           a.last_update_time = UTC_TIMESTAMP(),
           cycle_cnt = 0
     WHERE a.queue_id = b.queue_id
       AND a.queue_type = b.queue_type
       AND a.dst_endpoint_info = b.dst_endpoint_info
       AND a.queue_step = b.queue_step
       AND (b.double_side + b.queue_status) <> 2;

    COMMIT;
    TRUNCATE TABLE msg_queues.temp_qsu_queues;
    TRUNCATE TABLE msg_queues.temp_qsu_queues_next_step;

    DROP TABLE IF EXISTS msg_queues.temp_qsu_queues;
    DROP TABLE IF EXISTS msg_queues.temp_qsu_queues_next_step;

    SET returnCode_o = 200;
    SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);

END $$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;