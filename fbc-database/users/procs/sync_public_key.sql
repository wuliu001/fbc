USE `users`;

/*Procedure structure for Procedure `sync_public_key` */;

DROP PROCEDURE IF EXISTS `sync_public_key`;

DELIMITER $$
CREATE DEFINER=`dba`@`%` PROCEDURE `sync_public_key`( user_i                INT,
                                     id_i                  VARCHAR(50),
                                     public_key_i          TEXT,
                                     OUT returnCode_o      INT,
							         OUT returnMsg_o       LONGTEXT )
ll:BEGIN
    DECLARE v_checker INT;
    
    SELECT public_key_i REGEXP '^-----BEGIN PUBLIC KEY-----' AND public_key_i REGEXP '-----END PUBLIC KEY-----$'
      INTO v_checker;
	
    IF v_checker = 0 THEN
        SET returnCode_o = 511;
        SET returnMsg_o = 'This public key format is wrong.';
        LEAVE ll;
    END IF;
    
    INSERT INTO `users`.`public_keys`(`id`, `public_key`, `create_time`, `is_sync`, `last_be_sync_time`)
         VALUES (id_i, public_key_i, UTC_TIMESTAMP(), 1, UTC_TIMESTAMP()) 
   ON DUPLICATE KEY UPDATE public_key=public_key_i;
   
    SET returnCode_o = 200;
    SET returnMsg_o = 'OK';
END
$$
DELIMITER ;
