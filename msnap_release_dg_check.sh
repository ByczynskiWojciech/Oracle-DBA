#!/bin/bash

##################################################################

#To execute script add mumimum number of minutes for apply lag
#between Primary and standby database as parameter.
#
#./msnap_release_dg_check.sh -t *Number for minimum apply lag on DG*
#
#For example:
#./msnap_release_dg_check.sh -t 15
#./msnap_release_dg_check.sh -v -t 15

##################################################################

PATH=$PATH:/bin:/usr/local/bin; export PATH

RECPT=wojciech.byczynski@dxc.com

validate_snap="N"
host_standby=DEVDBA02
target=DEVDBA02
DATA=`date "+%Y%m%d_%H%M%S"`
SNAP=/oracle/${target}/dba/${target}/msnap
mkdir -p ${SNAP}/log
mkdir -p ${SNAP}/tmp
pre_msnap_log=${SNAP}/log/prerequisite_msnap_log_${DATA}.log
dg_ent_time=$1


     ORACLE_SID=${target}
     ORAENV_ASK=NO

dg_lag_time=

Usage() {

cat << EOF

#######################################################
# Script for msnap while prod listener is down
#######################################################

USAGE: ./msnap_release_dg_check.sh -t time_in_minutes -v(optional)

        where:
                -t <time_in_minutes>    - Time set in minutes which should be equal of less then APPLY LAG on PROD database
                -v                      - Option which only validates state of apply lag

To execute script add mumimum number of minutes for apply lag
between Primary and standby database as parameter.

For example:
./msnap_release_dg_check.sh -t 15
./msnap_release_dg_check.sh -v -t 15

EOF

}

while getopts 't:vh' opt
do
  case ${opt} in
    t) dg_ent_time="$OPTARG" ;;
    v) validate_snap="Y" ;;
    h) Usage && exit 0 ;;
    \?) Usage && exit 1 ;;
  esac
done

MAIL_DG () {
if cat ${pre_msnap_log}  | grep -q "PREREQUISITES ERROR"; then
 echo "Prerequisites for snapshot source ${host_standby} to ${target} FAILED. Please check logs ${pre_msnap_log}" | mail -s "Prerequisites for snapshot source ${host_standby} to ${target} FAILED" -a ${pre_msnap_log} $RECPT
 echo "Prerequisites for snapshot source ${host_standby} to ${target} FAILED. Please check logs and continue manually ${pre_msnap_log}."
else
 echo "Prerequisites for snapshot source ${host_standby} to ${target} OK. Logs ${pre_msnap_log}" | mail -s "Prerequisites for snapshot source ${host_standby} to ${target} OK" -a ${pre_msnap_log} $RECPT
 echo "Prerequisites for snapshot source ${host_standby} to ${target} OK."
fi
}

CHECK_ENTRY (){

valtim='^[0-9]+$'
if ! [[ $dg_ent_time =~ $valtim ]] ; then
   echo "`date "+%Y%m%d %H:%M:%S"` PREREQUISITES ERROR: Not a Integer number." >> ${pre_msnap_log}
   echo "Restart snapshot with parameters for DG in minutes as so ./msnap_release_dg_check.sh *Number for minimum apply lag on DG*" >> ${pre_msnap_log}
   echo "For example ./msnap_release_dg_check.sh -t 15" >> ${pre_msnap_log}
   echo "For example ./msnap_release_dg_check.sh -t 15 -v" >> ${pre_msnap_log}
   MAIL_DG
   exit 1
fi
}

CHECK_TIME (){
pass=`/oracle/$ORACLE_SID/dba/bin/orapass sys \$ORACLE_SID`

lag_time=`echo -e "set heading off feedback off pagesize 0\n select trim(ceil((60*24*60*extract(day from cast(value as interval day(2) to second(0))) + 60*60*extract(hour from cast(value as interval day(2) to second(0))) + 60*extract(minute from cast(value as interval day(2) to second(0))) + TO_NUMBER(((sysdate-to_date(datum_time,'MM/DD/YYYY HH24:MI:SS'))*24*60*60)))/60)) from v\\$dataguard_stats where name='apply lag';" | sqlplus -s "sys/$pass@\$host_standby as sysdba"`
echo $lag_time
}

CHECK_DG (){
if [ $dg_lag_time -lt $dg_ent_time ]
then
        echo "`date "+%Y%m%d %H:%M:%S"` PREREQUISITES OK" >> ${pre_msnap_log}
        echo "Current apply lag $dg_lag_time minutes, specified treshold is $dg_ent_time minutes." >> ${pre_msnap_log}

else
        echo "`date "+%Y%m%d %H:%M:%S"` PREREQUISITES ERROR: DATAGUARD on standby above the treshold" >> ${pre_msnap_log}
        echo "Current apply lag $dg_lag_time minutes, specified treshold is $dg_ent_time minutes." >> ${pre_msnap_log}
        MAIL_DG
        exit 1
fi
}

MAKE_SNAP () {
echo "Starting with snapshot $DATA!"
}

# main

dg_lag_time=`CHECK_TIME`

if [ $validate_snap == N ]
then
        CHECK_ENTRY
        CHECK_DG
        MAIL_DG
        MAKE_SNAP

elif [ $validate_snap == Y ]
then
        CHECK_ENTRY
        CHECK_DG
        MAIL_DG

else
        echo "Other Error!"

fi

exit 0
