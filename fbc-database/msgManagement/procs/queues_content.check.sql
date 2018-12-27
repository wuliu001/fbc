USE `msg_queues`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `queues_content.check` */;

DROP PROCEDURE IF EXISTS `queues_content.check`;

DELIMITER $$
USE `msg_queues`$$
CREATE PROCEDURE `queues_content.check`( 
    user_i            INT,
    OUT returnCode_o  INT,
    OUT returnMsg_o   LONGTEXT
    )
ll:BEGIN
    DECLARE v_procname          VARCHAR(64) DEFAULT 'queues_content.check';
    DECLARE v_modulename        VARCHAR(50) DEFAULT 'messageManager';
    DECLARE v_body              LONGTEXT DEFAULT NULL;
    DECLARE v_params_body       LONGTEXT DEFAULT NULL;
    DECLARE v_returnCode        INT DEFAULT 0;
    DECLARE v_returnMsg         LONGTEXT DEFAULT '';
    DECLARE v_cnt               BIGINT(20);
    
    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        COMMIT;
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
    END;
    
    SET SESSION group_concat_max_len = 4294967295;
    SET returnCode_o = 400;
    SET returnMsg_o =  'Workflow Manager queues_content.check Command Error.';
    SET v_params_body = CONCAT('{"user_i":"',user_i,'"}'); 

    SET returnMsg_o = 'fail to check input body irregular data.';
    SELECT COUNT(1) 
      INTO v_cnt 
      FROM msg_queues.temp_qi_queues 
     WHERE IFNULL(queue_msg,'') = ''
        OR IFNULL(`status`,'') = ''
        OR `status` REGEXP '^(-[1-9])?[0-9]*$' = 0;
    IF v_cnt > 0 THEN
        SET returnCode_o = 600;
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'fail to check input endpoint';
    SELECT COUNT(1) 
      INTO v_cnt 
      FROM msg_queues.temp_qi_queues 
     WHERE queue_id >= 0 
       AND IFNULL(dst_endpoint_info,'') = '';
    IF v_cnt > 0 THEN
        SET returnCode_o = 600;
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'fail to check exists queue body & queue step';
    SELECT COUNT(1)
      INTO v_cnt 
      FROM msg_queues.temp_qi_queues a,
           msg_queues.queues b
     WHERE a.queue_id = b.queue_id
       AND a.queue_type = b.queue_type
       AND a.dst_endpoint_info = b.dst_endpoint_info
       AND (IFNULL(a.queue_msg,'') <> IFNULL(b.queues,'') OR a.queue_step > b.queue_step);
    IF v_cnt > 0 THEN
        SET returnCode_o = 600;
        LEAVE ll;
    END IF;
    
    SET returnMsg_o = 'fail to delete exists inconsistent queues';
    DELETE a
      FROM msg_queues.temp_qi_queues a,
           msg_queues.queues b
     WHERE a.queue_id = b.queue_id
       AND a.queue_type = b.queue_type
       AND a.dst_endpoint_info = b.dst_endpoint_info
       AND a.queue_step < b.queue_step;

    SET returnCode_o = 200;
    SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(user_i,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
    
END $$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;