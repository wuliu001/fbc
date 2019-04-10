USE `centerdb`;

/*Procedure structure for Procedure `txChangeByCity.get` */;

DROP PROCEDURE IF EXISTS `txChangeByCity.get`;

DELIMITER $$
CREATE DEFINER=`dba`@`%` PROCEDURE `txChangeByCity.get`(goods_type_i       VARCHAR(100),
                                                        goods_symbol_i     VARCHAR(100),
                                                        goods_level_i      INT,
                                                        city_i             VARCHAR(100), 
                                                        OUT returnCode_o   INT,
                                                        OUT returnMsg_o    LONGTEXT )
ll:BEGIN
    DECLARE v_procname               VARCHAR(100) DEFAULT 'centerdb.txChangeByCity.get';
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
    SET v_params_body = CONCAT('{"goods_type_i":"',IFNULL(goods_type_i,''),'","goods_symbol_i":"',IFNULL(goods_symbol_i,''),'","goods_level_i":"',IFNULL(goods_level_i,''),'","city_i":"',IFNULL(city_i,''),'"}');
    SET goods_type_i = TRIM(goods_type_i);
    SET goods_symbol_i = TRIM(goods_symbol_i);
    SET city_i = TRIM(city_i);
    
    /*
    SET returnMsg_o = 'fail to check input goods type.';
    IF IFNULL(goods_type_i,'') = '' OR IFNULL(goods_symbol_i,'') = '' OR goods_level_i IS NULL OR IFNULL(city_i,'') = '' THEN
        SET returnCode_o = 511;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    */
    SELECT #'张三'                 AS `sale_account`,
           'ZS'                   AS `sale_account`,
           '10'                   AS `sale_cnt`,
           '0.67'                 AS `sale_change`,
           '2001-04-10 04:52:10'  AS `latest_sale_time`,
           #'李四'                 AS `purchase_account`,
           'LS'                   AS `purchase_account`,
           8                      AS `purchase_cnt`,
           '-0.14'                AS `purchase_change`,
           '2001-04-11 04:52:10'  AS `purchase_sale_time`
     UNION 
    SELECT #'张七'                 AS `sale_account`,
           'ZQ'                   AS `sale_account`,
           '10'                   AS `sale_cnt`,
           '0.67'                 AS `sale_change`,
           '2001-04-10 04:52:10'  AS `latest_sale_time`,
           NULL                   AS `purchase_account`,
           NULL                   AS `purchase_cnt`,
           NULL                   AS `purchase_change`,
           NULL                   AS `purchase_sale_time`
     UNION 
    SELECT NULL                     AS `sale_account`,
           NULL                     AS `sale_cnt`,
           NULL                     AS `sale_change`,
           NULL                     AS `latest_sale_time`,
           #'李五'                   AS `purchase_account`,
           'LW'                     AS `purchase_account`,
           8                        AS `purchase_cnt`,
           '-0.14'                  AS `purchase_change`,
           '2001-04-11 04:52:10'    AS `purchase_sale_time`;
    
    SET returnCode_o = 200;
	SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
END
$$
DELIMITER ;
