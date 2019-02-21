USE `msg_queues`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `get_un_synced_queue` */;

DROP PROCEDURE IF EXISTS `get_un_synced_queue`;

DELIMITER $$

CREATE PROCEDURE `get_un_synced_queue`(
    user_i                      INT,
    last_receive_info_i         LONGTEXT,
    syncService_id_i            VARCHAR(100),
    cur_weight_after_selected_i LONGTEXT,
    OUT returnCode_o            INT,
    OUT returnMsg_o             LONGTEXT)
ll:BEGIN
    DECLARE v_unsynced_sys_lock           INT;
    DECLARE v_sync_id                     INT;
    DECLARE v_procname                    VARCHAR(50) DEFAULT 'get_un_synced_queue';
    DECLARE v_modulename                  VARCHAR(50) DEFAULT 'messageManager';
    DECLARE v_params_body                 LONGTEXT DEFAULT NULL;
    DECLARE v_queue_type                  VARCHAR(50);
    DECLARE v_endpoint_infos              LONGTEXT;
    DECLARE v_queue_types                 VARCHAR(50);
    DECLARE v_cnt                         INT;
    DECLARE v_sql                         LONGTEXT;
    DECLARE v_returnCode                  INT;
    DECLARE v_returnMsg                   LONGTEXT;

    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        SET v_unsynced_sys_lock = RELEASE_LOCK('get_un_synced_queue_lock');
        ROLLBACK;
        TRUNCATE TABLE msg_queues.`temp_gusq_last_receive_info`;
        TRUNCATE TABLE msg_queues.`temp_gusq_unsync_queue`;
        TRUNCATE TABLE msg_queues.`temp_gusq_unsync_queue_limit`;
        TRUNCATE TABLE msg_queues.`temp_gusq_sync_service_cfg`;
        TRUNCATE TABLE msg_queues.`temp_gusq_dst_endpoint_info`;
        TRUNCATE TABLE msg_queues.`temp_gusq_begin_unsync_id`;
        DROP TABLE IF EXISTS msg_queues.`temp_gusq_last_receive_info`;
        DROP TABLE IF EXISTS msg_queues.`temp_gusq_unsync_queue`;
        DROP TABLE IF EXISTS msg_queues.`temp_gusq_unsync_queue_limit`;
        DROP TABLE IF EXISTS msg_queues.`temp_gusq_sync_service_cfg`;
        DROP TABLE IF EXISTS msg_queues.`temp_gusq_dst_endpoint_info`;
        DROP TABLE IF EXISTS msg_queues.`temp_gusq_begin_unsync_id`;
        CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,cur_weight_after_selected_i,returnMsg_o,v_returnCode,v_returnMsg);
    END;

    SET SESSION group_concat_max_len = 4294967295;
    SET returnCode_o = 400;
    SET returnMsg_o =  CONCAT(v_modulename, ' ', v_procname, ' command Error');
    SET v_params_body = CONCAT('{"syncService_id_i":"',IFNULL(syncService_id_i,'NULL'), '","last_receive_info_i":"', IFNULL(REPLACE(last_receive_info_i,'"',''),'NULL'), '"}');
    SET cur_weight_after_selected_i = IFNULL(TRIM(cur_weight_after_selected_i),'');
    SET syncService_id_i = TRIM(syncService_id_i);
    SET last_receive_info_i = TRIM(last_receive_info_i);

    SET returnMsg_o = 'fail to check input syncService_id_i&cur_weight_after_selected_i null data.';
    IF IFNULL(syncService_id_i,'') = '' OR IFNULL(cur_weight_after_selected_i,'') = '' THEN
        SET returnCode_o = 600;
        CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,cur_weight_after_selected_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'fail to check syncService_id_i exists.';
    SELECT MAX(id)
      INTO v_sync_id
      FROM msg_queues.`sync_service`
     WHERE syncService_id = syncService_id_i;
    IF v_sync_id IS NULL THEN
        SET returnCode_o = 651;
        CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,cur_weight_after_selected_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;

    /*check one side if there is any configuration data*/
    SET returnMsg_o = 'exists one side has no config service_parameters.';
    SELECT COUNT(1)
      INTO v_cnt
      FROM msg_queues.`queue_workflows` a
      LEFT 
      JOIN msg_queues.service_parameters b ON a.queue_type  = b.queue_type AND a.queue_step = b.queue_step 
     WHERE IFNULL(a.uri,'') <> ''
       AND a.double_side = 0 
       AND b.id IS NULL;
        
    IF v_cnt > 0 THEN
        SET returnCode_o = 652;
        CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,cur_weight_after_selected_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'get lock timeout.';
    SET v_unsynced_sys_lock = GET_LOCK('get_un_synced_queue_lock',180);
    IF v_unsynced_sys_lock <> 1 THEN
        SET returnCode_o = 653;
        CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,cur_weight_after_selected_i,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'create temp_gusq_unsync_queue.';
    CREATE TEMPORARY TABLE IF NOT EXISTS  msg_queues.`temp_gusq_last_receive_info` (
      `last_sync_queue_id`        BIGINT,
      `source_queue_type`         VARCHAR(50),
      `source_queue_step`         TINYINT,
      `dst_endpoint_info`         VARCHAR(100),
      `dst_queue_type`            VARCHAR(50),
      `dst_queue_step`            TINYINT,
      `double_side`               INT,
      `config_repeat_count`       INT,
      `uri`                       VARCHAR(50),
      `method`                    VARCHAR(50),
      `if_limited`                INT,
      KEY `que_type_dst_idx`      (`source_queue_type`),
      KEY `dstep_idx`             (`dst_endpoint_info`)
    ) ENGINE=InnoDB;
    TRUNCATE TABLE msg_queues.`temp_gusq_last_receive_info`;

    CREATE TEMPORARY TABLE IF NOT EXISTS msg_queues.`temp_gusq_unsync_queue` (
      `id`                        BIGINT NOT NULL,
      `queue_id`                  BIGINT,
      `main_queue_info`           VARCHAR(255),
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
      `if_rollback`               INT NOT NULL DEFAULT 0,
      `uri`                       LONGTEXT,
      `method`                    VARCHAR(50),
      `orig_dst_endpoint_info`    VARCHAR(100),
      `orig_cycle_cnt`            INT,
      `new_id`                    BIGINT(20),
      `if_limited`                INT,
      `body`                      LONGTEXT,
      `parameter`                 LONGTEXT,
      PRIMARY KEY                 (`id`),
      KEY `queue_type_idx`        (`queue_type`,`queue_step`)
    ) ENGINE=InnoDB;
    TRUNCATE TABLE msg_queues.`temp_gusq_unsync_queue`;
    
    CREATE TEMPORARY TABLE IF NOT EXISTS msg_queues.temp_gusq_unsync_queue_limit(
      `id`                        BIGINT NOT NULL,
      `queue_id`                  BIGINT,
      `queue_type`                VARCHAR(50),
      `queue_step`                TINYINT,
      `new_id`                    BIGINT(20),
      PRIMARY KEY                 (`id`),
      KEY `new_id_idx`            (`new_id`),
      KEY `queue_ts_idx`          (`queue_type`,`queue_step`) 
    ) ENGINE=InnoDB;
    TRUNCATE TABLE msg_queues.`temp_gusq_unsync_queue_limit`;

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

    CREATE TEMPORARY TABLE IF NOT EXISTS  msg_queues.`temp_gusq_dst_endpoint_info` (
      `queue_type`                VARCHAR(50),
      `dst_endpoint_info`         VARCHAR(100),
      KEY `que_type_dst_idx`      (`queue_type`)
    ) ENGINE=InnoDB;
    TRUNCATE TABLE msg_queues.`temp_gusq_dst_endpoint_info`;

    CREATE TEMPORARY TABLE IF NOT EXISTS  msg_queues.`temp_gusq_begin_unsync_id` (
      `queue_id`                       BIGINT,
      `queue_type`                     VARCHAR(50),
      `dst_endpoint_info`              VARCHAR(100),
      KEY `queue_id_idx`               (`queue_id`),
      KEY `queue_type_idx`             (`queue_type`),
      KEY `dst_endpoint_info_idx`      (`dst_endpoint_info`)
    ) ENGINE=InnoDB;
    TRUNCATE TABLE msg_queues.`temp_gusq_begin_unsync_id`;

    #get missing data
    IF IFNULL(last_receive_info_i,'') <> '' THEN
        SET returnMsg_o = 'fail to insert data into temp_gusq_last_receive_info.';
        SET v_sql = CONCAT('INSERT INTO msg_queues.`temp_gusq_last_receive_info`(last_sync_queue_id, source_queue_type, dst_endpoint_info, dst_queue_type) VALUES ', last_receive_info_i);
        CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);

        SET returnMsg_o = 'fail to get v_queue_step.';
        UPDATE msg_queues.`temp_gusq_last_receive_info` a,
               msg_queues.`queue_workflows` b
           SET a.source_queue_step = b.queue_step,
               a.dst_queue_step = b.dst_queue_step,
               a.double_side = b.double_side,
               a.config_repeat_count = b.repeat_count,
               a.`uri` = IF(IFNULL(b.`uri`,'') = '',CONCAT('/msg_management/',b.dst_queue_type,'/data'), b.`uri`),
               a.method = b.method,
               a.if_limited = CASE WHEN b.`limit` = 0 THEN 0 ELSE 1 END
         WHERE a.source_queue_type = b.queue_type
           AND a.dst_queue_type = b.dst_queue_type;

        SET returnMsg_o = 'check input dst_queue_type and source_queue_type invalid .';
        IF EXISTS (SELECT 1 FROM msg_queues.`temp_gusq_last_receive_info` WHERE source_queue_step IS NULL) THEN
            SET returnCode_o = 654;
            SET v_unsynced_sys_lock = RELEASE_LOCK('get_un_synced_queue_lock');
            TRUNCATE TABLE msg_queues.`temp_gusq_last_receive_info`;
            TRUNCATE TABLE msg_queues.`temp_gusq_unsync_queue`;
            TRUNCATE TABLE msg_queues.`temp_gusq_unsync_queue_limit`;
            TRUNCATE TABLE msg_queues.`temp_gusq_sync_service_cfg`;
            TRUNCATE TABLE msg_queues.`temp_gusq_dst_endpoint_info`;
            TRUNCATE TABLE msg_queues.`temp_gusq_begin_unsync_id`;
            DROP TABLE IF EXISTS msg_queues.`temp_gusq_last_receive_info`;
            DROP TABLE IF EXISTS msg_queues.`temp_gusq_unsync_queue`;
            DROP TABLE IF EXISTS msg_queues.`temp_gusq_unsync_queue_limit`;
            DROP TABLE IF EXISTS msg_queues.`temp_gusq_sync_service_cfg`;
            DROP TABLE IF EXISTS msg_queues.`temp_gusq_dst_endpoint_info`;
            DROP TABLE IF EXISTS msg_queues.`temp_gusq_begin_unsync_id`;
            CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,cur_weight_after_selected_i,returnMsg_o,v_returnCode,v_returnMsg);
            LEAVE ll;
        END IF;

        ## Reset the missing data
        SET returnMsg_o = 'fail to get data that has been sent only.';
        SELECT CASE WHEN COUNT(1) = 0 THEN ''
                    ELSE CONCAT('INSERT INTO msg_queues.`temp_gusq_unsync_queue`(id,queue_id,main_queue_info,queue_type,queue_step,queues,`status`,source_endpoint_info,dst_endpoint_info,cycle_cnt,create_time,is_delete,is_re_assign_endpoint,dst_queue_type,dst_queue_step,double_side,last_update_time,if_rollback,`uri`,orig_dst_endpoint_info,orig_cycle_cnt,method,if_limited,parameter,body) VALUES ',
                                 GROUP_CONCAT('(',a.id, ',',
                                     a.queue_id, ',''',
                                     IFNULL(a.main_queue_info,''),''',''',
                                     a.queue_type, ''',',
                                     b.source_queue_step, ',''',
                                     a.queues, ''',',
                                     a.`status`, ',''',
                                     a.source_endpoint_info,''',''',
                                     (CASE WHEN a.is_re_assign_endpoint = 1 AND a.cycle_cnt > b.config_repeat_count THEN '' ELSE IFNULL(a.dst_endpoint_info,'') END ), ''',',
                                     (CASE WHEN a.is_re_assign_endpoint = 1 AND a.cycle_cnt > b.config_repeat_count THEN 1 ELSE a.cycle_cnt + 1 END ), ',''',
                                     a.create_time, ''',',
                                     0, ',',
                                     a.is_re_assign_endpoint, ',''',
                                     b.dst_queue_type, ''',',
                                     b.dst_queue_step,',',
                                     b.double_side,',''',
                                     UTC_TIMESTAMP(),''',',
                                     (CASE WHEN a.is_re_assign_endpoint = 1 AND a.cycle_cnt > b.config_repeat_count THEN 1 ELSE 0 END ),',''',
                                     b.`uri`,''',''',
                                     IFNULL(a.dst_endpoint_info,''), ''',',
                                     a.cycle_cnt,',''',
                                     b.method,''',',
                                     b.if_limited,',''',
                                     IFNULL(SUBSTRING_INDEX(SUBSTRING_INDEX(a.queues,'|$|',e.parameter_val_pos),'|$|',-1),''),''',''',
                                     IFNULL(SUBSTRING_INDEX(SUBSTRING_INDEX(a.queues,'|$|',e.body_val_pos),'|$|',-1),''),''')')) END
          INTO v_sql 
          FROM msg_queues.`queues` a
         INNER 
          JOIN msg_queues.`temp_gusq_last_receive_info` b on a.queue_id > b.last_sync_queue_id AND a.queue_type = b.source_queue_type  AND a.dst_endpoint_info = b.dst_endpoint_info  AND a.queue_step >= b.source_queue_step
         INNER 
          JOIN  (SELECT DISTINCT queue_type FROM msg_queues.sync_service_config WHERE sync_id = v_sync_id ) c on  a.queue_type = c.queue_type
          LEFT 
          JOIN msg_queues.service_parameters e  ON a.queue_type =e.queue_type AND a.queue_step = e.queue_step;

        IF IFNULL(v_sql, '') <> '' THEN
            CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);
        END IF;
    END IF;

    ## get data that need to be sent
    SET returnMsg_o = 'get value from queues.';
    SELECT CASE WHEN COUNT(1) = 0 THEN ''
            ELSE CONCAT('INSERT INTO msg_queues.`temp_gusq_unsync_queue`(id,queue_id,main_queue_info,queue_type,queue_step,queues,`status`,source_endpoint_info,dst_endpoint_info,cycle_cnt,create_time,is_delete,is_re_assign_endpoint,dst_queue_type,dst_queue_step,double_side,last_update_time,if_rollback,`uri`,orig_dst_endpoint_info,orig_cycle_cnt,method,if_limited,parameter,body) VALUES ',
                         GROUP_CONCAT('(',a.id, ',',
                             a.queue_id, ',''',
                             IFNULL(a.main_queue_info,''),''',''',
                             a.queue_type, ''',',
                             a.queue_step, ',''',
                             a.queues, ''',',
                             a.`status`, ',''',
                             a.source_endpoint_info,''',''',
                             (CASE WHEN a.is_re_assign_endpoint = 1 AND a.cycle_cnt > b.repeat_count THEN '' ELSE IFNULL(a.dst_endpoint_info,'') END ), ''',',
                             (CASE WHEN a.is_re_assign_endpoint = 1 AND a.cycle_cnt > b.repeat_count THEN 1 ELSE a.cycle_cnt + 1 END ), ',''',
                             a.create_time, ''',',
                             a.is_delete, ',',
                             a.is_re_assign_endpoint, ',''',
                             b.dst_queue_type, ''',',
                             b.dst_queue_step,',',
                             b.double_side,',''',
                             UTC_TIMESTAMP(),''',',
                             (CASE WHEN a.is_re_assign_endpoint = 1 AND a.cycle_cnt > b.repeat_count THEN 1 ELSE 0 END ),',''',
                             IF(IFNULL(b.`uri`,'') = '',CONCAT('/msg_management/',b.dst_queue_type,'/data'), b.`uri`),''',''',
                             IFNULL(a.dst_endpoint_info,''), ''',',
                             a.cycle_cnt, ',''',
                             b.method,''',',
                             CASE WHEN b.`limit` = 0 THEN 0 ELSE 1 END,',''',
                             IFNULL(SUBSTRING_INDEX(SUBSTRING_INDEX(a.queues,'|$|',e.parameter_val_pos),'|$|',-1),''),''',''',
                             IFNULL(SUBSTRING_INDEX(SUBSTRING_INDEX(a.queues,'|$|',e.body_val_pos),'|$|',-1),''),''')')) END 
      INTO v_sql
      FROM msg_queues.`queues` a
     INNER JOIN (SELECT DISTINCT queue_type FROM msg_queues.sync_service_config WHERE sync_id = v_sync_id ) c ON a.queue_type = c.queue_type AND a.is_delete = 0
     INNER JOIN msg_queues.`queue_workflows` b ON a.queue_type = b.queue_type AND a.queue_step = b.queue_step AND IFNULL(b.dst_queue_type,'') <> '' 
      LEFT JOIN msg_queues.`temp_gusq_unsync_queue` d ON a.id = d.id
      LEFT JOIN msg_queues.service_parameters e  ON a.queue_type =e.queue_type AND a.queue_step = e.queue_step
     WHERE d.id IS NULL;

    SET returnMsg_o = 'fail to insert into temp_gusq_unsync_queue.';
    IF IFNULL(v_sql, '') <> '' THEN
        CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);
    END IF;

    ##calculate limit datas,only calculate the if_limited > 0''s datas
    SET @queue_type='';
    SET @queue_step = 0;
    SET @row_num=0;
    INSERT INTO msg_queues.`temp_gusq_unsync_queue_limit`(id,queue_id,new_id,queue_type,queue_step)
    SELECT id, 
           queue_id,
           (@row_num := CASE WHEN @queue_type=queue_type and @queue_step=queue_step  THEN @row_num + 1 ELSE 1 END) AS new_id,
           (@queue_type := queue_type) AS queue_type,
           (@queue_step := queue_step) as queue_step
      FROM msg_queues.`temp_gusq_unsync_queue`
     WHERE if_limited = 1 
     ORDER BY queue_type,queue_step,queue_id;
    
    DELETE c
      FROM msg_queues.`temp_gusq_unsync_queue_limit` a,
           msg_queues.queue_workflows b,
           msg_queues.temp_gusq_unsync_queue c
     WHERE a.queue_type = b.queue_type
       AND a.queue_step = b.queue_step
       AND b.`limit` > 0
       AND a.new_id > b.`limit`
       AND a.id = c.id;
     
    ##calculate the dst server,one queue_type, no matter how many steps ,once can only be assign to the same dst_endpoint_info
    ##some queues may not be reassign,so the temp_gusq_unsync_queue in the same queue_type may be send to different dst_endpoint_info
    SET returnMsg_o = 'fail to update sync service config.';
    SET v_sql = CONCAT('INSERT INTO msg_queues.`temp_gusq_sync_service_cfg`(syncService_id,endpoint_id,endpoint_ip,endpoint_port,queue_type,cur_weight_after_selected) VALUES ', cur_weight_after_selected_i);
    CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);

    UPDATE msg_queues.`sync_service_config` a,
           msg_queues.`temp_gusq_sync_service_cfg` b
       SET a.cur_weight_after_selected = b.cur_weight_after_selected
     WHERE a.sync_id = v_sync_id
       AND a.endpoint_id = b.endpoint_id
       AND a.endpoint_ip = b.endpoint_ip
       AND a.endpoint_port = b.endpoint_port
       AND a.queue_type = b.queue_type;
       
    SET returnMsg_o = 'fail to set dst_queue_info';
    SELECT GROUP_CONCAT(DISTINCT dst_queue_type)
      INTO v_queue_types
      FROM msg_queues.`temp_gusq_unsync_queue` 
     WHERE IFNULL(dst_endpoint_info ,'') = '';
    
    IF IFNULL(v_queue_types,'') <> '' THEN
        CALL msg_queues.`get_next_server`(syncService_id_i , v_queue_types, v_endpoint_infos, v_returnCode, v_returnMsg);
        IF v_returnCode <> 200 THEN
            SET v_unsynced_sys_lock = RELEASE_LOCK('get_un_synced_queue_lock');
            SET returnCode_o = v_returnCode;
            SET returnMsg_o = CONCAT(returnMsg_o,'',IFNULL(v_returnMsg,''));
            TRUNCATE TABLE msg_queues.`temp_gusq_last_receive_info`;
            TRUNCATE TABLE msg_queues.`temp_gusq_unsync_queue`;
            TRUNCATE TABLE msg_queues.`temp_gusq_unsync_queue_limit`;
            TRUNCATE TABLE msg_queues.`temp_gusq_sync_service_cfg`;
            TRUNCATE TABLE msg_queues.`temp_gusq_dst_endpoint_info`;
            TRUNCATE TABLE msg_queues.`temp_gusq_begin_unsync_id`;
            DROP TABLE IF EXISTS msg_queues.`temp_gusq_last_receive_info`;
            DROP TABLE IF EXISTS msg_queues.`temp_gusq_unsync_queue`;
            DROP TABLE IF EXISTS msg_queues.`temp_gusq_unsync_queue_limit`;
            DROP TABLE IF EXISTS msg_queues.`temp_gusq_sync_service_cfg`;
            DROP TABLE IF EXISTS msg_queues.`temp_gusq_dst_endpoint_info`;
            DROP TABLE IF EXISTS msg_queues.`temp_gusq_begin_unsync_id`;
            CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,cur_weight_after_selected_i,returnMsg_o,v_returnCode,v_returnMsg);
            LEAVE ll;
        END IF;

        CALL commons.`dynamic_sql_execute`(CONCAT('INSERT INTO msg_queues.`temp_gusq_dst_endpoint_info`(queue_type,dst_endpoint_info) VALUES ',v_endpoint_infos),v_returnCode,v_returnMsg);
        UPDATE msg_queues.`temp_gusq_unsync_queue` a,
               msg_queues.`temp_gusq_dst_endpoint_info` b
           SET a.dst_endpoint_info = b.dst_endpoint_info
         WHERE a.dst_queue_type = b.queue_type 
           AND IFNULL(a.dst_endpoint_info,'') = '';
    END IF;

    ##calculate the last sync queue_id
    SET returnMsg_o = 'fail to get begin_unsync_queue_id';
    INSERT INTO msg_queues.`temp_gusq_begin_unsync_id`(queue_id,queue_type,dst_endpoint_info)
         SELECT MIN(queue_id),queue_type,dst_endpoint_info
           FROM msg_queues.`temp_gusq_unsync_queue` a
          GROUP BY a.queue_type,a.dst_endpoint_info;

    SET returnMsg_o = 'fail to calculate last_sync_queue_id';
    UPDATE msg_queues.`temp_gusq_unsync_queue` a,
           (
               SELECT a.queue_type,a.dst_endpoint_info,IFNULL(MAX(b.queue_id),0) AS last_sync_queue_id
                 FROM msg_queues.`temp_gusq_begin_unsync_id` a
                 LEFT JOIN msg_queues.`queues` b
                   ON a.queue_type = b.queue_type
                  AND a.dst_endpoint_info = b.dst_endpoint_info
                  AND b.queue_id < a.queue_id
                GROUP BY a.queue_type,a.dst_endpoint_info           
           ) b
       SET a.last_sync_queue_id = b.last_sync_queue_id
     WHERE a.queue_type = b.queue_type
       AND a.dst_endpoint_info = b.dst_endpoint_info;
    
    START TRANSACTION;
    SET SESSION innodb_lock_wait_timeout = 30;
    
    SET returnMsg_o = 'fail to insert data into roll_back_queues.';
    INSERT INTO msg_queues.`roll_back_queues`(queue_id, main_queue_info, queue_type, queue_step, queues, `status`, source_endpoint_info, dst_endpoint_info, cycle_cnt, create_time, last_update_time, is_delete, is_re_assign_endpoint, remark)
         SELECT a.queue_id,a.main_queue_info,a.queue_type, a.queue_step, a.queues, a.`status`,a.source_endpoint_info, a.orig_dst_endpoint_info, a.orig_cycle_cnt,a.create_time, a.last_update_time,a.is_delete, a.is_re_assign_endpoint,a.remark
           FROM msg_queues.`temp_gusq_unsync_queue` a
          WHERE a.if_rollback = 1
             ON DUPLICATE KEY UPDATE remark = a.remark;  

    UPDATE msg_queues.`queues` a,
           msg_queues.`temp_gusq_unsync_queue` b
       SET a.dst_endpoint_info = b.dst_endpoint_info,
           a.cycle_cnt = b.cycle_cnt,
           a.last_update_time = UTC_TIMESTAMP(),
           a.queue_step = b.queue_step,
           a.is_delete = b.is_delete
     WHERE a.id = b.id;

    COMMIT;
    
    SET returnMsg_o = 'fail to get the output result.';
    SELECT CONCAT(uri,'?',IFNULL(parameter,'')) AS `uri`, 
           GROUP_CONCAT('(', queue_id, ',''', IFNULL(main_queue_info,''), ''',''', IFNULL(IF(double_side=0,`body`,queues),''), ''',', `status`, ')' ORDER BY queue_id) AS msgs,
           MAX(method) AS method,
           MAX(last_sync_queue_id) AS last_sync_queue_id,
           GROUP_CONCAT(queue_id ORDER BY queue_id) AS current_check_list,
           queue_type AS source_queue_type,
           MAX(dst_queue_type) AS dst_queue_type,
           MAX(dst_queue_step) AS dst_queue_step, 
           dst_endpoint_info,
           MAX(double_side) AS double_side
      FROM msg_queues.`temp_gusq_unsync_queue`
     GROUP BY CONCAT(uri,'?',IFNULL(parameter,'')),dst_endpoint_info,queue_type,queue_step;

    SET v_unsynced_sys_lock = RELEASE_LOCK('get_un_synced_queue_lock');
    TRUNCATE TABLE msg_queues.`temp_gusq_last_receive_info`;
    TRUNCATE TABLE msg_queues.`temp_gusq_unsync_queue`;
    TRUNCATE TABLE msg_queues.`temp_gusq_unsync_queue_limit`;
    TRUNCATE TABLE msg_queues.`temp_gusq_sync_service_cfg`;
    TRUNCATE TABLE msg_queues.`temp_gusq_dst_endpoint_info`;
    TRUNCATE TABLE msg_queues.`temp_gusq_begin_unsync_id`;
    DROP TABLE IF EXISTS msg_queues.`temp_gusq_last_receive_info`;
    DROP TABLE IF EXISTS msg_queues.`temp_gusq_unsync_queue`;
    DROP TABLE IF EXISTS msg_queues.`temp_gusq_unsync_queue_limit`;
    DROP TABLE IF EXISTS msg_queues.`temp_gusq_sync_service_cfg`;
    DROP TABLE IF EXISTS msg_queues.`temp_gusq_dst_endpoint_info`;
    DROP TABLE IF EXISTS msg_queues.`temp_gusq_begin_unsync_id`;

    SET returnCode_o = 200;
    SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(user_i,v_modulename,v_procname,v_params_body,cur_weight_after_selected_i,returnMsg_o,v_returnCode,v_returnMsg);

END$$

DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;