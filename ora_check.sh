#!/bin/bash

####################################
# Please execute this script with hour parameter
# By default script checks all the ORA errors since listed number of hours until time of execution of the script.
# For example ./ora_check.sh 5
####################################

IFS=
alert_log_loc=`sqlplus  -L -s / as sysdba << EOF
set pagesize 0
set verify off
set head off
set feedback off
set lines 300
SELECT CONCAT(CONCAT(VALUE,'/alert_'),CONCAT(INSTANCE_NAME,'.log')) A FROM V\\$DIAG_INFO, V\\$INSTANCE where NAME='Diag Trace';
exit;
EOF
`
number_of_hours=$1
ora_date=`date -d "$var" "+%Y-%m-%dT%H"`
#ora_date=`date -d "$number_of_hours hour ago" "+%Y-%m-%dT%H"`
first_line=`grep -m 1 -n "$ora_date" $alert_log_loc | cut -f1 -d":"`

echo "Alert log file location : $alert_log_loc"
echo "Start date              : $dead_date"
echo "First line in alert log : $first_line"


if_empty_1(){
if [ -z "$1" ]
then

        echo "ERROR: Date variable is empty"
        echo "Execute scrip againt with valid date variable!"
        exit 1
#else
#       echo "$1 is NOT empty"
fi
}


print_log(){
        echo `tail -n +$first_line $alert_log_loc | grep -B 1 -in "ORA"`
}

if_empty_1 $1
print_log
