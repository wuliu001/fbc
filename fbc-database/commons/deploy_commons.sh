#!/bin/bash

HOSTNAME=$1
LOGIN=$2
PASSW0RD=$3
PORT=$4
IS_UPGRADE=$5
returnCode=0

usage()
{
    echo ""
    echo "USAGE:"
    echo 'deploy_commons.sh HOSTNAME LOGIN PASSW0RD PORT IS_UPGRADE'
    echo ' '
}

if [ $# -lt 5 ]
then
    echo "Not enough parameters passed in!"
    usage
    exit 1
fi

if [ `ps -ef | grep /usr/sbin/mysqld | grep -v grep | wc -l` -eq 0 ] ; then
    service mysql start
    returnCode=$[ $returnCode+$? ]
fi

if [ `ps -ef | grep /usr/sbin/mysqld | grep -v grep | wc -l` -eq 0 ] ; then
    service mysql start
    returnCode=$[ $returnCode+$? ]
fi

LOCAL=$(dirname `readlink -f $0`)

if [ $IS_UPGRADE -eq 0 ]
then
    echo "Check whether drop all database..."
    return_info=`mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT commons -e 'call redeploy_commons(0,@a,@b,@c);select @a,@b,@c;'`
    status=$?
    eval $(echo "$return_info" | sed '/^$/d'| tail -1 | awk '{ printf("isdrop=\"%s\"; retcode=\"%s\";\n",$1,$2); }');
    if [ $status -ne 0 ] || [ $isdrop -eq 1 -a $retcode -eq 200  ] ; then
       echo "Create DB"
       mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT mysql < $LOCAL/dbDeployScript/createDB.sql
       echo "Create User"
       mysql -h$HOSTNAME -u$LOGIN -p$PASSW0RD -P$PORT mysql < $LOCAL/dbDeployScript/createUser.sql
    elif [ $retcode -ne  200 ]; then
       echo "$return_info"
       exit 1;
    fi
fi

mysql -h$HOSTNAME -udba -pmysql -P$PORT -e 'show processlist'
returnCode=$[ $returnCode+$? ]
mysql -h$HOSTNAME -uws -pygomi -P$PORT -e 'show processlist'
returnCode=$[ $returnCode+$? ]


echo "Schema commons Compile Begin"
if [ $IS_UPGRADE -eq 0 ]
then
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
        mysql -h$HOSTNAME -udba -pmysql -P$PORT commons < commons_tables.sql
        returnCode=$[ $returnCode+$? ]
        rm commons_tables.sql
    fi
fi

cd $LOCAL/commons/funcs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -udba -pmysql -P$PORT commons < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

cd $LOCAL/commons/procs
if [ $? -eq 0 ]
then
    for FN in `ls`
    do
        echo "  Compile $FN"
        mysql -h$HOSTNAME -udba -pmysql -P$PORT commons < $FN
        returnCode=$[ $returnCode+$? ]
    done
fi

echo "Schema commons Compile End"

#if [ $IS_UPGRADE -eq 1 ]
#then
#    echo "Upgrade Database"
#    return_info=`mysql -h$HOSTNAME -udba -pmysql -P$PORT commons -e 'call commons.\`upgrade.version_check\`(0,@a,@b);select @a,@b;'`
#    returnCode=$[ $returnCode+$? ]
#    code=`echo $return_info | awk '{print $3}'`
#    if [ $code -ne 200 ]
#    then
#        echo "Upgrade Database Fail."
#        returnCode=$[ $returnCode+1 ]
#    fi
#fi

echo "Init commons's Data"
return_info=`mysql -h$HOSTNAME -udba -pmysql -P$PORT commons -e 'call commons.Init_data(0,@a,@b);select @a,@b;'`
returnCode=$[ $returnCode+$? ]
code=`echo $return_info | awk '{print $3}'`
if [ $code -ne 200 ]
then
    echo "Init commons's Data Fail."
    returnCode=$[ $returnCode+1 ]
fi

echo 'set last deployment time'
return_info=`mysql -h$HOSTNAME -udba -pmysql -P$PORT commons -e 'call commons.set_deploy_time(0,@a,@b);select @a,@b;'`
returnCode=$[ $returnCode+$? ]
code=`echo $return_info | awk '{print $3}'`
if [ $code -ne 200 ]
then
    echo "set last deployment time Fail."
    returnCode=$[ $returnCode+1 ]
fi

if [ $returnCode -gt 0 ]
then
    echo "$returnCode"
    exit 1
else
    echo "$returnCode"
    exit 0
fi