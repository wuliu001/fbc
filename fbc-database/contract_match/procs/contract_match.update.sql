USE `contract_match`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `contract_match.update` */;

DROP PROCEDURE IF EXISTS `contract_match.update`;

DELIMITER $$
CREATE PROCEDURE `contract_match.update`(
    OUT returnCode_o         INT,
    OUT returnMsg_o          LONGTEXT)
ll:BEGIN
    DECLARE v_cnt                    BIGINT(20);
    DECLARE v_procname               VARCHAR(100) DEFAULT 'contract_match.update';
    DECLARE v_modulename             VARCHAR(50) DEFAULT 'contract_match';
    DECLARE v_params_body            LONGTEXT DEFAULT '';
    DECLARE v_returnCode             INT;
    DECLARE v_returnMsg              LONGTEXT;
    DECLARE v_done                   INT DEFAULT 0;
    DECLARE v_address                VARCHAR(256);
    DECLARE v_initiator              VARCHAR(256);
    DECLARE v_txType                 VARCHAR(32) ;
    DECLARE v_variety                VARCHAR(100);
    DECLARE v_dateOfMature           DATETIME;
    DECLARE v_dateOfProduction       DATETIME;
    DECLARE v_placeOfProduction      VARCHAR(256);
    DECLARE v_appearanceRating       INT;
    DECLARE v_sizeRating             INT;
    DECLARE v_sweetnessRating        INT;
    DECLARE v_minQuantity            INT;
    DECLARE v_maxQuantity            INT;
    DECLARE v_price                  FLOAT;
    DECLARE v_cityOfLocation         VARCHAR(100);
    DECLARE v_addresslist            VARCHAR(256);
    DECLARE v_start                  INT;
    DECLARE v_vend_address           VARCHAR(256);
    DECLARE v_sum_maxQuantity        FLOAT;
    DECLARE v_vend_minQuantity       FLOAT;
    DECLARE v_vend_maxQuantity       FLOAT;
    DECLARE v_matchedQuantity        FLOAT;
    DECLARE v_totalPrice             FLOAT;
    DECLARE v_vend_price             FLOAT;

    DECLARE curl CURSOR FOR SELECT address, 
                                   initiator, 
                                   txType, 
                                   variety, 
                                   dateOfMature, 
                                   dateOfProduction, 
                                   appearanceRating, 
                                   sizeRating, 
                                   sweetnessRating, 
                                   minQuantity, 
                                   maxQuantity, 
                                   price, 
                                   cityOfLocation,
                                   0 AS matchedQuantity,
                                   0 AS totalPrice
                              FROM contract_match.temp_cmu_purchase
                             ORDER BY price;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;
    
	DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        TRUNCATE TABLE contract_match.`temp_cmu_purchase`;
        TRUNCATE TABLE contract_match.`temp_cmu_vendition`;
        DROP TABLE IF EXISTS contract_match.`temp_cmu_purchase`;
        DROP TABLE IF EXISTS contract_match.`temp_cmu_vendition`;
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, '-', v_procname, ' execute Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
    END;

    SET v_params_body = CONCAT('{}');

    CREATE TEMPORARY TABLE IF NOT EXISTS contract_match.`temp_cmu_purchase` (
      `address`                     VARCHAR(256) NOT NULL,
      `initiator`                   VARCHAR(256) NOT NULL,
      `txType`                      VARCHAR(32) NOT NULL,
      `variety`                     VARCHAR(100) NOT NULL,
      `dateOfMature`                DATETIME NOT NULL,
      `dateOfProduction`            DATETIME NOT NULL,
      `appearanceRating`            INT NOT NULL,
      `sizeRating`                  INT NOT NULL,
      `sweetnessRating`             INT NOT NULL,
      `minQuantity`                 INT NOT NULL,
      `maxQuantity`                 INT NOT NULL,
      `matchedQuantity`             FLOAT DEFAULT NULL,
      `price`                       FLOAT NOT NULL,
      `cityOfLocation`              VARCHAR(100) NOT NULL,
      `totalPrice`                  FLOAT DEFAULT NULL,
      KEY `idx_address`             (`address`),
      KEY `idx_initiator`           (`initiator`)
    ) ENGINE=InnoDB;
    TRUNCATE TABLE contract_match.`temp_cmu_purchase`;

    CREATE TEMPORARY TABLE IF NOT EXISTS contract_match.`temp_cmu_vendition` (
      `address`                     VARCHAR(256) NOT NULL,
      `initiator`                   VARCHAR(256) NOT NULL,
      `txType`                      VARCHAR(32) NOT NULL,
      `variety`                     VARCHAR(100) NOT NULL,
      `dateOfMature`                DATETIME NOT NULL,
      `dateOfProduction`            DATETIME NOT NULL,
      `appearanceRating`            INT NOT NULL,
      `sizeRating`                  INT NOT NULL,
      `sweetnessRating`             INT NOT NULL,
      `minQuantity`                 INT NOT NULL,
      `maxQuantity`                 INT NOT NULL,
      `price`                       FLOAT NOT NULL,
      `cityOfLocation`              VARCHAR(100) NOT NULL,
      `matchedQuantity`             FLOAT DEFAULT NULL,
      `totalPrice`                  FLOAT DEFAULT NULL,
      `status`                      TINYINT(4) NOT NULL,
      KEY `idx_address`             (`address`),
      KEY `idx_initiator`           (`initiator`)
    ) ENGINE=InnoDB;
    TRUNCATE TABLE contract_match.`temp_cmu_vendition`; 
    
    -- xiaoshou
    INSERT INTO contract_match.`temp_cmu_purchase`(address, initiator, txType, variety, dateOfMature, dateOfProduction, appearanceRating, sizeRating, sweetnessRating, minQuantity, maxQuantity, price, cityOfLocation)
         SELECT address, initiator, txType, variety, dateOfMature, dateOfProduction, appearanceRating, sizeRating, sweetnessRating, minQuantity, maxQuantity, price, cityOfLocation
           FROM contract_match.transactions
          WHERE `status` = 0
            AND txType = 'purchase';-- xiaoshou
    
    -- goumai
    INSERT INTO contract_match.`temp_cmu_vendition`(address, initiator, txType, variety, dateOfMature, dateOfProduction, appearanceRating, sizeRating, sweetnessRating, minQuantity, maxQuantity, price, cityOfLocation,`status`)
         SELECT address, initiator, txType, variety, dateOfMature, dateOfProduction, appearanceRating, sizeRating, sweetnessRating, minQuantity, maxQuantity, price, cityOfLocation,`status`
           FROM contract_match.transactions
          WHERE `status` = 0
            AND txType = 'vendition';

    #begin match
    OPEN curl;
    REPEAT
        FETCH curl INTO v_address, v_initiator, v_txType, v_variety, v_dateOfMature, v_dateOfProduction, v_appearanceRating,v_sizeRating, 
                        v_sweetnessRating, v_minQuantity, v_maxQuantity, v_price, v_cityOfLocation,v_matchedQuantity,v_totalPrice;
        IF NOT v_done THEN
            
            SELECT IFNULL(GROUP_CONCAT(address ORDER BY price DESC),''),COUNT(1),SUM(maxQuantity)
              INTO v_addresslist,v_cnt,v_sum_maxQuantity
              FROM contract_match.`temp_cmu_vendition` 
             WHERE `status` = 0
              #AND initiator <> v_initiator
              #AND txType = 'vendition'
               AND dateOfMature = v_dateOfMature
               AND dateOfProduction = v_dateOfProduction
               AND appearanceRating = v_appearanceRating
               AND sizeRating = v_sizeRating
               AND sweetnessRating = v_sweetnessRating
               AND cityOfLocation = v_cityOfLocation
               AND price >= v_price
               AND maxQuantity > 0;
            
            IF v_sum_maxQuantity >= v_minQuantity THEN
                -- begin to match detail
                SET v_start = 1;
                WHILE v_cnt >= v_start AND v_maxQuantity > 0 DO
                    SET v_vend_address = commons.`Util.getField2`(v_addresslist,',',v_start);
                
                    SELECT minQuantity, maxQuantity ,price
                      INTO v_vend_minQuantity,v_vend_maxQuantity,v_vend_price
                      FROM contract_match.`temp_cmu_vendition` 
                     WHERE address = v_vend_address;
                    
                    IF v_vend_maxQuantity >= v_minQuantity AND v_vend_maxQuantity <= v_maxQuantity THEN
                        UPDATE contract_match.`temp_cmu_vendition` 
                           SET totalPrice = IFNULL(totalPrice,0) + v_vend_maxQuantity * v_vend_price,
                               `status` = 1,
                               `maxQuantity` = 0,
                               `matchedQuantity` = IFNULL(matchedQuantity,0) + v_vend_maxQuantity
                         WHERE address = v_vend_address;
                        
                        SET v_matchedQuantity = IFNULL(v_matchedQuantity,0) + v_vend_maxQuantity;
                        SET v_totalPrice = IFNULL(v_totalPrice,0) + v_vend_maxQuantity * v_vend_price;
                        SET v_maxQuantity = v_maxQuantity - v_vend_maxQuantity;
                        SET v_minQuantity = 0;
                    ELSEIF v_vend_maxQuantity >= v_minQuantity AND v_vend_maxQuantity > v_maxQuantity THEN
                        IF v_maxQuantity >= v_vend_minQuantity THEN
                            UPDATE contract_match.`temp_cmu_vendition` 
                               SET totalPrice = IFNULL(totalPrice,0) + v_maxQuantity * v_vend_price,
                                   `maxQuantity` = maxQuantity - v_maxQuantity,
                                   `minQuantity` = 0,
                                   `matchedQuantity` = IFNULL(matchedQuantity,0) + v_maxQuantity
                             WHERE address = v_vend_address;
                             
                            SET v_matchedQuantity = IFNULL(v_matchedQuantity,0) + v_maxQuantity;
                            SET v_totalPrice = IFNULL(v_totalPrice,0) + v_maxQuantity * v_vend_price;
                            SET v_maxQuantity = 0;
                            SET v_minQuantity = 0; 
                        END IF;
                    END IF;
                    SET v_start = v_start + 1;
                END WHILE;
                
                UPDATE contract_match.`temp_cmu_purchase` 
                   SET matchedQuantity = v_matchedQuantity,
                       totalPrice = v_totalPrice
                 WHERE address = v_address;
                
            END IF;  
            
        END IF;
    UNTIL v_done END REPEAT;
    CLOSE curl;
    
    #update purchase final result
    UPDATE contract_match.transactions a,
           contract_match.`temp_cmu_purchase` b
       SET a.`status` = 1,
           a.matchedQuantity = b.matchedQuantity,
           a.totalPrice = b.totalPrice
     WHERE a.address = b.address
       AND b.totalPrice > 0;

    #update vendition final result
    UPDATE contract_match.transactions a,
           contract_match.`temp_cmu_vendition` b
       SET a.`status` = 1,
           a.matchedQuantity = b.matchedQuantity,
           a.totalPrice = b.totalPrice
     WHERE a.address = b.address
       AND b.totalPrice > 0;

    TRUNCATE TABLE contract_match.`temp_cmu_purchase`;
    TRUNCATE TABLE contract_match.`temp_cmu_vendition`;
    DROP TABLE IF EXISTS contract_match.`temp_cmu_purchase`;
    DROP TABLE IF EXISTS contract_match.`temp_cmu_vendition`;
     
    SET returnCode_o = 200;
	SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,NULL,returnMsg_o,v_returnCode,v_returnMsg);
END
$$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;