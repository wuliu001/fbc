USE `msg_queues`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Event structure for Event `sub_queue_type` */;

DROP EVENT IF EXISTS `scan_sub_queue_type`;

DELIMITER $$

CREATE EVENT `scan_sub_queue_type` ON SCHEDULE EVERY 1 MINUTE STARTS '2016-01-01 00:00:00' ON COMPLETION PRESERVE ENABLE DO

ll:BEGIN
    DECLARE v_returnCode                 INT;
    DECLARE v_returnMsg                  LONGTEXT;
    DECLARE returnMsg_o                  LONGTEXT;
    DECLARE done                         INT DEFAULT 0;
    DECLARE imp_lock                     INT;
    DECLARE v_procname                   VARCHAR(50) DEFAULT 'scan_sub_queue_type.job';
    DECLARE v_modulename                 VARCHAR(50) DEFAULT 'messageManager';
    DECLARE v_lock_name                  VARCHAR(50) DEFAULT 'scan_sub_queue_type';
    DECLARE v_params_body                LONGTEXT DEFAULT '{}';
    DECLARE v_queue_msg                  LONGTEXT DEFAULT '';
    DECLARE v_id                         BIGINT;
    DECLARE v_queue_id                   BIGINT;
    DECLARE v_queue_type                 VARCHAR(50);
    DECLARE v_queue_step                 TINYINT;
    DECLARE v_main_queue_info            VARCHAR(255);
    DECLARE v_sub_queue_type             VARCHAR(50);
    DECLARE v_sub_queue_info             LONGTEXT;
    DECLARE v_sql                        LONGTEXT;
    DECLARE v_endpoint_idx               INT DEFAULT 1;
    DECLARE v_endpoint_cnt               INT DEFAULT 0;
    DECLARE v_dst_endpoints              LONGTEXT;
    DECLARE v_dst_endpoint               VARCHAR(200);

    DECLARE cur_queue_type CURSOR FOR SELECT id, queue_id, queue_type, queue_step, main_queue_info, sub_queue_type, queue_msg
                                        FROM msg_queues.`tmp_sub_queue_type` ;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        UPDATE msg_queues.queues
           SET queue_step = msg_queues.`getNextStep`(v_queue_type, v_queue_step, 1),
               cycle_cnt = CASE WHEN msg_queues.getNextStep(v_queue_type, v_queue_step, 1) = v_queue_step THEN cycle_cnt + 1 ELSE 0 END,
               `status` = CASE WHEN msg_queues.getNextStep(v_queue_type, v_queue_step, 1) <> v_queue_step THEN 1 ELSE `status` END,
               last_update_time = UTC_TIMESTAMP()
         WHERE id = v_id
           AND queue_id = v_queue_id
           AND queue_type = v_queue_type
           AND queue_step = v_queue_step;
        TRUNCATE TABLE msg_queues.`tmp_sub_queue_type`;
        DROP TABLE IF EXISTS msg_queues.`tmp_sub_queue_type`;
        SET v_returnMsg = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', returnMsg_o, ' | ', IFNULL(v_returnMsg,''));
        SET imp_lock = RELEASE_LOCK(v_lock_name);
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_queue_msg,v_returnMsg,v_returnCode,v_returnMsg);
    END;

    SET SESSION group_concat_max_len = 4294967295;
    SET returnMsg_o = CONCAT(v_modulename,v_procname,' command Error.');

    SET returnMsg_o = 'fail to get system lock.';
    SET imp_lock = GET_LOCK(v_lock_name,180);
    IF imp_lock <> 1 THEN
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_queue_msg,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    CREATE TEMPORARY TABLE IF NOT EXISTS msg_queues.`tmp_sub_queue_type` (
      `id`                   BIGINT NOT NULL,
      `queue_id`             BIGINT NOT NULL,
      `queue_type`           VARCHAR(50) NOT NULL,
      `queue_step`           TINYINT NOT NULL,
      `main_queue_info`      VARCHAR(255) NOT NULL,
      `sub_queue_type`       VARCHAR(50) NOT NULL,
      `queue_msg`            LONGTEXT DEFAULT NULL
    ) ENGINE=InnoDB; 
    TRUNCATE TABLE msg_queues.`tmp_sub_queue_type`;

    ## get main_queue_task''s queue_type, queue_step and get sub_task_type, 
    ##   queue_type and queue_step must be exist queue_workflows and queues

    SET returnMsg_o = 'select queue_id, queue_type, queue_step, sub_queue_type and their MD5 infomation.';
    SELECT GROUP_CONCAT('(', 
                        b.id, ',', 
                        b.queue_id, ',''', 
                        a.queue_type,''',', 
                        a.queue_step, ',''', 
                        MD5(CONCAT(b.id,b.queue_id,b.queue_type,b.queue_step,IFNULL(b.dst_endpoint_info,''),b.create_time,b.last_update_time)),''',''', 
                        a.sub_queue_type,''',',
                        '"(NULL,''', MD5(CONCAT(b.id,b.queue_id,b.queue_type,b.queue_step,IFNULL(b.dst_endpoint_info,''),b.create_time,b.last_update_time)),''',''', 
                        commons.`RegExp_SpecialStr.invalid`(commons.`RegExp_SpecialStr.invalid`(b.queues,'(.)|$'),'(.)|$') ,''',0)")')
      INTO v_sub_queue_info
      FROM (SELECT DISTINCT queue_type, queue_step, sub_queue_type
              FROM msg_queues.queue_workflows
             WHERE IFNULL(sub_queue_type,'') <> ''
           ) a
      JOIN msg_queues.queues b
        ON a.queue_type = b.queue_type
       AND a.queue_step = b.queue_step
       AND b.is_delete = 0;

    IF IFNULL(v_sub_queue_info,'')<>'' THEN
        SET returnMsg_o = 'input queue_msg, sub_queue_type to temp table.';
        SET v_sql = CONCAT('INSERT INTO msg_queues.`tmp_sub_queue_type`(`id`,`queue_id`,`queue_type`,`queue_step`,`main_queue_info`,`sub_queue_type`,`queue_msg`) VALUES ',v_sub_queue_info);
        CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);
    END IF;

    SET returnMsg_o = 'deal with sub_queue_type';
    OPEN cur_queue_type;
    lp:LOOP
        FETCH cur_queue_type INTO v_id, v_queue_id, v_queue_type, v_queue_step,v_main_queue_info, v_sub_queue_type, v_queue_msg;
        IF done THEN
           LEAVE lp;
        END IF;

        SET returnMsg_o = CONCAT('get configuration information for sub_queue_type:',v_sub_queue_type);
        SELECT GROUP_CONCAT(CONCAT('http://',endpoint_ip,':',endpoint_port) )
          INTO v_dst_endpoints
          FROM msg_queues.sync_service_config
         WHERE queue_type = v_sub_queue_type;

        SET v_endpoint_idx = 1;
        SET v_endpoint_cnt=FLOOR((LENGTH(v_dst_endpoints)-LENGTH(REPLACE(v_dst_endpoints, ',', '')))/LENGTH(',')) + 1;
        WHILE v_endpoint_idx <= v_endpoint_cnt DO
            SET returnMsg_o = CONCAT('call msg_queues.queues.insert: ',v_sub_queue_type, ' dst_endpoint:',v_dst_endpoint);
            SET v_dst_endpoint = commons.`Util.getField2`(v_dst_endpoints,',',v_endpoint_idx);

            CALL msg_queues.`queues.insert`(0 , v_queue_msg, v_sub_queue_type, 0, v_dst_endpoint, v_returnCode, v_returnMsg);
            IF v_returnCode <> 200 THEN
                SET imp_lock = RELEASE_LOCK(v_lock_name);
                SET returnMsg_o = v_returnMsg;

                UPDATE msg_queues.queues
                   SET queue_step = msg_queues.`getNextStep`(v_queue_type, v_queue_step, 1),
                       cycle_cnt = CASE WHEN msg_queues.getNextStep(v_queue_type, v_queue_step, 1) = v_queue_step THEN cycle_cnt + 1 ELSE 0 END,
                       `status` = CASE WHEN msg_queues.getNextStep(v_queue_type, v_queue_step, 1) <> v_queue_step THEN 1 ELSE `status` END,
                       last_update_time = UTC_TIMESTAMP()
                 WHERE id = v_id
                   AND queue_id = v_queue_id
                   AND queue_type = v_queue_type
                   AND queue_step = v_queue_step;
                   
                TRUNCATE TABLE msg_queues.`tmp_sub_queue_type`;
                DROP TABLE IF EXISTS msg_queues.`tmp_sub_queue_type`;
                CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_queue_msg,returnMsg_o,v_returnCode,v_returnMsg);
                LEAVE ll;
            END IF;
            
            SET v_endpoint_idx = v_endpoint_idx + 1;
        END WHILE;
        
        SET returnMsg_o = CONCAT('update queues''s main_step for main_queue_type: ',v_queue_type);
        UPDATE msg_queues.queues
           SET queue_step = msg_queues.`getNextStep`(v_queue_type, v_queue_step, 0),
               cycle_cnt = 0,
               last_update_time = UTC_TIMESTAMP(),
               main_queue_info = v_main_queue_info
         WHERE id = v_id
           AND queue_id = v_queue_id
           AND queue_type = v_queue_type
           AND queue_step = v_queue_step
           AND is_delete = 0;

    END LOOP;
    CLOSE cur_queue_type;

    SET imp_lock = RELEASE_LOCK(v_lock_name);

    TRUNCATE TABLE msg_queues.`tmp_sub_queue_type`;
    DROP TABLE IF EXISTS msg_queues.`tmp_sub_queue_type`;

    SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,v_queue_msg,returnMsg_o,v_returnCode,v_returnMsg);
END
$$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;