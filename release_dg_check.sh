#!/bin/bash

# Script for refreshing storage snapshots
# Prerequisites:
#  * destinatin DB instance is at least started
#  * spfile for ASM is used $ORACLE_HOME/dbs/spfiledbname.ora_for_asm
#  * ASM is UP
#  * LISTENER is UP
#  * source (PRDACP02) is not in a warning state
#
# tdabrowski@dxc.com / jrak@dxc.com

##################################################################

#To execute script add mumimum number of minutes for apply lag
#between Primary and standby database as parameter.
#
#./msnap_release_dg_check.sh *Number for minimum apply lag on DG*
#
#For example:
#./msnap_release_dg_check.sh 15

##################################################################

PATH=$PATH:/bin:/usr/local/bin; export PATH

RECPT=ApoBank-PolandDBASupport@dxc.com

target=DEVDBA02
host_name=`hostname`
DATA=`date "+%Y%m%d_%H%M%S"`
SNAP=/oracle/DEVDBA02/dba/wojtek
mkdir -p ${SNAP}/log
mkdir -p ${SNAP}/tmp
msnap_log=${SNAP}/log/msnap_log_${DATA}.log
msnap_out_log=${SNAP}/log/msnap_out_log_${DATA}.log
nid_out_log=${SNAP}/log/nid_out_log_${DATA}.log
host_standby=DEVDBA02
dg_ent_time=$1


     ORACLE_SID=${target}
     ORAENV_ASK=NO

dg_lag_time=

CHECK_ENTRY (){

valtim='^[0-9]+$'
if ! [[ $dg_ent_time =~ $valtim ]] ; then
   echo "`date "+%Y%m%d %H:%M:%S"` PREREQUISITES ERROR: Not a Integer number, restart snapshot with parameters for DG in minutes as so ./msnap_release_dg_check.sh *Number for minimum apply lag on DG*"
   echo "For example ./msnap_release_dg_check.sh 15"
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
        echo "`date "+%Y%m%d %H:%M:%S"` PREREQUISITES OK" >> ${msnap_log}
        echo "Current apply lag $dg_lag_time minutes, specified treshold is $dg_ent_time" >> ${msnap_log}
        make_snap

else
        echo "`date "+%Y%m%d %H:%M:%S"` PREREQUISITES ERROR: DATAGUARD on standby above the treshold" >> ${msnap_log}
        echo "Current apply lag $dg_lag_time minutes, specified treshold is $dg_ent_time" >> ${msnap_log}
        exit 1
fi
}


make_snap () {
echo "Started snapshot!"
echo "Snapshot done!"
}

# main

dg_lag_time=`CHECK_TIME`

CHECK_ENTRY
CHECK_DG


exit 0
