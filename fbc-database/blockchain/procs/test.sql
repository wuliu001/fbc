USE `blockchain`;

/*Procedure structure for Procedure `test` */;

DROP PROCEDURE IF EXISTS `test`;

DELIMITER $$
CREATE DEFINER=`dba`@`%` PROCEDURE `test`( user_i                INT,
								   username_i            VARCHAR(100),
                                   OUT returnCode_o      INT,
                                   OUT returnMsg_o       LONGTEXT)
BEGIN
    SELECT CONCAT('Hello World, ', username_i,'!') 'Key';
    SET returnCode_o = 200;
    SET returnMsg_o = 'OK';
END
$$
DELIMITER ;
