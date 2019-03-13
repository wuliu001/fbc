USE `msg_queues`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `main_queue_success` */;

DROP EVENT IF EXISTS `scan_subqueue_success`;

DELIMITER $$

CREATE EVENT `scan_subqueue_success` ON SCHEDULE EVERY 1 MINUTE STARTS '2019-01-01 00:00:00' ON COMPLETION PRESERVE ENABLE DO

ll:BEGIN
    DECLARE v_procname                    VARCHAR(64) DEFAULT 'scan_subqueue_success.job';
    DECLARE v_modulename                  VARCHAR(50) DEFAULT 'messageManager';
    DECLARE v_params_body                 LONGTEXT DEFAULT '{}';
    DECLARE v_returnCode                  INT;
    DECLARE v_returnMsg                   LONGTEXT;
    DECLARE returnMsg_o                   LONGTEXT;
    DECLARE v_queues                      LONGTEXT;
    DECLARE v_succesess                   LONGTEXT;
    DECLARE v_sql                         LONGTEXT;

    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        
        TRUNCATE TABLE msg_queues.`tmp_queue_workflows`;
        TRUNCATE TABLE msg_queues.`tmp_queue_scueess`;
        DROP TABLE msg_queues.`tmp_queue_workflows`;
        DROP TABLE msg_queues.`tmp_queue_scueess`;
        SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
    END;

    SET SESSION group_concat_max_len = 4294967295;
    SET returnMsg_o = CONCAT(v_modulename,v_procname,' command Error.');

    CREATE TEMPORARY TABLE IF NOT EXISTS msg_queues.`tmp_queue_workflows` (
      `queue_type`           VARCHAR(50) NOT NULL,
      `next_step`            TINYINT NOT NULL,
      `succ_next_step`       TINYINT NOT NULL,
      `fail_next_step`       TINYINT NOT NULL,
      `sub_queue_type`       VARCHAR(50) NOT NULL,
      `sub_queue_step`       TINYINT NOT NULL,
      `sub_queue_end_step`   TINYINT NOT NULL,
      `success_percent`      INT NOT NULL DEFAULT 0
    ) ENGINE=InnoDB; 
    TRUNCATE TABLE msg_queues.`tmp_queue_workflows`;

    CREATE TEMPORARY TABLE IF NOT EXISTS msg_queues.`tmp_queue_scueess` (
      `main_queue_info`      VARCHAR(255) NOT NULL,
      `queue_type`           VARCHAR(50) NOT NULL,
      `queue_step`           TINYINT NOT NULL,
      `succ_next_step`       TINYINT NOT NULL,
      `fail_next_step`       TINYINT NOT NULL,
      `successed`            INT NOT NULL DEFAULT 0,
      `failed`               INT NOT NULL DEFAULT 0
    ) ENGINE=InnoDB; 
    TRUNCATE TABLE msg_queues.`tmp_queue_scueess`;

    
    SET returnMsg_o = 'get  main_queue_type,next_step,sub_queue_type and success_percent step.';
    INSERT INTO msg_queues.`tmp_queue_workflows`(`queue_type`,`next_step`,`succ_next_step`,`fail_next_step`,`sub_queue_type`,`sub_queue_step`,`sub_queue_end_step`,`success_percent`)
    SELECT a1.queue_type, a1.next_step, msg_queues.`getNextStep`(a1.queue_type, a1.next_step,0) succ_next_step,
           msg_queues.`getNextStep`(a1.queue_type, a1.next_step,1) fail_next_step,
           a1.sub_queue_type, b1.queue_step sub_queue_step, c1.queue_step sub_queue_end_step, a1.success_percent
      FROM (SELECT a.queue_type,a.sub_queue_type,msg_queues.`getNextStep`(a.queue_type, a.queue_step,0) next_step,
                   IFNULL(a.success_percent,0) success_percent
              FROM msg_queues.queue_workflows a
              WHERE IFNULL(sub_queue_type,'')<>''
    	     ) a1
      JOIN msg_queues.queue_workflows b1
        ON a1.sub_queue_type = b1.queue_type
      JOIN msg_queues.queue_workflows c1
        ON a1.sub_queue_type = c1.queue_type
       AND c1.is_end_step = 1;

    SET returnMsg_o = 'compute success and failed number.';
    SELECT GROUP_CONCAT(CONCAT('(''',main_queue_info,''',''', queue_type,''',', queue_step, ',', succ_next_step,',',fail_next_step,',', successed,',',failed,')')) 
      INTO v_succesess
     FROM (
           SELECT main_queue_info,queue_type,queue_step,succ_next_step,fail_next_step,
                  CASE WHEN (success/tot_subNum)*100 >= success_percent THEN 1 ELSE 0 END successed,
                  CASE WHEN (fail/tot_subNum)*100 > (100-success_percent) THEN 1 ELSE 0 END failed
             FROM (
                   SELECT a.main_queue_info,b.queue_type,b.next_step as queue_step,b.succ_next_step,b.fail_next_step,b.sub_queue_type,
                          b.sub_queue_end_step,b.success_percent, COUNT(1) tot_subNum,
                          SUM(CASE WHEN `status`=0 AND a.queue_step = b.sub_queue_end_step THEN 1 ELSE 0 END) success,
                          SUM(CASE WHEN `status`>0 THEN 1 ELSE 0 END) fail
                     FROM msg_queues.queues a,
                          msg_queues.`tmp_queue_workflows` b
                    WHERE a.queue_type = b.sub_queue_type
                      AND a.queue_step = b.sub_queue_step
           	        GROUP BY a.main_queue_info,b.queue_type,b.next_step,b.succ_next_step,b.fail_next_step,b.sub_queue_type,
                             b.sub_queue_end_step,b.success_percent
                  ) a
            WHERE NOT ((CASE WHEN (success/tot_subNum)*100 >= success_percent THEN 1 ELSE 0 END ) = 0
              AND (CASE WHEN (fail/tot_subNum)*100 > (100-success_percent) THEN 1 ELSE 0 END) = 0)
        ) b;
    
    IF IFNULL(v_succesess,'')<>'' THEN
        SET returnMsg_o = 'save queue_id and sub_queue_type and end_step to temp table.';
        SET v_sql = CONCAT('INSERT INTO msg_queues.`tmp_queue_scueess`(`main_queue_info`,`queue_type`,`queue_step`,`succ_next_step`,`fail_next_step`,`successed`,`failed`)  VALUES ',v_succesess);
        CALL commons.`dynamic_sql_execute`(v_sql,v_returnCode,v_returnMsg);

        SET returnMsg_o = 'update main queue step to next and status';
        UPDATE msg_queues.queues a, msg_queues.`tmp_queue_scueess` b
           SET a.`status` = CASE WHEN failed > 0 AND fail_next_step <> b.queue_step THEN 1 ELSE a.`status` END,
               a.queue_step = CASE WHEN failed > 0 THEN b.fail_next_step ELSE b.succ_next_step END,
               a.last_update_time = UTC_TIMESTAMP(),
               a.cycle_cnt =  CASE WHEN failed > 0 AND fail_next_step = b.queue_step THEN cycle_cnt + 1 ELSE 0 END
         WHERE a.queue_type=b.queue_type
           AND a.queue_step=b.queue_step
           AND a.main_queue_info = b.main_queue_info
           AND a.is_delete = 0;

    END IF;

    TRUNCATE TABLE msg_queues.`tmp_queue_workflows`;
    TRUNCATE TABLE msg_queues.`tmp_queue_scueess`;
    DROP TABLE msg_queues.`tmp_queue_workflows`;
    DROP TABLE msg_queues.`tmp_queue_scueess`;

    SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);

END $$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;