USE `blockchain_cache`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `cacheQueue.insert` */;

DROP PROCEDURE IF EXISTS `cacheQueue.insert`;

DELIMITER $$
USE `blockchain_cache`$$
CREATE PROCEDURE `cacheQueue.insert`( 
    queuetype_i                      VARCHAR(32),
    queue_body_i                     LONGTEXT,
    node_dns_i                       VARCHAR(100),
    OUT returnCode_o                 INT,
    OUT returnMsg_o                  LONGTEXT
    )
ll:BEGIN
    DECLARE v_params_body               LONGTEXT DEFAULT NULL;
    DECLARE v_procname                  VARCHAR(64) DEFAULT 'cacheQueue.insert';
    DECLARE v_modulename                VARCHAR(50) DEFAULT 'blockchainCache';
    DECLARE v_returnCode                INT DEFAULT 0;
    DECLARE v_returnMsg                 LONGTEXT DEFAULT '';
    DECLARE v_sql                       LONGTEXT;
    DECLARE v_queuetype                 VARCHAR(32) DEFAULT TRIM(queuetype_i);
    DECLARE v_queue_body                LONGTEXT DEFAULT TRIM(queue_body_i);
    DECLARE v_node_dns                  VARCHAR(100) DEFAULT TRIM(node_dns_i);
    DECLARE v_dst_endpoint_info         VARCHAR(100);
    DECLARE done                        INT DEFAULT 0;
    
    #send to other nodes
    DECLARE cur_next_serv CURSOR FOR SELECT DISTINCT CONCAT(endpoint_ip,':',endpoint_port)
                                       FROM msg_queues.sync_service_config 
                                      WHERE queue_type = v_queuetype
                                        AND CONCAT(endpoint_ip,':',endpoint_port) <> v_node_dns;
                                        
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    
    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;      
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_queue_body,returnMsg_o,v_returnCode,v_returnMsg);
    END;
    
    SET v_params_body = CONCAT('{"queuetype_i":"',IFNULL(queuetype_i,''),'","node_dns_i":"',IFNULL(node_dns_i,''),'"}');
    
    SET returnMsg_o = 'fail to insert data into queues';
    OPEN cur_next_serv;
    S:REPEAT
        FETCH cur_next_serv INTO v_dst_endpoint_info;
        IF NOT done THEN
            CALL `msg_queues`.`queues.insert`(0, v_queue_body, v_queuetype, 0, v_dst_endpoint_info, v_returnCode,v_returnMsg);
            IF v_returnCode <> 200 THEN
                SET returnCode_o  = v_returnCode;
                SET returnMsg_o = CONCAT(returnMsg_o,v_returnMsg);
                CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,v_body,returnMsg_o,v_returnCode,v_returnMsg);
                LEAVE ll;
            END IF;        
       END IF;
    UNTIL done END REPEAT;
    CLOSE cur_next_serv;

    SET returnCode_o = 200;
    SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,v_queue_body,returnMsg_o,v_returnCode,v_returnMsg);
    
END $$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;