USE `users`;

/*Procedure structure for Procedure `get_public_info` */;

DROP PROCEDURE IF EXISTS `get_public_info`;

DELIMITER $$
CREATE DEFINER=`dba`@`%` PROCEDURE `get_public_info`( user_i                INT,
                                     id_i                  VARCHAR(50),
                                     OUT returnCode_o      INT,
							         OUT returnMsg_o       LONGTEXT )
ll:BEGIN
    DECLARE v_checker        INT;
    
    SELECT COUNT(*)
      INTO v_checker
      FROM users.public_info
	 WHERE id = id_i;
	
    IF v_checker = 0 THEN
        SET returnCode_o = 511;
        SET returnMsg_o = 'This user is invalid in this node.';
        LEAVE ll;
    END IF;
    
    SELECT username userAccount,
           corporation_name 'corporationName',
           `owner`,
           address,
           company_register_date 'companyRegisterDate',
           registered_capital 'registeredCapital',
           annual_income 'annualIncome',
           tel_num 'telNum',
           email
	  FROM users.public_info
	 WHERE id = id_i;
	
    SET returnCode_o = 200;
    SET returnMsg_o = 'OK';
END
$$
DELIMITER ;
