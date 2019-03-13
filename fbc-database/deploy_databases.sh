#!/bin/bash

HOSTNAME=$1
LOGIN=$2
PASSW0RD=$3
PORT=$4
returnCode=0

usage()
{
        echo ""
        echo "USAGE:"
        echo 'deploy_databases.sh HOSTNAME LOGIN PASSW0RD PORT'
        echo ' '
}

if [ $# -lt 4 ]
then
        echo "Not enough parameters passed in!"
        usage
        exit 1
fi

LOCAL=$(dirname `readlink -f $0`)
HOSTNAME=$(echo $HOSTNAME | tr '[A-Z]' '[a-z]')

echo "Schema blockchain Compile Begin"
mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT -e "drop database if exists blockchain"
mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT -e "create database if not exists blockchain"

cd $LOCAL/blockchain/tables
if [ $? -eq 0 ]
then
    echo "/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;\n/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;\n" >blockchain_tables.sql

    for FN in `ls`
    do
        echo "  Compile $FN"
        cat $FN >> blockchain_tables.sql
    done
    echo "/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;\n/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;" >>blockchain_tables.sql
    mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT blockchain < blockchain_tables.sql
    returnCode=$[ $returnCode+$? ]
    rm blockchain_tables.sql
fi

cd $LOCAL/blockchain/funcs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT blockchain < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/blockchain/procs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT blockchain < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/blockchain/jobs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT blockchain < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/blockchain/datas
if [ $? -eq 0 ]
then
    echo "/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;\n/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;\n" >msg_queues_datas.sql

    for FN in `ls`
    do
        echo "  Compile $FN"
        cat $FN >> blockchain_datas.sql
    done
    echo "/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;\n/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;" >> msg_queues_datas.sql
    mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT blockchain < blockchain_datas.sql
    returnCode=$[ $returnCode+$? ]
    rm blockchain_datas.sql
fi

echo "Schema blockchain Compile End"

echo "Schema blockchain_cache Compile Begin"
mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT -e "drop database if exists blockchain_cache"
mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT -e "create database if not exists blockchain_cache"

cd $LOCAL/blockchain_cache/tables
if [ $? -eq 0 ]
then
    echo "/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;\n/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;\n" >blockchain_cache_tables.sql

    for FN in `ls`
    do
        echo "  Compile $FN"
        cat $FN >> blockchain_cache_tables.sql
    done
    echo "/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;\n/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;" >>blockchain_cache_tables.sql
    mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT blockchain_cache < blockchain_cache_tables.sql
    returnCode=$[ $returnCode+$? ]
    rm blockchain_cache_tables.sql
fi

cd $LOCAL/blockchain_cache/funcs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT blockchain_cache < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/blockchain_cache/procs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT blockchain_cache < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/blockchain_cache/jobs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT blockchain_cache < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/blockchain_cache/datas
if [ $? -eq 0 ]
then
    echo "/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;\n/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;\n" >msg_queues_datas.sql

    for FN in `ls`
    do
        echo "  Compile $FN"
        cat $FN >> blockchain_cache_datas.sql
    done
    echo "/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;\n/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;" >> msg_queues_datas.sql
    mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT blockchain_cache < blockchain_cache_datas.sql
    returnCode=$[ $returnCode+$? ]
    rm blockchain_cache_datas.sql
fi

echo "Schema blockchain_cache Compile End"

echo "Schema commons Compile Begin"
mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT -e "drop database if exists commons"
mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT -e "create database if not exists commons"

cd $LOCAL/commons/tables
if [ $? -eq 0 ]
then
    echo "/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;\n/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;\n" >commons_tables.sql

    for FN in `ls`
    do
        echo "  Compile $FN"
        cat $FN >> commons_tables.sql
    done
    echo "/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;\n/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;" >>commons_tables.sql
    mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT commons < commons_tables.sql
    returnCode=$[ $returnCode+$? ]
    rm commons_tables.sql
fi

cd $LOCAL/commons/funcs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT commons < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/commons/procs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT commons < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/commons/jobs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT commons < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/commons/datas
if [ $? -eq 0 ]
then
    echo "/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;\n/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;\n" >msg_queues_datas.sql

    for FN in `ls`
    do
        echo "  Compile $FN"
        cat $FN >> commons_datas.sql
    done
    echo "/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;\n/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;" >> msg_queues_datas.sql
    mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT commons < commons_datas.sql
    returnCode=$[ $returnCode+$? ]
    rm commons_datas.sql
fi

echo "Schema commons Compile End"

echo "Schema msg_queues Compile Begin"
mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT -e "drop database if exists msg_queues"
mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT -e "create database if not exists msg_queues"

cd $LOCAL/msg_queues/tables
if [ $? -eq 0 ]
then
    echo "/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;\n/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;\n" >msg_queues_tables.sql

    for FN in `ls`
    do
        echo "  Compile $FN"
        cat $FN >> msg_queues_tables.sql
    done
    echo "/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;\n/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;" >>msg_queues_tables.sql
    mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT msg_queues < msg_queues_tables.sql
    returnCode=$[ $returnCode+$? ]
    rm msg_queues_tables.sql
fi

cd $LOCAL/msg_queues/funcs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT msg_queues < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/msg_queues/procs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT msg_queues < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/msg_queues/jobs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT msg_queues < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/msg_queues/datas
if [ $? -eq 0 ]
then
    echo "/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;\n/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;\n" >msg_queues_datas.sql

    for FN in `ls`
    do
        echo "  Compile $FN"
        cat $FN >> msg_queues_datas.sql
    done
    echo "/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;\n/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;" >> msg_queues_datas.sql
    mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT msg_queues < msg_queues_datas.sql
    returnCode=$[ $returnCode+$? ]
    rm msg_queues_datas.sql
fi

echo "Schema msg_queues Compile End"

echo "Schema centerdb Compile Begin"
mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT -e "drop database if exists centerdb"
mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT -e "create database if not exists centerdb"

cd $LOCAL/centerdb/tables
if [ $? -eq 0 ]
then
    echo "/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;\n/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;\n" >centerdb_tables.sql

    for FN in `ls`
    do
        echo "  Compile $FN"
        cat $FN >> centerdb_tables.sql
    done
    echo "/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;\n/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;" >>centerdb_tables.sql
    mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT centerdb < centerdb_tables.sql
    returnCode=$[ $returnCode+$? ]
    rm centerdb_tables.sql
fi

cd $LOCAL/centerdb/funcs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT centerdb < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/centerdb/procs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT centerdb < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/centerdb/jobs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT centerdb < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/centerdb/datas
if [ $? -eq 0 ]
then
    echo "/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;\n/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;\n" >centerdb_datas.sql

    for FN in `ls`
    do
        echo "  Compile $FN"
        cat $FN >> centerdb_datas.sql
    done
    echo "/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;\n/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;" >> centerdb_datas.sql
    mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT centerdb < centerdb_datas.sql
    returnCode=$[ $returnCode+$? ]
    rm centerdb_datas.sql
fi

echo "Schema centerdb Compile End"

echo "Schema keystore Compile Begin"
mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT -e "drop database if exists keystore"
mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT -e "create database if not exists keystore"

cd $LOCAL/keystore/tables
if [ $? -eq 0 ]
then
    echo "/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;\n/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;\n" >keystore_tables.sql

    for FN in `ls`
    do
        echo "  Compile $FN"
        cat $FN >> keystore_tables.sql
    done
    echo "/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;\n/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;" >>keystore_tables.sql
    mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT keystore < keystore_tables.sql
    returnCode=$[ $returnCode+$? ]
    rm keystore_tables.sql
fi

cd $LOCAL/keystore/funcs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT keystore < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/keystore/procs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT keystore < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/keystore/jobs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT keystore < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/keystore/datas
if [ $? -eq 0 ]
then
    echo "/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;\n/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;\n" >keystore_datas.sql

    for FN in `ls`
    do
        echo "  Compile $FN"
        cat $FN >> keystore_datas.sql
    done
    echo "/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;\n/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;" >> keystore_datas.sql
    mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT keystore < keystore_datas.sql
    returnCode=$[ $returnCode+$? ]
    rm keystore_datas.sql
fi

echo "Schema keystore Compile End"

echo "Schema receipt Compile Begin"
mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT -e "drop database if exists receipt"
mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT -e "create database if not exists receipt"

cd $LOCAL/receipt/tables
if [ $? -eq 0 ]
then
    echo "/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;\n/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;\n" >receipt_tables.sql

    for FN in `ls`
    do
        echo "  Compile $FN"
        cat $FN >> receipt_tables.sql
    done
    echo "/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;\n/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;" >>receipt_tables.sql
    mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT receipt < receipt_tables.sql
    returnCode=$[ $returnCode+$? ]
    rm receipt_tables.sql
fi

cd $LOCAL/receipt/funcs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT receipt < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/receipt/procs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT receipt < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/receipt/jobs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT receipt < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/receipt/datas
if [ $? -eq 0 ]
then
    echo "/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;\n/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;\n" >receipt_datas.sql

    for FN in `ls`
    do
        echo "  Compile $FN"
        cat $FN >> receipt_datas.sql
    done
    echo "/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;\n/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;" >> receipt_datas.sql
    mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT receipt < receipt_datas.sql
    returnCode=$[ $returnCode+$? ]
    rm receipt_datas.sql
fi

echo "Schema receipt Compile End"

echo "Schema statedb Compile Begin"
mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT -e "drop database if exists statedb"
mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT -e "create database if not exists statedb"

cd $LOCAL/statedb/tables
if [ $? -eq 0 ]
then
    echo "/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;\n/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;\n" >statedb_tables.sql

    for FN in `ls`
    do
        echo "  Compile $FN"
        cat $FN >> statedb_tables.sql
    done
    echo "/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;\n/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;" >>statedb_tables.sql
    mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT statedb < statedb_tables.sql
    returnCode=$[ $returnCode+$? ]
    rm statedb_tables.sql
fi

cd $LOCAL/statedb/funcs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT statedb < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/statedb/procs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT statedb < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/statedb/jobs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT statedb < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/statedb/datas
if [ $? -eq 0 ]
then
    echo "/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;\n/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;\n" >statedb_datas.sql

    for FN in `ls`
    do
        echo "  Compile $FN"
        cat $FN >> statedb_datas.sql
    done
    echo "/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;\n/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;" >> statedb_datas.sql
    mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT statedb < statedb_datas.sql
    returnCode=$[ $returnCode+$? ]
    rm statedb_datas.sql
fi

echo "Schema statedb Compile End"

echo "Schema tx_cache Compile Begin"
mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT -e "drop database if exists tx_cache"
mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT -e "create database if not exists tx_cache"

cd $LOCAL/tx_cache/tables
if [ $? -eq 0 ]
then
    echo "/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;\n/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;\n" >tx_cache_tables.sql

    for FN in `ls`
    do
        echo "  Compile $FN"
        cat $FN >> tx_cache_tables.sql
    done
    echo "/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;\n/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;" >>tx_cache_tables.sql
    mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT tx_cache < tx_cache_tables.sql
    returnCode=$[ $returnCode+$? ]
    rm tx_cache_tables.sql
fi

cd $LOCAL/tx_cache/funcs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT tx_cache < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/tx_cache/procs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT tx_cache < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/tx_cache/jobs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT tx_cache < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/tx_cache/datas
if [ $? -eq 0 ]
then
    echo "/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;\n/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;\n" >tx_cache_datas.sql

    for FN in `ls`
    do
        echo "  Compile $FN"
        cat $FN >> tx_cache_datas.sql
    done
    echo "/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;\n/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;" >> tx_cache_datas.sql
    mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT tx_cache < tx_cache_datas.sql
    returnCode=$[ $returnCode+$? ]
    rm tx_cache_datas.sql
fi

echo "Schema tx_cache Compile End"

echo "Schema transactions Compile Begin"
mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT -e "drop database if exists transactions"
mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT -e "create database if not exists transactions"

cd $LOCAL/transactions/tables
if [ $? -eq 0 ]
then
    echo "/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;\n/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;\n" >transactions_tables.sql

    for FN in `ls`
    do
        echo "  Compile $FN"
        cat $FN >> transactions_tables.sql
    done
    echo "/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;\n/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;" >>transactions_tables.sql
    mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT transactions < transactions_tables.sql
    returnCode=$[ $returnCode+$? ]
    rm transactions_tables.sql
fi

cd $LOCAL/transactions/funcs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT transactions < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/transactions/procs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT transactions < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/transactions/jobs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT transactions < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/transactions/datas
if [ $? -eq 0 ]
then
    echo "/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;\n/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;\n" >transactions_datas.sql

    for FN in `ls`
    do
        echo "  Compile $FN"
        cat $FN >> transactions_datas.sql
    done
    echo "/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;\n/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;" >> transactions_datas.sql
    mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT transactions < transactions_datas.sql
    returnCode=$[ $returnCode+$? ]
    rm transactions_datas.sql
fi

echo "Schema transactions Compile End"

echo "Schema contract_match Compile Begin"
mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT -e "drop database if exists contract_match"
mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT -e "create database if not exists contract_match"

cd $LOCAL/contract_match/tables
if [ $? -eq 0 ]
then
    echo "/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;\n/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;\n" >contract_match_tables.sql

    for FN in `ls`
    do
        echo "  Compile $FN"
        cat $FN >> contract_match_tables.sql
    done
    echo "/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;\n/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;" >>contract_match_tables.sql
    mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT contract_match < contract_match_tables.sql
    returnCode=$[ $returnCode+$? ]
    rm contract_match_tables.sql
fi

cd $LOCAL/contract_match/funcs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT contract_match < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/contract_match/procs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT contract_match < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/contract_match/jobs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT contract_match < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/contract_match/datas
if [ $? -eq 0 ]
then
    echo "/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;\n/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;\n" >contract_match_datas.sql

    for FN in `ls`
    do
        echo "  Compile $FN"
        cat $FN >> contract_match_datas.sql
    done
    echo "/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;\n/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;" >> contract_match_datas.sql
    mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT contract_match < contract_match_datas.sql
    returnCode=$[ $returnCode+$? ]
    rm contract_match_datas.sql
fi

echo "Schema contract_match Compile End"

echo "Schema contract_match Compile Begin"
mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT -e "drop database if exists contract_match"
mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT -e "create database if not exists contract_match"

cd $LOCAL/contract_match/tables
if [ $? -eq 0 ]
then
    echo "/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;\n/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;\n" >contract_match_tables.sql

    for FN in `ls`
    do
        echo "  Compile $FN"
        cat $FN >> contract_match_tables.sql
    done
    echo "/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;\n/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;" >>contract_match_tables.sql
    mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT contract_match < contract_match_tables.sql
    returnCode=$[ $returnCode+$? ]
    rm contract_match_tables.sql
fi

cd $LOCAL/contract_match/funcs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT contract_match < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/contract_match/procs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT contract_match < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/contract_match/jobs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT contract_match < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/contract_match/datas
if [ $? -eq 0 ]
then
    echo "/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;\n/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;\n" >msg_queues_datas.sql

    for FN in `ls`
    do
        echo "  Compile $FN"
        cat $FN >> contract_match_datas.sql
    done
    echo "/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;\n/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;" >> msg_queues_datas.sql
    mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT contract_match < contract_match_datas.sql
    returnCode=$[ $returnCode+$? ]
    rm contract_match_datas.sql
fi

echo "Schema contract_match Compile End"

if [ $returnCode -gt 0 ]
then
    echo "$returnCode"
    exit 1
else
    echo "$returnCode"
    exit 0
fi