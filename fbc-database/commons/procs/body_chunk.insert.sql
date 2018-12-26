USE `commons`;

/*Procedure structure for Procedure `body_chunk.insert` */;

DROP PROCEDURE IF EXISTS `body_chunk.insert`;

DELIMITER $$
CREATE DEFINER=`dba`@`%` PROCEDURE `body_chunk.insert`(uuid_i VARCHAR(100), 
                                     order_i INT,
                                     body_chunk_i LONGTEXT)
BEGIN
    INSERT INTO commons.post_body_cache(uuid, ord, body_cache, create_time)
         VALUES (uuid_i, order_i, body_chunk_i, UTC_TIMESTAMP());
END
$$
DELIMITER ;
