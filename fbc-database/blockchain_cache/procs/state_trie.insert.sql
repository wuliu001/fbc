USE `blockchain_cache`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `state_trie.insert` */;

DROP PROCEDURE IF EXISTS `state_trie.insert`;

DELIMITER $$
USE `blockchain_cache`$$
CREATE PROCEDURE `state_trie.insert`( 
    pre_stateRoot_i             VARCHAR(256),
    OUT returnCode_o            INT,
    OUT returnMsg_o             LONGTEXT
    )
ll:BEGIN
    DECLARE v_procname          VARCHAR(64) DEFAULT 'state_trie.insert';
    DECLARE v_modulename        VARCHAR(50) DEFAULT 'blockchainCache';
    DECLARE v_params_body       LONGTEXT DEFAULT NULL;
    DECLARE v_returnCode        INT DEFAULT 0;
    DECLARE v_returnMsg         LONGTEXT DEFAULT '';
    
    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION BEGIN
        SHOW WARNINGS;
        GET DIAGNOSTICS CONDITION 1 v_returnCode = MYSQL_ERRNO, v_returnMsg = MESSAGE_TEXT;
        SET returnCode_o = 400;
        SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error: ', IFNULL(returnMsg_o,'') , ' | ' ,v_returnMsg);
        CALL `commons`.`log_module.e`(0,v_modulename,v_procname,v_params_body,'',returnMsg_o,v_returnCode,v_returnMsg);
    END;
    
    SET returnCode_o = 400;
    SET returnMsg_o = CONCAT(v_modulename, ' ', v_procname, ' command Error');
    SET v_params_body = CONCAT('{"pre_stateRoot_i":"',IFNULL(pre_stateRoot_i,''),'"}');

    SET returnMsg_o = 'generate state_object trie info.';
    # example: accountAddress: 3a95cdadfbe8b62a18f333c38b515085
    # alias: 3a95cdadfbe8b62a18f333c38b515085

    SET returnMsg_o = 'generate the 4th layer data in state_trie.';
    INSERT INTO blockchain_cache.state_trie(hash,alias,layer,address)
         SELECT MD5(accountAddress),accountAddress,4,accountAddress
           FROM blockchain_cache.state_object
          WHERE delete_flag = 0;

    # alias: 3a_95
    SET returnMsg_o = 'generate the 3rd layer data in state_trie.';
    INSERT INTO blockchain_cache.state_trie(alias,layer)
         SELECT CONCAT(SUBSTR(SUBSTR(alias,1,4),1,2),'_',SUBSTR(SUBSTR(alias,1,4),3,2)),3
           FROM blockchain_cache.state_trie
          WHERE layer = 4
            AND delete_flag = 0
          GROUP BY CONCAT(SUBSTR(SUBSTR(alias,1,4),1,2),'_',SUBSTR(SUBSTR(alias,1,4),3,2));

    # alias: 3a
    SET returnMsg_o = 'generate the 2nd layer data in state_trie.';
    INSERT INTO blockchain_cache.state_trie(alias,layer)
         SELECT SUBSTR(alias,1,2),2
           FROM blockchain_cache.state_trie
          WHERE layer = 3
            AND delete_flag = 0
          GROUP BY SUBSTR(alias,1,2);

    SET returnMsg_o = 'get 2nd layer data from statedb.state_trie.';
    INSERT INTO blockchain_cache.state_trie(hash,alias,layer)
         SELECT a.hash,a.alias,a.layer
           FROM statedb.state_trie a
          WHERE a.parentHash = pre_stateRoot_i
            AND a.layer = 2
            AND NOT EXISTS (SELECT 1 FROM blockchain_cache.state_trie b WHERE b.layer = 2 AND b.alias = a.alias AND b.delete_flag = 0);

    SET returnMsg_o = 'get 3rd layer data from statedb.state_trie.';
    INSERT INTO blockchain_cache.state_trie(hash,alias,layer)
         SELECT b.hash,b.alias,b.layer
           FROM statedb.state_trie a,
                statedb.state_trie b
          WHERE a.parentHash = pre_stateRoot_i
            AND a.layer = 2
            AND EXISTS (SELECT 1 FROM blockchain_cache.state_trie c WHERE c.layer = 2 AND c.alias = a.alias AND c.hash = '' AND c.delete_flag = 0)
            AND b.parentHash = a.hash
            AND b.layer = 3
            AND NOT EXISTS (SELECT 1 FROM blockchain_cache.state_trie d WHERE d.layer = 3 AND d.alias = b.alias AND d.delete_flag = 0);

    SET returnMsg_o = 'get 4th layer data from statedb.state_trie.';
    INSERT INTO blockchain_cache.state_trie(hash,alias,layer,address)
         SELECT c.hash,c.alias,c.layer,c.address
           FROM statedb.state_trie a,
                statedb.state_trie b,
                statedb.state_trie c
          WHERE a.parentHash = pre_stateRoot_i
            AND a.layer = 2
            AND EXISTS (SELECT 1 FROM blockchain_cache.state_trie d WHERE d.layer = 2 AND d.alias = a.alias AND d.hash = '' AND d.delete_flag = 0)
            AND b.parentHash = a.hash
            AND b.layer = 3
            AND EXISTS (SELECT 1 FROM blockchain_cache.state_trie e WHERE e.layer = 3 AND e.alias = b.alias AND e.hash = '' AND e.delete_flag = 0)
            AND c.parentHash = b.hash
            AND c.layer = 4
            AND NOT EXISTS (SELECT 1 FROM blockchain_cache.state_trie f WHERE f.layer = 4 AND f.alias = c.alias AND f.delete_flag = 0);

    SET returnMsg_o = 'update the 3rd layer hash value in blockchain_cache.state_trie.';
    UPDATE blockchain_cache.state_trie a,
           (SELECT CONCAT(SUBSTR(SUBSTR(alias,1,4),1,2),'_',SUBSTR(SUBSTR(alias,1,4),3,2)) AS pre_alias,
                    MD5(GROUP_CONCAT(hash)) AS hash
              FROM blockchain_cache.state_trie
             WHERE layer = 4
               AND delete_flag = 0
             GROUP BY CONCAT(SUBSTR(SUBSTR(alias,1,4),1,2),'_',SUBSTR(SUBSTR(alias,1,4),3,2))) b
       SET a.hash = b.hash
     WHERE a.alias = b.pre_alias
       AND a.delete_flag = 0
       AND a.layer = 3;

    SET returnMsg_o = 'update the 4th layer parentHash value in blockchain_cache.state_trie.';
    UPDATE blockchain_cache.state_trie a,
           blockchain_cache.state_trie b
       SET a.parentHash = b.hash
     WHERE a.layer = 4
       AND a.delete_flag = 0
       AND b.layer = 3
       AND b.delete_flag = 0
       AND REPLACE(b.alias,'_','') = SUBSTR(a.alias,1,4);

    SET returnMsg_o = 'update the 2nd layer hash value in blockchain_cache.state_trie.';
    UPDATE blockchain_cache.state_trie a,
           (SELECT SUBSTR(alias,1,2) AS pre_alias,
                   MD5(GROUP_CONCAT(hash)) AS hash
              FROM blockchain_cache.state_trie
             WHERE layer = 3
               AND delete_flag = 0
             GROUP BY SUBSTR(alias,1,2)) b
       SET a.hash = b.hash
     WHERE a.alias = b.pre_alias
       AND a.delete_flag = 0
       AND a.layer = 2
       AND a.hash = '';

    SET returnMsg_o = 'update the 3rd layer parentHash value in blockchain_cache.state_trie.';
    UPDATE blockchain_cache.state_trie a,
           blockchain_cache.state_trie b
       SET a.parentHash = b.hash
     WHERE a.layer = 3
       AND a.delete_flag = 0
       AND b.layer = 2
       AND b.delete_flag = 0
       AND b.alias = SUBSTR(a.alias,1,2);

    SET returnMsg_o = 'generate stateRoot (1st layer) data.';
    INSERT INTO blockchain_cache.state_trie(hash,layer)
         SELECT MD5(GROUP_CONCAT(hash)),1
           FROM blockchain_cache.state_trie
          WHERE layer = 2
            AND delete_flag = 0;

    SET returnMsg_o = 'update the 2nd layer parentHash value in blockchain_cache.state_trie.';
    UPDATE blockchain_cache.state_trie a,
           blockchain_cache.state_trie b
       SET a.parentHash = b.hash
     WHERE a.layer = 2
       AND a.delete_flag = 0
       AND b.layer = 1
       AND b.delete_flag = 0;

    SET returnCode_o = 200;
    SET returnMsg_o = 'OK';
    CALL `commons`.`log_module.i`(0,v_modulename,v_procname,v_params_body,'',returnMsg_o,v_returnCode,v_returnMsg);
    
END $$
DELIMITER ;
/*!50003 SET sql_mode = @saved_sql_mode */;