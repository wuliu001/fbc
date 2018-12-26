#!/bin/bash

returnCode=0

while getopts ":u:" opt
do
    case $opt in
        u)
            IS_UPGRADE=$OPTARG
            ;;
        \?)
            IS_UPGRADE=0
            ;;
    esac
done

if [[ ! $IS_UPGRADE || $IS_UPGRADE != 1 ]]; then
    IS_UPGRADE=0
fi

LOCAL=$(dirname `readlink -f $0`)
source $LOCAL/deploy_msg_queues.conf

cd $LOCAL
../commons/deploy_commons.sh $HOSTNAME $LOGIN $PASSW0RD $PORT $IS_UPGRADE
returnCode=$[ $returnCode+$? ]
if [ $returnCode -gt 0 ]
then
    echo "deploy commons fail!"
    exit 1
fi

if [ $IS_UPGRADE -eq 0 ]
then
    echo "Create DB"
    mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT mysql < $LOCAL/dbDeployScript/createDB.sql
fi

echo "Schema msg_queues Compile Begin"
if [ $IS_UPGRADE -eq 0 ]
then
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
        mysql -h$HOSTNAME -udba -pmysql -P$PORT msg_queues < msg_queues_tables.sql
        returnCode=$[ $returnCode+$? ]
        rm msg_queues_tables.sql
    fi
fi

cd $LOCAL/msg_queues/funcs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -udba -pmysql -P$PORT msg_queues < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/msg_queues/procs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -udba -pmysql -P$PORT msg_queues < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/msg_queues/jobs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -udba -pmysql -P$PORT msg_queues < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

echo " Init msg_queues's Data"
return_info=`mysql -h$HOSTNAME -udba -pmysql -P$PORT msg_queues -e 'call msg_queues.Init_data(0,@a,@b);select @a,@b;'`;
returnCode=$[ $returnCode+$? ]
code=`echo $return_info | awk '{print $3}'`
if [ $code -ne 200 ]
then
    echo "Init msg_queues's Data Fail."
    returnCode=$[ $returnCode+1 ]
fi

echo "Schema msg_queues Compile End"

if [ $returnCode -gt 0 ]
then
    echo "$returnCode"
    exit 1
else
    echo "$returnCode"
    exit 0
fi
