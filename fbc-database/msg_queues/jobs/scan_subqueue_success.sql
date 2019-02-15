
USE `msg_queues`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `main_queue_success` */;

DROP EVENT IF EXISTS `scan_subqueue_success`;

DELIMITER $$

CREATE EVENT `scan_subqueue_success` ON SCHEDULE EVERY 2 MINUTE STARTS '2019-01-01 00:00:00' ON COMPLETION PRESERVE ENABLE DO

ll:BEGIN
    DECLARE v_procname                    VARCHAR(64) DEFAULT 'scan_subqueue_success.job';
    DECLARE v_modulename                  VARCHAR(50) DEFAULT 'messageManager';
    DECLARE v_params_body                 LONGTEXT DEFAULT '{}';
    DECLARE v_returnCode                  INT;
    DECLARE v_returnMsg                   LONGTEXT;
    DECLARE returnMsg_o                   LONGTEXT;
    DECLARE v_sql                         LONGTEXT;

    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        
        TRUNCATE TABLE msg_queues.`tmp_sss_workflows`;
        TRUNCATE TABLE msg_queues.`tmp_sss_calculate`;
        TRUNCATE TABLE msg_queues.`tmp_sss_final_calculate`;
        DROP TABLE msg_queues.`tmp_sss_workflows`;
        DROP TABLE msg_queues.`tmp_sss_calculate`;
        DROP TABLE IF EXISTS msg_queues.`tmp_sss_final_calculate`;
        SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
    END;

    SET SESSION group_concat_max_len = 4294967295;
    SET returnMsg_o = CONCAT(v_modulename,v_procname,' command Error.');

    CREATE TEMPORARY TABLE IF NOT EXISTS msg_queues.`tmp_sss_workflows` (
      `main_queue_type`         VARCHAR(50),
      `main_queue_step`         TINYINT,
      `main_queue_success_step` TINYINT,
      `main_queue_fail_step`    TINYINT,
      `success_percent`         INT,
      `sub_queue_type`          VARCHAR(50),
      `sub_queue_step`          TINYINT,
      KEY `key_main_idx`        (`main_queue_type`,`main_queue_step`)
    ) ENGINE=InnoDB; 
    TRUNCATE TABLE msg_queues.`tmp_sss_workflows`;

    CREATE TEMPORARY TABLE IF NOT EXISTS msg_queues.`tmp_sss_calculate` (
      `id`                           BIGINT(20) UNSIGNED NOT NULL,
      `main_queue_info`              VARCHAR(255) NOT NULL,
      `main_queue_type`              VARCHAR(50) NOT NULL,
      `main_queue_step`              TINYINT NOT NULL,
      `main_queue_success_step`      TINYINT,
      `main_queue_fail_step`         TINYINT,
      `success_percent`              INT,
      `sub_queue_type`               VARCHAR(50) NOT NULL,
      `sub_queue_step`               TINYINT NOT NULL,
      KEY `key_main_queue_info`      (`main_queue_info`),
      KEY `key_main_queue_type_idx`  (`main_queue_type`)
    ) ENGINE=InnoDB; 
    TRUNCATE TABLE msg_queues.`tmp_sss_calculate`;

    CREATE TEMPORARY TABLE IF NOT EXISTS msg_queues.`tmp_sss_final_calculate` (
      `id`                           BIGINT(20) UNSIGNED NOT NULL,
      `main_queue_type`              VARCHAR(50) NOT NULL,
      `main_queue_step`              TINYINT NOT NULL,
      `main_queue_success_step`      TINYINT,
      `main_queue_fail_step`         TINYINT,
      `successed`                    INT NOT NULL DEFAULT 0,
      `failed`                       INT NOT NULL DEFAULT 0,
      KEY `key_id_idx`               (`id`), 
      KEY `key_main_idx`             (`main_queue_type`,`main_queue_step`)
    ) ENGINE=InnoDB; 
    TRUNCATE TABLE msg_queues.`tmp_sss_final_calculate`;
    
    SET returnMsg_o = 'get config info failed.';
    INSERT INTO msg_queues.`tmp_sss_workflows`(main_queue_type,main_queue_step,main_queue_success_step,main_queue_fail_step,success_percent,sub_queue_type,sub_queue_step)
    SELECT b.main_queue_type ,b.main_queue_step,msg_queues.`getNextStep`(b.main_queue_type,b.main_queue_step,0) main_queue_success_step,msg_queues.`getNextStep`(b.main_queue_type,b.main_queue_step,1) main_queue_fail_step,b.success_percent,b.sub_queue_type,a.queue_step sub_queue_step
      FROM msg_queues.queue_workflows a,
           (
               SELECT queue_type main_queue_type, msg_queues.`getNextStep`(queue_type,queue_step,0) main_queue_step,success_percent,sub_queue_type
                 FROM msg_queues.queue_workflows 
                WHERE IFNULL(sub_queue_type,'') <> ''
           )b 
     WHERE a.queue_type = b.sub_queue_type
       AND a.is_end_step =1;
    
    SET returnMsg_o = 'failed to get the main queue info.';
    SELECT CASE WHEN COUNT(1) = 0 THEN ''
                ELSE CONCAT('INSERT INTO msg_queues.`tmp_sss_calculate` (id,main_queue_info,main_queue_type,main_queue_step,main_queue_success_step,main_queue_fail_step,sub_queue_type,sub_queue_step,success_percent) VALUES ',
                             GROUP_CONCAT('(',
                                  a.id,',''', 
                                  IFNULL(a.main_queue_info,''),''',''',
                                  a.queue_type,''',',
                                  a.queue_step,',',
                                  b.main_queue_success_step,',',
                                  b.main_queue_fail_step,',''',
                                  b.sub_queue_type,''',',
                                  b.sub_queue_step,',',
                                  b.success_percent,')')) END
       INTO v_sql
       FROM msg_queues.queues a,
            msg_queues.`tmp_sss_workflows` b
      WHERE a.queue_type=b.main_queue_type
        AND a.queue_step=b.main_queue_step;
    IF IFNULL(v_sql,'')<>'' THEN
        CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);
    END IF;
    
    SET returnMsg_o = 'failed to calculate the main queue result.';
    SELECT CASE WHEN COUNT(1) = 0 THEN ''
                ELSE CONCAT('INSERT INTO msg_queues.`tmp_sss_final_calculate` (id,main_queue_type,main_queue_step,main_queue_success_step,main_queue_fail_step,successed,failed) VALUES ',
                             GROUP_CONCAT('(',
                                          c.id,',''',
                                          c.main_queue_type,''',',
                                          c.main_queue_step,',',
                                          c.main_queue_success_step,',',
                                          c.main_queue_fail_step,',',
                                          CASE WHEN (c.success_cnt/c.total_cnt)*100 >= c.success_percent THEN 1 ELSE 0 END,',',
                                          CASE WHEN (c.fail_cnt/c.total_cnt)*100 > (100-c.success_percent) THEN 1 ELSE 0 END,')')) END
     INTO v_sql
     FROM (
               SELECT b.id,
                      b.main_queue_info,
                      b.main_queue_type,
                      b.main_queue_step,
                      b.main_queue_success_step,
                      b.main_queue_fail_step,
                      COUNT(1) total_cnt,
                      SUM(CASE WHEN a.queue_step = b.sub_queue_step AND `status` = 0 THEN 1 ELSE 0 END ) AS success_cnt,
                      SUM(CASE WHEN a.queue_step = b.sub_queue_step AND `status` <> 0 THEN 1 ELSE 0 END ) AS fail_cnt,
                      b.success_percent
                 FROM msg_queues.queues a,
                      msg_queues.`tmp_sss_calculate` b
                WHERE a.main_queue_info = b.main_queue_info
                  AND a.queue_type = b.sub_queue_type
                GROUP BY b.id,b.main_queue_info,b.main_queue_type,b.main_queue_step,b.success_percent,b.main_queue_success_step,b.main_queue_fail_step
           )c;
    
    IF IFNULL(v_sql,'')<>'' THEN
        CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);
    END IF;
    
    SET returnMsg_o = 'fail to update main queue step to next and status';
    UPDATE msg_queues.queues a, 
           msg_queues.`tmp_sss_final_calculate` b
       SET a.`status` = (CASE WHEN b.failed > 0 THEN 1 END),
           a.queue_step =(CASE WHEN b.failed > 0 THEN b.main_queue_fail_step WHEN b.successed > 0 THEN b.main_queue_success_step END),
           a.cycle_cnt = (CASE WHEN b.failed > 0 OR b.successed > 0 THEN 0 END),
           a.last_update_time = UTC_TIMESTAMP()
     WHERE a.id = b.id
       AND a.queue_type = b.main_queue_type
       AND a.queue_step = b.main_queue_step;

    TRUNCATE TABLE msg_queues.`tmp_sss_workflows`;
    TRUNCATE TABLE msg_queues.`tmp_sss_calculate`;
    TRUNCATE TABLE msg_queues.`tmp_sss_final_calculate`;
    DROP TABLE msg_queues.`tmp_sss_workflows`;
    DROP TABLE msg_queues.`tmp_sss_calculate`;
    DROP TABLE IF EXISTS msg_queues.`tmp_sss_final_calculate`;

    SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);

END $$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;