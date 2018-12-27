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

cd $LOCAL/commons/datas
if [ $? -eq 0 ]
then
    echo "/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;\n/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;\n" >commons_datas.sql

    for FN in `ls`
    do
        echo "  Compile $FN"
        cat $FN >> commons_datas.sql
    done
    echo "/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;\n/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;" >> commons_datas.sql
    mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT commons < commons_datas.sql
    returnCode=$[ $returnCode+$? ]
    rm commons_datas.sql
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
echo "Schema commons Compile End"


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
echo "Schema blockchain_cache Compile End"

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

echo "Schema users Compile Begin"
mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT -e "drop database if exists users"
mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT -e "create database if not exists users"

cd $LOCAL/users/tables
if [ $? -eq 0 ]
then
    echo "/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;\n/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;\n" >users_tables.sql

    for FN in `ls`
    do
        echo "  Compile $FN"
        cat $FN >> users_tables.sql
    done
    echo "/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;\n/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;" >>users_tables.sql
    mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT users < users_tables.sql
    returnCode=$[ $returnCode+$? ]
    rm users_tables.sql
fi

cd $LOCAL/users/funcs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT users < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/users/procs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT users < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi
echo "Schema users Compile End"

if [ $returnCode -gt 0 ]
then
    echo "$returnCode"
    exit 1
else
    echo "$returnCode"
    exit 0
fi