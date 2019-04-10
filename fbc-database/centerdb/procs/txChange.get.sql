USE `centerdb`;

/*Procedure structure for Procedure `txChange.get` */;

DROP PROCEDURE IF EXISTS `txChange.get`;

DELIMITER $$
CREATE DEFINER=`dba`@`%` PROCEDURE `txChange.get`(goods_type_i      VARCHAR(100),
                                                  goods_symbol_i    VARCHAR(100),
                                                  goods_level_i     INT,
                                                  OUT returnCode_o  INT,
                                                  OUT returnMsg_o   LONGTEXT )
ll:BEGIN
    DECLARE v_procname               VARCHAR(100) DEFAULT 'centerdb.txChange.get';
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
    SET v_params_body = CONCAT('{"goods_type_i":"',IFNULL(goods_type_i,''),'","goods_symbol_i":"',IFNULL(goods_symbol_i,''),'","goods_level_i":"',IFNULL(goods_level_i,''),'"}');
    SET goods_type_i = TRIM(goods_type_i);
    SET goods_symbol_i = TRIM(goods_symbol_i);
    /*
    SET returnMsg_o = 'fail to check input goods type.';
    IF IFNULL(goods_type_i,'') = '' OR IFNULL(goods_symbol_i,'') = '' OR goods_level_i IS NULL THEN
        SET returnCode_o = 511;
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
        LEAVE ll;
    END IF;
    */
    SELECT '成都'          AS `producing_area`,
           '10.00'        AS `price`,
           '-0.5'         AS `rise_fall`,
           '120,259'      AS `volume`,
           '0.67'         AS `volume_change`,
           '125,459'      AS `purchase_cnt`,
           '-6.54'        AS `purchase_change`,
           '115,986.00'   AS `sale_cnt`,
           '8.76'         AS `sale_change`,
           4              AS `logistics_time`
     UNION
    SELECT '广州'          AS `producing_area`,
           '10.00'        AS `price`,
           '-0.5'         AS `rise_fall`,
           '120,259'      AS `volume`,
           '0.67'         AS `volume_change`,
           '125,459'      AS `purchase_cnt`,
           '-6.54'        AS `purchase_change`,
           '115,986.00'   AS `sale_cnt`,
           '8.76'         AS `sale_change`,
           4              AS `logistics_time`
     UNION 
    SELECT '云南'          AS `producing_area`,
           '10.00'        AS `price`,
           '-0.5'         AS `rise_fall`,
           '120,259'      AS `volume`,
           '0.67'         AS `volume_change`,
           NULL           AS `purchase_cnt`,
           NULL           AS `purchase_change`,
           NULL           AS `sale_cnt`,
           NULL           AS `sale_change`,
           4              AS `logistics_time`;
    
    SET returnCode_o = 200;
	SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
END
$$
DELIMITER ;
