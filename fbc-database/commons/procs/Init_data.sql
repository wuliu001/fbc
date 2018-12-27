USE `commons`;

/*Procedure structure for Procedure `Init_data` */;

DROP PROCEDURE IF EXISTS `Init_data`;

DELIMITER $$
CREATE DEFINER=`dba`@`%` PROCEDURE `Init_data`(
    user_i                INT,
    OUT returnCode_o      INT,
    OUT returnMsg_o       LONGTEXT
)
LL:BEGIN

    DECLARE v_procname            VARCHAR(50) DEFAULT 'commons.Init_data';
    DECLARE v_params_body         LONGTEXT DEFAULT NULL;
    DECLARE v_returnCode          INT;
    DECLARE v_returnMsg           TEXT;
  
    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;

        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT('Workflow commons.Init_data command Error: ',IFNULL(returnMsg_o,''),' | ',v_returnMsg);
    END;

    SET returnCode_o = 400; 
    SET returnMsg_o = 'Workflow commons.Init_data command Error.';
    SET v_params_body = CONCAT('{"user_i":"',IFNULL(user_i,''),'"}');
    SET SESSION group_concat_max_len = 4294967295;

    TRUNCATE TABLE `config`;
    TRUNCATE TABLE `dbversion`;

    INSERT INTO `config` VALUES (1,'log_level','1',NULL);
    INSERT INTO `config` VALUES (2,'device_online','0','device online event');
    INSERT INTO `config` VALUES (3,'device_update','1','device download event');
    INSERT INTO `config` VALUES (4,'file_uploading','1','device upload event');
    INSERT INTO `config` VALUES (5,'rtv_processing_report_noti','1','rtv processing report event');
    INSERT INTO `config` VALUES (6,'coredb_import_err_rollback','0','0: keep, 1: rollback');
    INSERT INTO `config` VALUES (7,'t1_system_status','1','0: manual, 1: auto');
    INSERT INTO `config` VALUES (8,'rtv_processing_event_log','1','0: not record log, 1: record log');
    INSERT INTO `config` VALUES (9,'NDS_v_level','14','NDS_level');
    INSERT INTO `config` VALUES (10,'update_curves_length','0','0: no, 1: yes');
    INSERT INTO `config` VALUES (11,'foregrounddb_operation_log','1','0: not record log, 1: record log');
    INSERT INTO `config` VALUES (12,'vehicle_foregrounddb_operation_log','1','0: not record log, 1: record log');
    INSERT INTO `config` VALUES (13,'logic_foregrounddb_operation_log','1','0: not record log, 1: record log');
    INSERT INTO `config` VALUES (14,'landmarkdb_operation_log','1','0: not record log, 1: record log');
    INSERT INTO `config` VALUES (15,'foregrounddb_trans_timeout_value','0','foregrounddb trans timeout value (unit hour)');
    INSERT INTO `config` VALUES (16,'landmarkdb_trans_timeout_value','0','landmarkdb trans timeout value (unit hour)');
    INSERT INTO `config` VALUES (17,'vehicle_foregrounddb_trans_timeout_value','0','vehicle_foregrounddb trans timeout value (unit hour)');
    INSERT INTO `config` VALUES (18,'procedure_elapsed_time','1000','proc run time greater than value then record log(unit ms)');
    INSERT INTO `config` VALUES (19,'foregrounddb_archive_time','0','archive time(unit day)');
    INSERT INTO `config` VALUES (20,'foregrounddb_purge_time','0','purge time(unit day)');
    INSERT INTO `config` VALUES (21,'check_geo_division_ids','0','1:check 0:no_check');
    INSERT INTO `config` VALUES (22,'commons','1','log_level');
    INSERT INTO `config` VALUES (23,'deviceManager','1','log_level');
    INSERT INTO `config` VALUES (24,'businessData','3','log_level');
    INSERT INTO `config` VALUES (25,'logicData','3','log_level');
    INSERT INTO `config` VALUES (26,'dataContorller','3','log_level');
    INSERT INTO `config` VALUES (27,'debugData','1','log_level');
    INSERT INTO `config` VALUES (28,'messageManager','2','log_level');
    INSERT INTO `config` VALUES (29,'businessData_Archive','3','log_level');
    INSERT INTO `config` VALUES (30,'msg_queue_log','1','0: not record log, 1: record log');
    INSERT INTO `config` VALUES (31,'redeploy_interval','1800','redeploy interval seconds, it must fully be deployed within 30 minutes');
    INSERT INTO `config` VALUES (32,'intersections','0','0: no, 1: yes');
    INSERT INTO `config` VALUES (33,'foregroundData','1','log_level');
    INSERT INTO `dbversion` VALUES (1,`routinesVersion.get`());

    SET returnCode_o = 200;
    SET returnMsg_o = 'OK';

END
$$
DELIMITER ;
