#!/bin/bash

####################################
# Please execute this script with date parameter in format YYYY-MM-DDTHH (For example 2022-05-01T12)
# By default script checks all the deadlocks since listed date parameter until time of execution of the script,
# there is possibility to limit output timeframe by adding second variable date.
# For example ./deadlock_check.sh 2022-05-18T10:49:03
# For example ./deadlock_check.sh 2022-05-18
# For example ./deadlock_check.sh 2022-05-18T01
# For example ./deadlock_check.sh 2022-04-12 2022-04-13
# For example ./deadlock_check.sh 2022-04-12T01 2022-04-13T23
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
dead_date=$1
end_dead_date=$2
first_line=`grep -m 1 -n "$dead_date" $alert_log_loc | cut -f1 -d":"`
end_line=`grep -m 1 -n "$end_dead_date" $alert_log_loc | cut -f1 -d":"`

echo "Alert log file location : $alert_log_loc"
echo "Start date of deadlocks : $dead_date"
echo "End date of deadlocks   : $end_dead_date"
echo "First line in alert log : $first_line"
echo "Last line in alert log  : $end_line"


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

if_empty_2(){
if [ -z "$1" ]
then
        echo "End date variable is empty"
#else
#        echo "$1 is NOT empty"
fi
}


print_log(){
if [ -z "$2" ]
then
        echo `tail -n +$first_line $alert_log_loc | grep -B 1 -in "ORA-00060: Deadlock detected"`
else
        lines_number=`head -n $end_line $alert_log_loc | tail -n $first_line | grep "ORA-00060: Deadlock detected" | wc -l`
        echo "Number of Deadlocks found for timeframe $dead_date - $end_dead_date : $lines_number"
        echo `head -n $end_line $alert_log_loc | tail -n $first_line | grep -B 1 -in "ORA-00060: Deadlock detected"`
fi
}


#while getopts ":v:" opt; do
#  case $opt in
#    v)
#      echo echo `head -n $end_line $alert_log_loc | tail -n $first_line | grep -B 1 -in "ORA-00060: Deadlock detected"`
#      ;;
#    \?)
#      echo "Invalid option: -$OPTARG" >&2
#      exit 1
#      ;;
#    :)
#      echo "Option -$OPTARG requires an argument." >&2
#      exit 1
#      ;;
#  esac
#done

if_empty_1 $1
#if_empty_2 $2
print_log $1 $2

