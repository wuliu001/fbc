USE `centerdb`;

/*Procedure structure for Procedure `protofolio.get` */;

DROP PROCEDURE IF EXISTS `protofolio.get`;

DELIMITER $$
CREATE DEFINER=`dba`@`%` PROCEDURE `protofolio.get`(accountAddress_i      VARCHAR(256),
                                                    OUT returnCode_o      INT,
                                                    OUT returnMsg_o       LONGTEXT )
ll:BEGIN
    DECLARE v_procname               VARCHAR(100) DEFAULT 'centerdb.protofolio.get';
    DECLARE v_modulename             VARCHAR(50) DEFAULT 'centerdb';
    DECLARE v_params_body            LONGTEXT DEFAULT '';
    DECLARE v_returnCode             INT;
    DECLARE v_returnMsg              LONGTEXT;
    
	DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
    END;
    
    SET returnCode_o = 400;
    SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error');
    SET v_params_body = CONCAT('{"accountAddress_i":"',IFNULL(accountAddress_i,''),'"}');
    SET accountAddress_i = TRIM(accountAddress_i);
    /*
    SET returnMsg_o = 'fail to check input accountAddress_i.';
    IF IFNULL(accountAddress_i,'') = '' THEN
        SET returnCode_o = 511;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    */
    SELECT #'苹果'                       AS `goods_type`,
          'APPLE'                       AS `goods_type`,
           'APL'                        AS `symbol`,
           '85'                         AS `level`,
           #'云南'                       AS `purchase_area`,
           'YunNan'                     AS `purchase_area`,
           '10.00'                      AS `purchase_price`,
           '5001.78'                    AS `purchase_cnt`,
           #'顺丰'                       AS `logistics`,
           'ShunFeng'                   AS `logistics`,
           #'运输中'                     AS `logistics_status`,
           'Processing'                 AS `logistics_status`,
           '2001-04-10 04:52:10'        AS `logistics_start_time`,
           '2001-04-10 04:52:10'        AS `logistics_end_time`,
           4                            AS `waiting_logistics_time`,
           0                            AS `is_logistics_delay`;
    
    SELECT #'苹果'   AS `goods_type`,
           'APPLE'  AS `goods_type`,
           '2250'   AS `daily_purchase_cnt`,
           '2.5'    AS `inventory_period`,
           0        AS `inventory_gap_period`;

    SELECT #'苹果'                       AS `goods_type`,
           'APPLE'                      AS `goods_type`,
           'APL'                        AS `symbol`,
           '85'                         AS `level`,
           #'云南'                       AS `sale_area`,
           'YunNan'                     AS `sale_area`,
           '10.00'                      AS `sale_price`,
           '5001.78'                    AS `sale_cnt`,
           #'顺丰'                       AS `logistics`,
           'ShunFeng'                   AS `logistics`,
           #'运输中'                     AS `logistics_status`,
           'Process'                    AS `logistics_status`,
           '2001-04-10 04:52:10'        AS `logistics_start_time`,
           '2001-04-10 04:52:10'        AS `logistics_end_time`,
           4                            AS `waiting_logistics_time`,
           0                            AS `is_logistics_delay`;

    SELECT #'苹果'       AS `goods_type`,
           'APPLE'      AS `goods_type`,
           '2250'       AS `daily_sale_cnt`,
           '17003.98'   AS `daily_sale_total_price`,
           '2.5'        AS `average_repayment_period`;    
    
    SET returnCode_o = 200;
	SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
END
$$
DELIMITER ;
