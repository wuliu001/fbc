USE `msg_queues`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `get_un_synced_queue` */;

DROP PROCEDURE IF EXISTS `get_un_synced_queue`;

DELIMITER $$

CREATE PROCEDURE `get_un_synced_queue`(
    user_i                      INT,
    last_receive_info_i         TEXT,
    syncService_id_i            VARCHAR(100),
    cur_weight_after_selected_i TEXT,
    OUT returnCode_o            INT,
    OUT returnMsg_o             TEXT)
ll:BEGIN
    DECLARE v_unsynced_sys_lock           INT;
    DECLARE v_sync_id                     INT;
    DECLARE done                          INT DEFAULT 0;
    DECLARE v_procname                    VARCHAR(50) DEFAULT 'get_un_synced_queue';
    DECLARE v_modulename                  VARCHAR(50) DEFAULT 'messageManager';
    DECLARE v_body                        LONGTEXT DEFAULT NULL;
    DECLARE v_params_body                 LONGTEXT DEFAULT NULL;
    DECLARE v_queue_type                  VARCHAR(50);
    DECLARE v_syncService_id_i            VARCHAR(100);
    DECLARE v_cur_endpoint_info           VARCHAR(100);
    DECLARE v_lock_name                   VARCHAR(50) DEFAULT 'get_un_synced_queue_lock';

    DECLARE v_dst_queue_type              VARCHAR(50);
    DECLARE v_cnt                         INT;
    DECLARE v_sql                         LONGTEXT;
    DECLARE v_value                       LONGTEXT;
    DECLARE v_limit                       INT;
    DECLARE v_returnCode                  INT;
    DECLARE v_returnMsg                   LONGTEXT;

    # get each type need to allocate server data
    DECLARE cur_next_serv CURSOR FOR SELECT a.queue_type, a.dst_queue_type
                                       FROM msg_queues.`temp_gusq_unsync_queue` a
                                      WHERE a.dst_endpoint_info IS NULL
                                        AND a.source_endpoint_info = 'default'
                                      GROUP BY a.queue_type, a.dst_queue_type;

    # GROUP BY queue_type, get each queue_type OF LIMIT VALUES
    DECLARE cur_queue_type CURSOR FOR SELECT queue_type,`limit`
                                        FROM msg_queues.`queue_workflows`
                                       WHERE CASE WHEN double_side = 0 THEN CAST(uri AS CHAR) ELSE CAST(dst_queue_type AS CHAR(50)) END IS NOT NULL
                                       GROUP BY queue_type,`limit`;


    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        SET v_unsynced_sys_lock = RELEASE_LOCK(v_lock_name);
        ROLLBACK;
        TRUNCATE TABLE msg_queues.`temp_gusq_unsync_queue`;
        TRUNCATE TABLE msg_queues.`temp_gusq_unsync_queue_limit`;
        TRUNCATE TABLE msg_queues.`temp_gusq_unsync_queue_limit2`;
        TRUNCATE TABLE msg_queues.`temp_gusq_sync_service_cfg`;
        TRUNCATE TABLE msg_queues.`temp_gusq_last_sync_id`;
        TRUNCATE TABLE msg_queues.`temp_gusq_begin_unsync_id`;
        TRUNCATE TABLE msg_queues.`temp_gusq_final_queue`;
        DROP TABLE IF EXISTS msg_queues.`temp_gusq_final_queue`;        
        DROP TABLE IF EXISTS msg_queues.`temp_gusq_unsync_queue`;
        DROP TABLE IF EXISTS msg_queues.`temp_gusq_unsync_queue_limit`;
        DROP TABLE IF EXISTS msg_queues.`temp_gusq_unsync_queue_limit2`;
        DROP TABLE IF EXISTS msg_queues.`temp_gusq_sync_service_cfg`;
        DROP TABLE IF EXISTS msg_queues.`temp_gusq_last_sync_id`;
        DROP TABLE IF EXISTS msg_queues.`temp_gusq_begin_unsync_id`;
        CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
    END;


    SET returnCode_o = 400;
    SET returnMsg_o = '';
    SET v_params_body = CONCAT('{"syncService_id_i":"',IFNULL(syncService_id_i,''), '","last_receive_info_i":"', IFNULL(REPLACE(last_receive_info_i,'"',''),''), '"}');
    SET v_body = IFNULL(cur_weight_after_selected_i,'');
    SET SESSION group_concat_max_len = 4294967295;

    CALL commons.`log_module.i`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);

    SET v_syncService_id_i = TRIM(syncService_id_i);
    IF v_syncService_id_i IS NULL OR v_syncService_id_i = '' THEN
        SET returnCode_o = 600;
        SET returnMsg_o = 'syncService_id_i should not be null.';
        CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    SELECT MAX(a.id)
      INTO v_sync_id
      FROM msg_queues.`sync_service` a
    WHERE a.syncService_id = v_syncService_id_i;

    IF v_sync_id IS NULL THEN
        SET returnCode_o = 600;
        SET returnMsg_o = 'syncService_id_i is wrong.';
        CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    IF cur_weight_after_selected_i IS NULL THEN
        SET returnCode_o = 600;
        SET returnMsg_o = 'cur_weight_after_selected_i should not be null.';
        CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    /*check one side if there is any configuration data*/
    IF EXISTS (SELECT 1 FROM msg_queues.`queue_workflows` WHERE double_side = 0) THEN
        SELECT cnt,queue_type INTO v_cnt, v_queue_type
          FROM
          (
              SELECT COUNT(*) AS cnt,GROUP_CONCAT(queue_type) AS queue_type FROM
              (
                 SELECT  a.queue_type
                   FROM (SELECT * FROM msg_queues.`queue_workflows` WHERE uri IS NOT NULL AND double_side = 0) a
                   LEFT JOIN msg_queues.`service_parameters` b
                     ON a.queue_type=b.queue_type AND a.queue_step=b.queue_step
                  WHERE b.var_name IS  NULL
              ) t
          ) c;

        IF v_cnt > 0 THEN
            SET returnCode_o = 651;
            SET returnMsg_o = CONCAT(v_queue_type, ' ,one side need config service_parameters.');
            CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
            LEAVE ll;
        END IF;

    END IF;

    SET v_unsynced_sys_lock = GET_LOCK(v_lock_name,1);
    IF v_unsynced_sys_lock <> 1 THEN
        SET returnCode_o = 652;
        SET returnMsg_o = 'get lock timeout.';
        CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    SET returnMsg_o = 'create temp_gusq_unsync_queue.';
    CREATE TEMPORARY TABLE IF NOT EXISTS msg_queues.`temp_gusq_unsync_queue` (
      `id`                        BIGINT NOT NULL,
      `queue_id`                  BIGINT,
      `queue_type`                VARCHAR(50),
      `queue_step`                TINYINT,
      `queues`                    LONGTEXT,
      `status`                    TINYINT,
      `source_endpoint_info`      VARCHAR(100),
      `dst_endpoint_info`         VARCHAR(100),
      `cycle_cnt`                 INT,
      `create_time`               DATETIME,
      `last_update_time`          DATETIME,
      `is_delete`                 TINYINT,
      `is_re_assign_endpoint`     TINYINT,
      `remark`                    VARCHAR(300),
      `dst_queue_type`            VARCHAR(50),
      `dst_queue_step`            TINYINT,
      `last_sync_queue_id`        BIGINT,
      `double_side`               INT,
      `repeat_count`              INT,
      `is_missing`                INT,
      KEY `queue_type_idx` (`queue_type`)
    ) ENGINE=InnoDB;
    TRUNCATE TABLE msg_queues.`temp_gusq_unsync_queue`;

    CREATE TEMPORARY TABLE IF NOT EXISTS msg_queues.`temp_gusq_unsync_queue_limit` LIKE msg_queues.`temp_gusq_unsync_queue`;
    TRUNCATE TABLE msg_queues.`temp_gusq_unsync_queue_limit`;


    CREATE TEMPORARY TABLE IF NOT EXISTS msg_queues.`temp_gusq_unsync_queue_limit2` LIKE msg_queues.`temp_gusq_unsync_queue`;
    TRUNCATE TABLE msg_queues.`temp_gusq_unsync_queue_limit2`;

    CREATE TEMPORARY TABLE IF NOT EXISTS msg_queues.`temp_gusq_sync_service_cfg` (
      `syncService_id`            VARCHAR(100),
      `endpoint_id`               VARCHAR(100),
      `endpoint_ip`               VARCHAR(20),
      `endpoint_port`             VARCHAR(20),
      `queue_type`                VARCHAR(50),
      `sync_id`                   INT,
      `cur_weight_after_selected` TEXT
    ) ENGINE=InnoDB;
    TRUNCATE TABLE msg_queues.`temp_gusq_sync_service_cfg`;

    CREATE TEMPORARY TABLE IF NOT EXISTS  msg_queues.`temp_gusq_last_sync_id` (
      `queue_type`                VARCHAR(50),
      `dst_endpoint_info`         VARCHAR(100),
      `last_sync_queue_id`        BIGINT
    ) ENGINE=InnoDB;
    TRUNCATE TABLE msg_queues.`temp_gusq_last_sync_id`;


    CREATE TEMPORARY TABLE IF NOT EXISTS  msg_queues.`temp_gusq_begin_unsync_id` (
      `queue_id`                  BIGINT,
      `queue_type`                VARCHAR(50),
      `dst_endpoint_info`         VARCHAR(100)
    ) ENGINE=InnoDB;
    TRUNCATE TABLE msg_queues.`temp_gusq_begin_unsync_id`;

    CREATE TEMPORARY TABLE IF NOT EXISTS  msg_queues.`temp_gusq_last_receive_info` (
      `last_sync_queue_id`        BIGINT,
      `source_queue_type`         VARCHAR(50),
      `dst_endpoint_info`         VARCHAR(100),
      `dst_queue_type`            VARCHAR(50),
      `dst_queue_step`            TINYINT,
      `double_side`               INT,
      KEY `que_type_dst_idx` (`source_queue_type`,`dst_endpoint_info`)
    ) ENGINE=InnoDB;
    TRUNCATE TABLE msg_queues.`temp_gusq_last_receive_info`;

    CREATE TEMPORARY TABLE IF NOT EXISTS  msg_queues.`temp_gusq_final_queue` (
      `uri`                    VARCHAR(100),
      `msgs`                   LONGTEXT,
      `method`                 VARCHAR(50),
      `last_synced_id`         BIGINT(20),
      `current_check_list`     LONGTEXT,
      `source_queue_type`      VARCHAR(50),
      `dst_queue_type`         VARCHAR(50),
      `dst_queue_step`         INT(11),
      `dst_endpoint_info`      VARCHAR(100),
      `double_side`            INT(11)
    ) ENGINE=InnoDB;
    TRUNCATE TABLE msg_queues.`temp_gusq_final_queue`;

    SET returnMsg_o = 'update temp_gusq_sync_service_cfg.';
    SET v_sql = CONCAT('INSERT INTO msg_queues.`temp_gusq_sync_service_cfg`(syncService_id,endpoint_id,endpoint_ip,endpoint_port,queue_type,cur_weight_after_selected) VALUES ', cur_weight_after_selected_i);
    CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);

    UPDATE msg_queues.`temp_gusq_sync_service_cfg`
       SET sync_id = v_sync_id;

    SET returnMsg_o = 'update sync_service_config.';
    UPDATE msg_queues.`sync_service_config` a,
           msg_queues.`temp_gusq_sync_service_cfg` b
       SET a.cur_weight_after_selected = b.cur_weight_after_selected
     WHERE a.sync_id = b.sync_id
       AND a.endpoint_id = b.endpoint_id
       AND a.endpoint_ip = b.endpoint_ip
       AND a.endpoint_port = b.endpoint_port
       AND a.queue_type = b.queue_type;


    IF last_receive_info_i IS NOT NULL AND last_receive_info_i <> '' THEN
        #get missing data
        SET returnMsg_o = 'get last_receive_info.';
        SET v_sql = CONCAT('INSERT INTO msg_queues.`temp_gusq_last_receive_info`(last_sync_queue_id, source_queue_type, dst_endpoint_info, dst_queue_type) VALUES ', last_receive_info_i);
        CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);

        SET returnMsg_o = 'get v_queue_step.';
        UPDATE msg_queues.`temp_gusq_last_receive_info` a,
               msg_queues.`queue_workflows` b
           SET a.dst_queue_step = b.dst_queue_step,
               a.double_side = b.double_side
         WHERE a.source_queue_type = b.queue_type
           AND a.dst_queue_type = b.dst_queue_type;

        IF EXISTS (SELECT 1 FROM msg_queues.`temp_gusq_last_receive_info` WHERE dst_queue_step IS NULL) THEN
            SET returnCode_o = 600;
            SET returnMsg_o = 'check input dst_queue_type and source_queue_type invalid .';
            SET v_unsynced_sys_lock = RELEASE_LOCK(v_lock_name);
            TRUNCATE TABLE msg_queues.`temp_gusq_unsync_queue`;
            TRUNCATE TABLE msg_queues.`temp_gusq_unsync_queue_limit`;
            TRUNCATE TABLE msg_queues.`temp_gusq_unsync_queue_limit2`;
            TRUNCATE TABLE msg_queues.`temp_gusq_sync_service_cfg`;
            TRUNCATE TABLE msg_queues.`temp_gusq_last_sync_id`;
            TRUNCATE TABLE msg_queues.`temp_gusq_begin_unsync_id`;
            TRUNCATE TABLE msg_queues.`temp_gusq_final_queue`;
            DROP TABLE IF EXISTS msg_queues.`temp_gusq_final_queue`;            
            DROP TABLE IF EXISTS msg_queues.`temp_gusq_unsync_queue`;
            DROP TABLE IF EXISTS msg_queues.`temp_gusq_unsync_queue_limit`;
            DROP TABLE IF EXISTS msg_queues.`temp_gusq_unsync_queue_limit2`;
            DROP TABLE IF EXISTS msg_queues.`temp_gusq_sync_service_cfg`;
            DROP TABLE IF EXISTS msg_queues.`temp_gusq_last_sync_id`;
            DROP TABLE IF EXISTS msg_queues.`temp_gusq_begin_unsync_id`;
            CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
            LEAVE ll;
        END IF;

        ## Reset the data that has been sent only
        SET returnMsg_o = 'get data that has been sent only.';
        SELECT GROUP_CONCAT(CONCAT('(',a.id, ',',
               a.queue_id, ',''',
               a.queue_type, ''',',
               a.queue_step, ',''',
               a.queues, ''',',
               a.`status`, ',''',
               a.source_endpoint_info,''',''',
               a.dst_endpoint_info, ''',',
               a.cycle_cnt, ',''',
               a.create_time, ''',',
               a.is_delete, ',',
               1,',',
               a.is_re_assign_endpoint, ')')
               )
          INTO v_value
          FROM msg_queues.`queues` a,
               msg_queues.`temp_gusq_last_receive_info` b
         WHERE a.queue_id > b.last_sync_queue_id
           AND a.queue_type = b.source_queue_type
           AND a.dst_endpoint_info = b.dst_endpoint_info
           AND a.queue_step > b.dst_queue_step;

        IF IFNULL(v_value, '') <> '' THEN
            SET returnMsg_o = 'Insert data that has been sent only.';
            SET v_sql = CONCAT('INSERT INTO msg_queues.`temp_gusq_unsync_queue`(id,queue_id,queue_type,queue_step,queues,`status`,source_endpoint_info,dst_endpoint_info,cycle_cnt,create_time,is_delete,is_missing,is_re_assign_endpoint) VALUES', v_value);
            CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);
        END IF;

        SET returnMsg_o = 'the data that has been sent only need reset cycle_cnt.';
        UPDATE msg_queues.`temp_gusq_unsync_queue` a,
               msg_queues.`temp_gusq_last_receive_info` b
           SET a.queue_step = b.dst_queue_step,
               a.cycle_cnt = 1,
               a.last_update_time = UTC_TIMESTAMP(),
               a.is_delete = 0,
               a.double_side = b.double_side,
               a.dst_queue_type = b.dst_queue_type,
               a.dst_queue_step = b.dst_queue_step
         WHERE a.queue_type = b.source_queue_type
           AND a.dst_endpoint_info = b.dst_endpoint_info;
    END IF;

    ## get data that need to be sent
    START TRANSACTION;
    SET returnMsg_o = 'get value from queues.';
    SELECT GROUP_CONCAT(CONCAT('(',a.id, ',',
           a.queue_id, ',''',
           a.queue_type, ''',',
           a.queue_step, ',''',
           a.queues, ''',',
           a.`status`, ',''',
           a.source_endpoint_info,''',',
           CASE WHEN a.dst_endpoint_info IS NULL THEN 'NULL' ELSE CONCAT('''',a.dst_endpoint_info,'''') END,',',
           a.cycle_cnt + 1, ',''',
           a.create_time, ''',''',
           a.last_update_time, ''',',
           a.is_delete, ',',
           b.double_side, ',''',
           b.dst_queue_type, ''',',
           CASE WHEN b.dst_queue_step IS NULL THEN 'NULL' ELSE b.dst_queue_step END,',',
           b.repeat_count, ',',
           a.is_re_assign_endpoint, ')')
           )
      INTO v_value
      FROM msg_queues.`queues` a,
           msg_queues.`queue_workflows` b
     WHERE a.queue_type = b.queue_type
       AND a.queue_step = b.queue_step
       AND CASE WHEN b.double_side = 0 THEN CAST(b.uri AS CHAR) ELSE CAST(b.dst_queue_type AS CHAR(50)) END IS NOT NULL;

    SET returnMsg_o = 'INSERT INTO temp_gusq_unsync_queue.';
    IF IFNULL(v_value, '') <> '' THEN
        SET v_sql = CONCAT('INSERT INTO msg_queues.`temp_gusq_unsync_queue`(id, queue_id, queue_type,queue_step, queues, `status`, source_endpoint_info, dst_endpoint_info, cycle_cnt, create_time, last_update_time, is_delete, double_side, dst_queue_type, dst_queue_step, repeat_count,is_re_assign_endpoint) VALUES', v_value);
        CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);
    END IF;

    SET returnMsg_o = 'insert into roll_back_queues.';
    INSERT INTO msg_queues.`roll_back_queues`(id,queue_id,queue_type,queue_step,queues,`status`,source_endpoint_info,dst_endpoint_info,cycle_cnt,create_time,is_delete)
         SELECT id, queue_id, queue_type, queue_step, queues, `status`,source_endpoint_info, dst_endpoint_info, cycle_cnt,create_time, is_delete
           FROM msg_queues.`temp_gusq_unsync_queue` a
          WHERE a.is_re_assign_endpoint = 1
            AND ( (a.cycle_cnt > a.repeat_count AND a.repeat_count > 0 AND a.is_missing IS NULL) OR a.is_missing = 1 )
             ON DUPLICATE KEY UPDATE queue_id = a.queue_id,
                                     queue_type = a.queue_type,
                                     queue_step = a.queue_step,
                                     queues = a.queues,
                                     `status` = a.`status`,
                                     source_endpoint_info = a.source_endpoint_info,
                                     dst_endpoint_info = a.dst_endpoint_info,
                                     cycle_cnt = a.cycle_cnt,
                                     create_time = a.create_time,
                                     is_delete = a.is_delete;

    SET returnMsg_o = 'send times great threshold need reset queues.';
    UPDATE msg_queues.`temp_gusq_unsync_queue` a
       SET a.cycle_cnt = 1,
           a.dst_endpoint_info = NULL,
           a.last_update_time = UTC_TIMESTAMP()
     WHERE a.cycle_cnt > a.repeat_count
       AND a.repeat_count > 0
       AND a.is_missing IS NULL;

    SET returnMsg_o = 'reset dst_queue_info';
    OPEN cur_next_serv;
    S:REPEAT
        FETCH cur_next_serv INTO v_queue_type, v_dst_queue_type;
        IF NOT done THEN
            CALL msg_queues.`get_next_server`(syncService_id_i , v_dst_queue_type, v_cur_endpoint_info, v_returnCode, v_returnMsg);
            IF v_returnCode <> 200 THEN
                ROLLBACK;
                SET v_unsynced_sys_lock = RELEASE_LOCK(v_lock_name);
                SET returnMsg_o = v_returnMsg;
                TRUNCATE TABLE msg_queues.`temp_gusq_unsync_queue`;
                TRUNCATE TABLE msg_queues.`temp_gusq_unsync_queue_limit`;
                TRUNCATE TABLE msg_queues.`temp_gusq_unsync_queue_limit2`;
                TRUNCATE TABLE msg_queues.`temp_gusq_sync_service_cfg`;
                TRUNCATE TABLE msg_queues.`temp_gusq_last_sync_id`;
                TRUNCATE TABLE msg_queues.`temp_gusq_begin_unsync_id`;
                TRUNCATE TABLE msg_queues.`temp_gusq_final_queue`;
                DROP TABLE IF EXISTS msg_queues.`temp_gusq_final_queue`;               
                DROP TABLE IF EXISTS msg_queues.`temp_gusq_unsync_queue`;
                DROP TABLE IF EXISTS msg_queues.`temp_gusq_unsync_queue_limit`;
                DROP TABLE IF EXISTS msg_queues.`temp_gusq_unsync_queue_limit2`;
                DROP TABLE IF EXISTS msg_queues.`temp_gusq_sync_service_cfg`;
                DROP TABLE IF EXISTS msg_queues.`temp_gusq_last_sync_id`;
                DROP TABLE IF EXISTS msg_queues.`temp_gusq_begin_unsync_id`;
                LEAVE ll;
            END IF;

            SET returnMsg_o = 'update dst_endpoint_info';
            UPDATE msg_queues.`temp_gusq_unsync_queue`
               SET dst_endpoint_info = v_cur_endpoint_info
             WHERE is_missing IS NULL
               AND dst_endpoint_info IS NULL
               AND queue_type = v_queue_type;
        END IF;
    UNTIL done END REPEAT;
    CLOSE cur_next_serv;


    SET returnMsg_o = 'get begin_unsync_queue_id';
    INSERT INTO msg_queues.`temp_gusq_begin_unsync_id`(queue_id,queue_type,dst_endpoint_info)
         SELECT MIN(queue_id),queue_type,dst_endpoint_info
           FROM msg_queues.`temp_gusq_unsync_queue` a
          GROUP BY a.queue_type,a.dst_endpoint_info;

    SET returnMsg_o = 'calculate last_sync_queue_id';
    INSERT INTO msg_queues.`temp_gusq_last_sync_id`(queue_type,dst_endpoint_info,last_sync_queue_id)
         SELECT a.queue_type,a.dst_endpoint_info,IFNULL(MAX(b.queue_id),0)
           FROM msg_queues.`temp_gusq_begin_unsync_id` a
           LEFT JOIN msg_queues.`queues` b
             ON a.queue_type = b.queue_type
            AND a.dst_endpoint_info = b.dst_endpoint_info
            AND b.queue_id < a.queue_id
          GROUP BY a.queue_type,a.dst_endpoint_info;


    SET returnMsg_o = 'update last_sync_queue_id';
    UPDATE msg_queues.`temp_gusq_unsync_queue` a,
           msg_queues.`temp_gusq_last_sync_id` b
       SET a.last_sync_queue_id = b.last_sync_queue_id
     WHERE a.queue_type = b.queue_type
       AND a.dst_endpoint_info = b.dst_endpoint_info;

    SET done = 0;
    OPEN cur_queue_type;
    myrepeat:REPEAT
        FETCH cur_queue_type INTO v_queue_type, v_limit;
        IF NOT done THEN
            SET returnMsg_o = 'insert into temp_gusq_unsync_queue_limit';
            SET v_sql = CONCAT('INSERT INTO msg_queues.`temp_gusq_unsync_queue_limit`(id, queue_id, queue_type,queue_step, queues, `status`, source_endpoint_info, dst_endpoint_info, cycle_cnt, last_update_time, is_delete, double_side, dst_queue_type, dst_queue_step, last_sync_queue_id)
                 SELECT a.id, a.queue_id, a.queue_type, a.queue_step, a.queues, a.`status`, a.source_endpoint_info, a.dst_endpoint_info, a.cycle_cnt, a.last_update_time, a.is_delete, a.double_side, a.dst_queue_type ,a.dst_queue_step, a.last_sync_queue_id
                   FROM msg_queues.`temp_gusq_unsync_queue` a
                  WHERE a.queue_type =''',  v_queue_type,
                  ''' ORDER BY a.queue_id,a.id ');
            IF v_limit > 0 THEN
                SET v_sql = CONCAT( v_sql, 'LIMIT ', v_limit);
            END IF;

            CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);
        END IF;
    UNTIL done END REPEAT;
    CLOSE cur_queue_type;

    UPDATE msg_queues.`queues` a,
           msg_queues.`temp_gusq_unsync_queue_limit` b
       SET a.dst_endpoint_info = b.dst_endpoint_info,
           a.cycle_cnt = b.cycle_cnt,
           a.last_update_time = b.last_update_time,
           a.queue_step = b.queue_step,
           a.is_delete = b.is_delete
     WHERE a.id = b.id;

    SET returnMsg_o = 'insert into temp_gusq_unsync_queue_limit2';
    INSERT INTO msg_queues.`temp_gusq_unsync_queue_limit2` SELECT * FROM msg_queues.temp_gusq_unsync_queue_limit;
    COMMIT;

    INSERT INTO msg_queues.`temp_gusq_final_queue`(uri,msgs,method,last_synced_id,current_check_list,source_queue_type,dst_queue_type,dst_queue_step,dst_endpoint_info,double_side)
    SELECT t.uri,GROUP_CONCAT(msgs) AS msgs,MAX(method) AS method,MAX(last_sync_queue_id) AS last_synced_id,GROUP_CONCAT(queue_id) AS current_check_list ,
           source_queue_type,MAX(dst_queue_type) AS dst_queue_type, MAX(dst_queue_step) AS dst_queue_step, dst_endpoint_info, MAX(double_side) AS double_side
    FROM
    (
        SELECT CONCAT('/msg_management/',a.dst_queue_type,'/data') AS uri, CONCAT('(', a.queue_id,',''',  a.queues, ''',', a.status, ')') AS msgs ,c.method,a.last_sync_queue_id,a.queue_id,
                a.queue_type AS source_queue_type,a.dst_queue_type ,a.dst_queue_step, a.dst_endpoint_info, a.double_side
          FROM `temp_gusq_unsync_queue_limit` a, `queue_workflows` c
         WHERE a.queue_type = c.queue_type
           AND a.queue_step = c.queue_step
           AND a.double_side = 1
    ) t
    GROUP BY t.uri,t.dst_endpoint_info,t.source_queue_type;
    
    INSERT INTO msg_queues.`temp_gusq_final_queue`(uri,msgs,method,last_synced_id,current_check_list,source_queue_type,dst_queue_type,dst_queue_step,dst_endpoint_info,double_side)
    SELECT t.uri,GROUP_CONCAT(msgs) AS msgs,MAX(method) AS method,MAX(last_sync_queue_id) AS last_synced_id,GROUP_CONCAT(queue_id) AS current_check_list ,
           source_queue_type,MAX(dst_queue_type) AS dst_queue_type, MAX(dst_queue_step) AS dst_queue_step, dst_endpoint_info, MAX(double_side) AS double_side
    FROM
    (
        SELECT CONCAT(c.uri,'?', msg_queues.`getParameters`(a.queue_type, a.queue_step, a.queues)) AS uri, CONCAT('(', a.queue_id,',''', msg_queues.`getBody`(a.queue_type, a.queue_step, a.queues), ''',', a.status, ')') AS msgs ,c.method,a.last_sync_queue_id,a.queue_id,
                a.queue_type AS source_queue_type,a.dst_queue_type ,a.dst_queue_step, a.dst_endpoint_info, a.double_side
          FROM `temp_gusq_unsync_queue_limit2` a, `queue_workflows` c
         WHERE a.queue_type = c.queue_type
           AND a.queue_step = c.queue_step
           AND a.double_side = 0
    ) t
    GROUP BY t.uri,t.dst_endpoint_info,t.source_queue_type;
    
    SELECT DISTINCT uri,msgs,method,last_synced_id,current_check_list,source_queue_type,dst_queue_type,dst_queue_step,dst_endpoint_info,double_side
      FROM msg_queues.`temp_gusq_final_queue`;

    SET v_unsynced_sys_lock = RELEASE_LOCK(v_lock_name);
    TRUNCATE TABLE msg_queues.`temp_gusq_unsync_queue`;
    TRUNCATE TABLE msg_queues.`temp_gusq_unsync_queue_limit`;
    TRUNCATE TABLE msg_queues.`temp_gusq_unsync_queue_limit2`;
    TRUNCATE TABLE msg_queues.`temp_gusq_sync_service_cfg`;
    TRUNCATE TABLE msg_queues.`temp_gusq_last_sync_id`;
    TRUNCATE TABLE msg_queues.`temp_gusq_begin_unsync_id`;
    TRUNCATE TABLE msg_queues.`temp_gusq_final_queue`;
    DROP TABLE IF EXISTS msg_queues.`temp_gusq_final_queue`;
    DROP TABLE IF EXISTS msg_queues.`temp_gusq_unsync_queue`;
    DROP TABLE IF EXISTS msg_queues.`temp_gusq_unsync_queue_limit`;
    DROP TABLE IF EXISTS msg_queues.`temp_gusq_unsync_queue_limit2`;
    DROP TABLE IF EXISTS msg_queues.`temp_gusq_sync_service_cfg`;
    DROP TABLE IF EXISTS msg_queues.`temp_gusq_last_sync_id`;
    DROP TABLE IF EXISTS msg_queues.`temp_gusq_begin_unsync_id`;


    SET returnCode_o = 200;
    SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);

END$$

DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;