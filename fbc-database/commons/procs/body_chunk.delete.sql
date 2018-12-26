USE `commons`;

/*Procedure structure for Procedure `body_chunk.delete` */;

DROP PROCEDURE IF EXISTS `body_chunk.delete`;

DELIMITER $$
CREATE DEFINER=`dba`@`%` PROCEDURE `body_chunk.delete`(uuid_i VARCHAR(100))
BEGIN
    DELETE FROM commons.post_body_cache WHERE uuid = uuid_i;
END
$$
DELIMITER ;
