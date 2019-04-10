USE `centerdb`;

/*Procedure structure for Procedure `tx_info.get` */;

DROP PROCEDURE IF EXISTS `tx_info.get`;

DELIMITER $$
CREATE DEFINER=`dba`@`%` PROCEDURE `tx_info.get`(OUT returnCode_o      INT,
                                                 OUT returnMsg_o       LONGTEXT )
ll:BEGIN
    DECLARE v_procname               VARCHAR(100) DEFAULT 'centerdb.tx_info.get';
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
    SET v_params_body = CONCAT('{}');
    
    SELECT #'苹果'         AS `goods_type`,
           'APPLE'        AS `goods_type`,
           'APL'          AS `symbol`,
           '85'           AS `level`,
           '10.00'        AS `price`,
           '-0.5'         AS `rise_fall`,
           '120,259'      AS `volume`,
           '0.67'         AS `volume_change`,
           '125,459'      AS `purchase_cnt`,
           '-6.54'        AS `purchase_change`,
           '115,986.00'   AS `sale_cnt`,
           '8.76'         AS `sale_change`;
    
    SET returnCode_o = 200;
	SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
END
$$
DELIMITER ;
