USE `blockchain_cache`;
/*!50003 SET @saved_sql_mode = @@sql_mode */;
/*!50003 SET sql_mode = 'STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */;

/*Procedure structure for Procedure `transaction_trie.insert` */;

DROP PROCEDURE IF EXISTS `transaction_trie.insert`;

DELIMITER $$
USE `blockchain_cache`$$
CREATE PROCEDURE `transaction_trie.insert`( 
    pre_txRoot_i                VARCHAR(256),
    OUT returnCode_o            INT,
    OUT returnMsg_o             LONGTEXT
    )
ll:BEGIN
    DECLARE v_procname          VARCHAR(64) DEFAULT 'transaction_trie.insert';
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
    SET v_params_body = CONCAT('{"pre_txRoot_i":"',IFNULL(pre_txRoot_i,''),'"}');

    SET returnMsg_o = 'generate transaction trie info.';
    # example: 
    # initiator accountAddress: 9ab5cdadfbe8b62a18f333c38b515085
    # receiver accountAddress: 3a43cdadfbe8b62a18f333c38b515085
    # tx address: ab89cdadfbe8b62a18f333c38b515085
    # request_timestamp: 2017-03-19 07:06:49

    # alias: ab89cdadfbe8b62a18f333c38b515085
    SET returnMsg_o = 'generate the 7th layer data in transaction_trie.';
    INSERT INTO blockchain_cache.transaction_trie(hash,alias,layer,address)
         SELECT MD5(address),address,7,address
           FROM blockchain_cache.transactions
          WHERE delete_flag = 0;
    
    # alias: 3a_43_9ab5cdadfbe8b62a18f333c38b515085_201703_19
    SET returnMsg_o = 'generate the 6th layer data in transaction_trie.';
    INSERT INTO blockchain_cache.transaction_trie(alias,layer)
         SELECT CONCAT(SUBSTR(b.receiver,1,2),'_',SUBSTR(b.receiver,3,2),'_',b.initiator,'_',DATE_FORMAT(b.request_timestamp,'%Y%m_%d')),6
           FROM blockchain_cache.transaction_trie a,
                blockchain_cache.transactions b
          WHERE a.layer = 7
            AND a.delete_flag = 0
            AND a.address = b.address
            AND b.delete_flag = 0
          GROUP BY CONCAT(SUBSTR(b.receiver,1,2),'_',SUBSTR(b.receiver,3,2),'_',b.initiator,'_',DATE_FORMAT(b.request_timestamp,'%Y%m_%d'));
    
    # alias: 3a_43_9ab5cdadfbe8b62a18f333c38b515085_201703
    SET returnMsg_o = 'generate the 5th layer data in transaction_trie.';
    INSERT INTO blockchain_cache.transaction_trie(alias,layer)
         SELECT SUBSTR(alias,1,LENGTH(alias)-3),5
           FROM blockchain_cache.transaction_trie
          WHERE layer = 6
            AND delete_flag = 0
          GROUP BY SUBSTR(alias,1,LENGTH(alias)-3);
    
    # alias: 3a_43_9ab5cdadfbe8b62a18f333c38b515085
    SET returnMsg_o = 'generate the 4th layer data in transaction_trie.';
    INSERT INTO blockchain_cache.transaction_trie(alias,layer)
         SELECT SUBSTR(alias,1,LENGTH(alias)-7),4
           FROM blockchain_cache.transaction_trie
          WHERE layer = 5
            AND delete_flag = 0
          GROUP BY SUBSTR(alias,1,LENGTH(alias)-7);

    # alias: 3a_43
    SET returnMsg_o = 'generate the 3rd layer data in transaction_trie.';
    INSERT INTO blockchain_cache.transaction_trie(alias,layer)
         SELECT SUBSTR(alias,1,5),3
           FROM blockchain_cache.transaction_trie
          WHERE layer = 4
            AND delete_flag = 0
          GROUP BY SUBSTR(alias,1,5);
    
    # alias: 3a
    SET returnMsg_o = 'generate the 2nd layer data in transaction_trie.';
    INSERT INTO blockchain_cache.transaction_trie(alias,layer)
         SELECT SUBSTR(alias,1,2),2
           FROM blockchain_cache.transaction_trie
          WHERE layer = 3
            AND delete_flag = 0
          GROUP BY SUBSTR(alias,1,2);
    
    SET returnMsg_o = 'get 2nd layer data from transactions.transaction_trie.';
    INSERT INTO blockchain_cache.transaction_trie(hash,alias,layer)
         SELECT a.hash,a.alias,a.layer
           FROM transactions.transaction_trie a
          WHERE a.parentHash = pre_txRoot_i
            AND a.layer = 2
            AND NOT EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie b WHERE b.layer = 2 AND b.alias = a.alias AND b.delete_flag = 0);
    
    SET returnMsg_o = 'get 3rd layer data from transactions.transaction_trie.';
    INSERT INTO blockchain_cache.transaction_trie(hash,alias,layer)
         SELECT b.hash,b.alias,b.layer
           FROM transactions.transaction_trie a,
                transactions.transaction_trie b
          WHERE a.parentHash = pre_txRoot_i
            AND a.layer = 2
            AND EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie c WHERE c.layer = 2 AND c.alias = a.alias AND c.hash = '' AND c.delete_flag = 0)
            AND b.parentHash = a.hash
            AND b.layer = 3
            AND NOT EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie d WHERE d.layer = 3 AND d.alias = b.alias AND d.delete_flag = 0);
    
    SET returnMsg_o = 'get 4th layer data from transactions.transaction_trie.';
    INSERT INTO blockchain_cache.transaction_trie(hash,alias,layer)
         SELECT c.hash,c.alias,c.layer
           FROM transactions.transaction_trie a,
                transactions.transaction_trie b,
                transactions.transaction_trie c
          WHERE a.parentHash = pre_txRoot_i
            AND a.layer = 2
            AND EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie d WHERE d.layer = 2 AND d.alias = a.alias AND d.hash = '' AND d.delete_flag = 0)
            AND b.parentHash = a.hash
            AND b.layer = 3
            AND EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie e WHERE e.layer = 3 AND e.alias = b.alias AND e.hash = '' AND e.delete_flag = 0)
            AND c.parentHash = b.hash
            AND c.layer = 4
            AND NOT EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie f WHERE f.layer = 4 AND f.alias = c.alias AND f.delete_flag = 0);
    
    SET returnMsg_o = 'get 5th layer data from transactions.transaction_trie.';
    INSERT INTO blockchain_cache.transaction_trie(hash,alias,layer)
         SELECT d.hash,d.alias,d.layer
           FROM transactions.transaction_trie a,
                transactions.transaction_trie b,
                transactions.transaction_trie c,
                transactions.transaction_trie d
          WHERE a.parentHash = pre_txRoot_i
            AND a.layer = 2
            AND EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie e WHERE e.layer = 2 AND e.alias = a.alias AND e.hash = '' AND e.delete_flag = 0)
            AND b.parentHash = a.hash
            AND b.layer = 3
            AND EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie f WHERE f.layer = 3 AND f.alias = b.alias AND f.hash = '' AND f.delete_flag = 0)
            AND c.parentHash = b.hash
            AND c.layer = 4
            AND EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie g WHERE g.layer = 4 AND g.alias = c.alias AND g.hash = '' AND g.delete_flag = 0)
            AND d.parentHash = c.hash
            AND d.layer = 5
            AND NOT EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie h WHERE h.layer = 5 AND h.alias = d.alias AND h.delete_flag = 0);

    SET returnMsg_o = 'get 6th layer data from transactions.transaction_trie.';
    INSERT INTO blockchain_cache.transaction_trie(hash,alias,layer)
         SELECT e.hash,e.alias,e.layer
           FROM transactions.transaction_trie a,
                transactions.transaction_trie b,
                transactions.transaction_trie c,
                transactions.transaction_trie d,
                transactions.transaction_trie e
          WHERE a.parentHash = pre_txRoot_i
            AND a.layer = 2
            AND EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie f WHERE f.layer = 2 AND f.hash = '' AND f.alias = a.alias AND f.delete_flag = 0)
            AND b.parentHash = a.hash
            AND b.layer = 3
            AND EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie g WHERE g.layer = 3 AND g.hash = '' AND g.alias = b.alias AND g.delete_flag = 0)
            AND c.parentHash = b.hash
            AND c.layer = 4
            AND EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie h WHERE h.layer = 4 AND h.hash = '' AND h.alias = c.alias AND h.delete_flag = 0)
            AND d.parentHash = c.hash
            AND d.layer = 5
            AND EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie i WHERE i.layer = 5 AND i.hash = '' AND i.alias = d.alias AND i.delete_flag = 0)
            AND e.parentHash = d.hash
            AND e.layer = 6
            AND NOT EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie j WHERE j.layer = 6 AND j.alias = e.alias AND j.delete_flag = 0);

    SET returnMsg_o = 'get 7th layer data from transactions.transaction_trie.';
    INSERT INTO blockchain_cache.transaction_trie(hash,alias,layer)
         SELECT f.hash,f.alias,f.layer
           FROM transactions.transaction_trie a,
                transactions.transaction_trie b,
                transactions.transaction_trie c,
                transactions.transaction_trie d,
                transactions.transaction_trie e,
                transactions.transaction_trie f
          WHERE a.parentHash = pre_txRoot_i
            AND a.layer = 2
            AND EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie g WHERE g.layer = 2 AND g.alias = a.alias AND g.hash = '' AND g.delete_flag = 0)
            AND b.parentHash = a.hash
            AND b.layer = 3
            AND EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie h WHERE h.layer = 3 AND h.alias = b.alias AND h.hash = '' AND h.delete_flag = 0)
            AND c.parentHash = b.hash
            AND c.layer = 4
            AND EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie i WHERE i.layer = 4 AND i.alias = c.alias AND i.hash = '' AND i.delete_flag = 0)
            AND d.parentHash = c.hash
            AND d.layer = 5
            AND EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie j WHERE j.layer = 5 AND j.alias = d.alias AND j.hash = '' AND j.delete_flag = 0)
            AND e.parentHash = d.hash
            AND e.layer = 6
            AND EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie k WHERE k.layer = 6 AND k.alias = e.alias AND k.hash = '' AND k.delete_flag = 0)
            AND f.parentHash = e.hash
            AND f.layer = 7
            AND NOT EXISTS (SELECT 1 FROM blockchain_cache.transaction_trie l WHERE l.layer = 7 AND l.alias = f.alias AND l.delete_flag = 0);

    SET returnMsg_o = 'update the 6th layer hash value in blockchain_cache.transaction_trie.';
    UPDATE blockchain_cache.transaction_trie a,
           (SELECT CONCAT(SUBSTR(c.receiver,1,2),'_',SUBSTR(c.receiver,3,2),'_',c.initiator,'_',DATE_FORMAT(c.request_timestamp,'%Y%m_%d')) AS pre_alias,
                   MD5(GROUP_CONCAT(b.hash)) AS hash
              FROM blockchain_cache.transaction_trie b,
                   blockchain_cache.transactions c
             WHERE b.layer = 7
               AND b.delete_flag = 0
               AND b.address = c.address
               AND c.delete_flag = 0
             GROUP BY CONCAT(SUBSTR(c.receiver,1,2),'_',SUBSTR(c.receiver,3,2),'_',c.initiator,'_',DATE_FORMAT(c.request_timestamp,'%Y%m_%d'))) d
       SET a.hash = d.hash
     WHERE a.alias = d.pre_alias
       AND a.layer = 6
       AND a.delete_flag = 0;

    SET returnMsg_o = 'update the 7th layer parentHash value in blockchain_cache.transaction_trie.';
    UPDATE blockchain_cache.transaction_trie a,
           (SELECT c.address,b.hash
              FROM blockchain_cache.transaction_trie b,
                   blockchain_cache.transactions c
             WHERE b.alias = CONCAT(SUBSTR(c.receiver,1,2),'_',SUBSTR(c.receiver,3,2),'_',c.initiator,'_',DATE_FORMAT(c.request_timestamp,'%Y%m_%d'))
               AND b.layer = 6
               AND b.delete_flag = 0
               AND c.delete_flag = 0) d
       SET a.parentHash = d.hash
     WHERE a.layer = 7
       AND a.delete_flag = 0
       AND a.address = d.address;

    SET returnMsg_o = 'update the 5th layer hash value in blockchain_cache.transaction_trie.';
    UPDATE blockchain_cache.transaction_trie a,
           (SELECT SUBSTR(alias,1,LENGTH(alias)-3) AS pre_alias,
                   MD5(GROUP_CONCAT(hash)) AS hash
              FROM blockchain_cache.transaction_trie
             WHERE layer = 6
               AND delete_flag = 0
             GROUP BY SUBSTR(alias,1,LENGTH(alias)-3)) b
       SET a.hash = b.hash
     WHERE a.alias = b.pre_alias
       AND a.layer = 5
       AND a.delete_flag = 0;
    
    SET returnMsg_o = 'update the 6th layer parentHash value in blockchain_cache.transaction_trie.';
    UPDATE blockchain_cache.transaction_trie a,
           blockchain_cache.transaction_trie b
       SET a.parentHash = b.hash
     WHERE a.layer = 6
       AND a.delete_flag = 0
       AND b.layer = 5
       AND b.delete_flag = 0
       AND b.alias = SUBSTR(a.alias,1,LENGTH(a.alias)-3);
    
    SET returnMsg_o = 'update the 4th layer hash value in blockchain_cache.transaction_trie.';
    UPDATE blockchain_cache.transaction_trie a,
           (SELECT SUBSTR(alias,1,LENGTH(alias)-7) AS pre_alias,
                   MD5(GROUP_CONCAT(hash)) AS hash
              FROM blockchain_cache.transaction_trie
             WHERE layer = 5
               AND delete_flag = 0
             GROUP BY SUBSTR(alias,1,LENGTH(alias)-7)) b
       SET a.hash = b.hash
     WHERE a.alias = b.pre_alias
       AND a.layer = 4
       AND a.delete_flag = 0;

    SET returnMsg_o = 'update the 5th layer parentHash value in blockchain_cache.transaction_trie.';
    UPDATE blockchain_cache.transaction_trie a,
           blockchain_cache.transaction_trie b
       SET a.parentHash = b.hash
     WHERE a.layer = 5
       AND a.delete_flag = 0
       AND b.layer = 4
       AND b.delete_flag = 0
       AND b.alias = SUBSTR(a.alias,1,LENGTH(a.alias)-7);

    SET returnMsg_o = 'update the 3rd layer hash value in blockchain_cache.transaction_trie.';
    UPDATE blockchain_cache.transaction_trie a,
           (SELECT SUBSTR(alias,1,5) AS pre_alias,
                   MD5(GROUP_CONCAT(hash)) AS hash
              FROM blockchain_cache.transaction_trie
             WHERE layer = 4
               AND delete_flag = 0
             GROUP BY SUBSTR(alias,1,5)) b
       SET a.hash = b.hash
     WHERE a.alias = b.pre_alias
       AND a.layer = 3
       AND a.delete_flag = 0;
    
    SET returnMsg_o = 'update the 4th layer parentHash value in blockchain_cache.transaction_trie.';
    UPDATE blockchain_cache.transaction_trie a,
           blockchain_cache.transaction_trie b
       SET a.parentHash = b.hash
     WHERE a.layer = 4
       AND a.delete_flag = 0
       AND b.layer = 3
       AND b.delete_flag = 0
       AND b.alias = SUBSTR(a.alias,1,5);

    SET returnMsg_o = 'update the 2nd layer hash value in blockchain_cache.transaction_trie.';
    UPDATE blockchain_cache.transaction_trie a,
           (SELECT SUBSTR(alias,1,2) AS pre_alias,
                   MD5(GROUP_CONCAT(hash)) AS hash
              FROM blockchain_cache.transaction_trie
             WHERE layer = 3
               AND delete_flag = 0
             GROUP BY SUBSTR(alias,1,2)) b
       SET a.hash = b.hash
     WHERE a.alias = b.pre_alias
       AND a.layer = 2
       AND a.delete_flag = 0
       AND a.hash = '';
    
    SET returnMsg_o = 'update the 3rd layer parentHash value in blockchain_cache.transaction_trie.';
    UPDATE blockchain_cache.transaction_trie a,
           blockchain_cache.transaction_trie b
       SET a.parentHash = b.hash
     WHERE a.layer = 3
       AND a.delete_flag = 0
       AND b.layer = 2
       AND b.delete_flag = 0
       AND b.alias = SUBSTR(a.alias,1,2);
    
    SET returnMsg_o = 'generate txRoot (1st layer) data in blockchain_cache.transaction_trie.';
    INSERT INTO blockchain_cache.transaction_trie(hash,layer)
         SELECT MD5(GROUP_CONCAT(hash)),1
           FROM blockchain_cache.transaction_trie
          WHERE layer = 2
            AND delete_flag = 0;

    SET returnMsg_o = 'update the 2nd layer parentHash value in blockchain_cache.transaction_trie.';
    UPDATE blockchain_cache.transaction_trie a,
           blockchain_cache.transaction_trie b
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