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
    DECLARE v_sys_lock                    INT;

    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        ROLLBACK;
        SET v_sys_lock = RELEASE_LOCK('msg_queues.queues');
        TRUNCATE TABLE msg_queues.temp_qi_queues;
        TRUNCATE TABLE msg_queues.`temp_qi_queues_steps`;
        DROP TABLE IF EXISTS msg_queues.temp_qi_queues;
        DROP TABLE IF EXISTS msg_queues.`temp_qi_queues_steps`;
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
    END;

    SET SESSION group_concat_max_len = 4294967295;
    SET returnCode_o = 400;
    SET returnMsg_o =  CONCAT(v_modulename, ' ', v_procname, ' command Error');
    SET v_params_body = CONCAT('{"user_i":"',IFNULL(user_i,'NULL'),'","queue_type_i":"',IFNULL(queue_type_i,'NULL'),'","queue_step_i":"',IFNULL(queue_step_i,'NULL'),'","dst_endpoint_info_i":"',IFNULL(dst_endpoint_info_i,'NULL'),'"}');
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
    IF msg_queues.`checkStatus`(queue_type_i,queue_step_i) = 0 THEN
        SET returnCode_o = 651;
        CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    CREATE TEMPORARY TABLE IF NOT EXISTS msg_queues.`temp_qi_queues` (
     `queue_id`                        BIGINT,
     `main_queue_info`                 VARCHAR(255),
     `queue_msg`                       LONGTEXT,
     `status`                          VARCHAR(20),
     `next_queue_step`                 TINYINT
    ) ENGINE=InnoDB;
    TRUNCATE TABLE msg_queues.temp_qi_queues;
    
    CREATE TEMPORARY TABLE IF NOT EXISTS msg_queues.`temp_qi_queues_steps` (
     `status`                          VARCHAR(20),
     `next_queue_step`                 TINYINT
    ) ENGINE=InnoDB;
    TRUNCATE TABLE msg_queues.temp_qi_queues_steps;

    START TRANSACTION;
    SET SESSION innodb_lock_wait_timeout = 30;

    SET returnMsg_o = 'insert body into temp table failed.';
    SET v_sql = CONCAT('INSERT INTO msg_queues.`temp_qi_queues` (queue_id,main_queue_info,queue_msg,`status`) VALUES ',v_body);
    CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);
    
    SET returnMsg_o = 'input body info check failed.';
    CALL msg_queues.`queues_content.check`(user_i,queue_type_i,queue_step_i, dst_endpoint_info_i,v_returnCode_check,v_returnMsg_check);
    IF v_returnCode_check <> 200 THEN
        COMMIT;
        TRUNCATE TABLE msg_queues.temp_qi_queues;
        TRUNCATE TABLE msg_queues.`temp_qi_queues_steps`;
        DROP TABLE IF EXISTS msg_queues.temp_qi_queues;
        DROP TABLE IF EXISTS msg_queues.`temp_qi_queues_steps`;
        SET returnCode_o = v_returnCode_check;
        SET returnMsg_o = CONCAT(IFNULL(returnMsg_o,''),' ',IFNULL(v_returnMsg_check,''));
        CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'fail to set temp_qi_queues_steps.';
    INSERT INTO msg_queues.`temp_qi_queues_steps` (`status`,next_queue_step)
    SELECT a.`status`,msg_queues.`getNextStep`(queue_type_i,queue_step_i, a.`status`)
      FROM (
             SELECT `status` 
               FROM msg_queues.`temp_qi_queues` 
              GROUP BY `status`
           )a;

    SET returnMsg_o = CONCAT('fail to get queues locks');
    SET v_sys_lock = GET_LOCK('msg_queues.queues',180);
    IF v_sys_lock <> 1 THEN
        COMMIT;
        TRUNCATE TABLE msg_queues.temp_qi_queues;
        TRUNCATE TABLE msg_queues.`temp_qi_queues_steps`;
        DROP TABLE IF EXISTS msg_queues.temp_qi_queues;
        DROP TABLE IF EXISTS msg_queues.`temp_qi_queues_steps`;
        SET returnCode_o = 652;
        CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'failed to input data into queues.';
    INSERT INTO msg_queues.queues(`queue_id`,`main_queue_info`,`queue_type`, `queue_step`, queues, source_endpoint_info,dst_endpoint_info,cycle_cnt,create_time,last_update_time,is_re_assign_endpoint)
         SELECT a.queue_id,
                a.main_queue_info,
                queue_type_i,
                queue_step_i,
                a.queue_msg,
                (CASE WHEN queue_id IS NULL THEN 'default' ELSE dst_endpoint_info_i END),
                dst_endpoint_info_i ,
                0,
                UTC_TIMESTAMP(),
                UTC_TIMESTAMP(),
                CASE WHEN IFNULL(dst_endpoint_info_i,'') = '' THEN 1 ELSE 0 END
           FROM msg_queues.temp_qi_queues a,
                msg_queues.temp_qi_queues_steps b 
          WHERE a.`status` = b.`status`
             ON DUPLICATE KEY UPDATE queue_step = b.next_queue_step,
                                     queues = a.queue_msg,
                                     cycle_cnt = 0,
                                     last_update_time = UTC_TIMESTAMP();
                                     
    UPDATE msg_queues.queues SET queue_id = id WHERE queue_id IS NULL;
    
    SET v_sys_lock = RELEASE_LOCK('msg_queues.queues');
    
    COMMIT;

    TRUNCATE TABLE msg_queues.temp_qi_queues;
    TRUNCATE TABLE msg_queues.`temp_qi_queues_steps`;
    DROP TABLE IF EXISTS msg_queues.temp_qi_queues;
    DROP TABLE IF EXISTS msg_queues.`temp_qi_queues_steps`;

    SET returnCode_o = 200;
    SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);

END $$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;