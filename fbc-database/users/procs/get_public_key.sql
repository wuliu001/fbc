USE `users`;

/*Procedure structure for Procedure `get_public_key` */;

DROP PROCEDURE IF EXISTS `get_public_key`;

DELIMITER $$
CREATE DEFINER=`dba`@`%` PROCEDURE `get_public_key`( user_i                INT,
                                    id_i                  VARCHAR(50),
                                    OUT returnCode_o      INT,
							        OUT returnMsg_o       LONGTEXT )
ll:BEGIN
    DECLARE v_pub_key TEXT;
    SELECT MAX(public_key)
      INTO v_pub_key
      FROM `users`.`public_keys`
	 WHERE id = id_i;
	
    IF IFNULL(TRIM(v_pub_key),'') = '' THEN
        SET returnCode_o = 511;
        SET returnMsg_o = 'This node do not exist public key for this user.';
        LEAVE ll;
    END IF;
    
    SELECT v_pub_key `public_key`;
    
    UPDATE `users`.`public_keys`
       SET last_be_sync_time = UTC_TIMESTAMP()
	 WHERE id = id_i;
     
	SET returnCode_o = 200;
	SET returnMsg_o = 'OK';
END
$$
DELIMITER ;
