USE `msg_queues`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `queues.insert` */;

DROP PROCEDURE IF EXISTS `queues.insert`;

DELIMITER $$

CREATE PROCEDURE `queues.insert`(
    user_i                   INT,
    body_i                   LONGTEXT,
    queue_type_i             VARCHAR(50),
    queue_step_i             TINYINT(4),
    dst_endpoint_info_i      VARCHAR(100),
    OUT returnCode_o         INT,
    OUT returnMsg_o          LONGTEXT
    )
ll:BEGIN
    DECLARE v_procname                    VARCHAR(64) DEFAULT 'queues.insert';
    DECLARE v_modulename                  VARCHAR(50) DEFAULT 'messageManager';
    DECLARE v_body                        LONGTEXT DEFAULT NULL;
    DECLARE v_params_body                 LONGTEXT DEFAULT NULL;
    DECLARE v_returnCode                  INT;
    DECLARE v_returnMsg                   LONGTEXT;
    DECLARE v_returnCode_check            INT;
    DECLARE v_returnMsg_check             LONGTEXT;
    DECLARE v_sql                         LONGTEXT;
    DECLARE v_is_type_valid               INT;

    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        ROLLBACK;
        TRUNCATE TABLE msg_queues.temp_qi_queues;
        DROP TABLE IF EXISTS msg_queues.temp_qi_queues;
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
    END;

    SET SESSION group_concat_max_len = 4294967295;
    SET returnCode_o = 400;
    SET returnMsg_o = CONCAT(v_modulename,v_procname,' command Error.');
    SET v_params_body = CONCAT('{"user_i":"',user_i,'","queue_type_i":"',queue_type_i,'","queue_step_i":"',queue_step_i,'","dst_endpoint_info_i":"',dst_endpoint_info_i,'"}');
    SET v_body = TRIM(body_i);
    SET queue_type_i = TRIM(queue_type_i);
    SET dst_endpoint_info_i = TRIM(dst_endpoint_info_i);

    SET returnMsg_o = 'check input null data Error.';
    IF IFNULL(v_body,'') = '' OR IFNULL(queue_type_i,'') = '' OR queue_step_i IS NULL THEN
        SET returnCode_o = 600;
        CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    SET returnMsg_o = 'check input queue_type and queue_step invalid.';
    SET v_is_type_valid = msg_queues.`checkStatus`(queue_type_i,queue_step_i);
    IF v_is_type_valid = 0 THEN
        SET returnCode_o = 600;
        CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    CREATE TEMPORARY TABLE IF NOT EXISTS msg_queues.`temp_qi_queues` (
     `queue_id`                        BIGINT(20),
     `queue_msg`                       LONGTEXT,
     `status`                          VARCHAR(20),
     `queue_type`                      VARCHAR(50),
     `queue_step`                      TINYINT(4),
     `next_queue_step`                 TINYINT(4),
     `source_endpoint_info`            VARCHAR(100),
     `dst_endpoint_info`               VARCHAR(100),
     `is_re_assign_endpoint`           TINYINT(4)
    ) ENGINE=InnoDB;
    TRUNCATE TABLE msg_queues.temp_qi_queues;

    START TRANSACTION;
    SET SESSION innodb_lock_wait_timeout = 30;

    SET returnMsg_o = 'insert body into temp table failed.';
    SET v_sql = CONCAT('INSERT INTO msg_queues.`temp_qi_queues` (queue_id,queue_msg,`status`) VALUES ',v_body);
    CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);
    UPDATE msg_queues.`temp_qi_queues`
       SET `queue_type` = queue_type_i,
           `queue_step` = queue_step_i,
           `source_endpoint_info` = (CASE WHEN IFNULL(dst_endpoint_info_i ,'') = '' THEN 'default' ELSE dst_endpoint_info_i END),
           `dst_endpoint_info` = dst_endpoint_info_i,
           `is_re_assign_endpoint` = (CASE WHEN IFNULL(dst_endpoint_info_i ,'') = '' THEN 1 ELSE 0 END);

    SET returnMsg_o = 'input body info check failed.';
    CALL msg_queues.`queues_content.check`(user_i,v_returnCode_check,v_returnMsg_check);
    IF v_returnCode_check <> 200 THEN
        COMMIT;
        TRUNCATE TABLE msg_queues.temp_qi_queues;
        DROP TABLE IF EXISTS msg_queues.temp_qi_queues;
        SET returnCode_o = v_returnCode_check;
        SET returnMsg_o = CONCAT(IFNULL(returnMsg_o,''),' ',IFNULL(v_returnMsg_check,''));
        CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    SET returnMsg_o = 'update next step info failed.';
    UPDATE msg_queues.temp_qi_queues a
      LEFT
      JOIN msg_queues.queues b
        ON a.queue_id = b.queue_id
       AND a.queue_type = b.queue_type
       AND a.dst_endpoint_info = b.dst_endpoint_info
       AND a.queue_step = b.queue_step
       SET a.next_queue_step = (CASE WHEN b.id IS NULL THEN a.queue_step ELSE msg_queues.`getNextStep`(b.queue_type,b.queue_step,a.`status`) END);

    SET returnMsg_o = 'failed to input data into queues.';
    INSERT INTO msg_queues.queues(`queue_id`,`queue_type`, `queue_step`, queues, source_endpoint_info,dst_endpoint_info,cycle_cnt,create_time, last_update_time,is_re_assign_endpoint)
         SELECT a.queue_id,a.queue_type,a.next_queue_step,a.queue_msg,a.source_endpoint_info,a.dst_endpoint_info ,0,UTC_TIMESTAMP(),UTC_TIMESTAMP(),a.is_re_assign_endpoint
           FROM msg_queues.temp_qi_queues a
             ON DUPLICATE KEY UPDATE queue_step = a.next_queue_step,
                                     queues = a.queue_msg,
                                     cycle_cnt = 0,
                                     last_update_time = UTC_TIMESTAMP(),
                                     is_re_assign_endpoint = a.is_re_assign_endpoint;
    UPDATE msg_queues.queues SET queue_id = id WHERE queue_id IS NULL;

    COMMIT;

    TRUNCATE TABLE msg_queues.temp_qi_queues;
    DROP TABLE IF EXISTS msg_queues.temp_qi_queues;

    SET returnCode_o = 200;
    SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);

END $$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;