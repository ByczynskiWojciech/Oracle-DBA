#!/bin/bash

#####################################################################

#To execute script add mumimum number of FRA USAGE
#!!!!!!THIS SCRIPT IS NOT MEANT TO BE USED ON DG CONFIGURATION OR PROD SERVERS!!!!!!
#
#./blackout_backup.sh *Miminum of FRA space left*
#
#For example:
#./blackout_backup.sh -F 15
#./blackout_backup.sh -F 15 -D -T 24
#./blackout_backup.sh -h

#####################################################################

PATH=$PATH:/bin:/usr/local/bin; export PATH
RECPT=apobank-polanddbasupport@dxc.com

DATA=`date "+%Y%m%d_%H%M%S"`
mkdir -p /oracle/$ORACLE_SID/dba/logs/blackout_logs
blackout_backup_log=/oracle/$ORACLE_SID/dba/logs/blackout_logs/blackout_backup_log_${DATA}.log
FRA_USAGE=
AGENT_HOME=/oracle/$ORACLE_SID/agent/agent_inst
blackout_name=`$AGENT_HOME/bin/emctl status blackout | head -n 3 | tail -n 1 | awk '{print $3}'`
listener_status=`lsnrctl status`
DELETE_CHECK="N"


     ORAENV_ASK=NO
     . oraenv


###############################################################################
# Help screen
###############################################################################

Usage() {

cat << EOF
#!!!!!!THIS SCRIPT IS NOT MEANT TO BE USED ON DG CONFIGURATION OR PROD SERVERS!!!!!!
#######################################################
# Script for backup during blackout and listener is down
#######################################################
USAGE: ./blackout_backup.sh -F <space_left_on_FRA_DB>
        where:
                -F <space_left_on_FRA_DB>     - Space expressed in percentage which represents minimum value of space that script won't make any actions
                -D                            - !!! Do not use this option!!! Option which doesn't backup archive logs, only deletes those older than 1 day
                -T                            - !!! Do not use this option!!! Times in hours which you would like to archive logs to be deleted(required with -D option)
                -h                            - Help screen

For example:
./blackout_backup.sh -F 15
./blackout_backup.sh -F 15 -D -T 24
./blackout_backup.sh -h

EOF
}

###############################################################################
# Read command line arguments
###############################################################################
while getopts 'F:DhT:' opt
do
  case ${opt} in
    F) FRA_USAGE="$OPTARG" ;;
    D) DELETE_CHECK="Y" ;;
    T) DEL_H="$OPTARG" ;;
    h) Usage && exit 0 ;;
    \?) echo  "Invalid parameter" && exit 1 ;;
  esac
done

delete_archive(){
SQLPLUS_OUTPUT=$(rman target / <<ENDOFSQL
DELETE ARCHIVELOG ALL COMPLETED BEFORE "sysdate-$DEL_H/24";
exit;
ENDOFSQL
)

echo "Deleting archivelog files above $DEL_H hours." >> ${blackout_backup_log}
echo "" >> ${blackout_backup_log}
}

mail_bb() {

cat ${blackout_backup_log} | mail -s "Result of blackout backup script executed on $ORACLE_SID." $RECPT

}

check_blackout() {

blackout_status=`$AGENT_HOME/bin/emctl status blackout | head -n 3 | tail -n 1`
if [ "$blackout_status" == "No Blackout registered." ];then
    echo "No Blackout registered." >> ${blackout_backup_log}
    echo ""
    echo "Backup can be started manualy." >> ${blackout_backup_log}
    echo ""
    mail_bb
    exit 1;
fi

}

check_listener() {

if [[ "$listener_status" =~ .*"No listener".* ]]; then
    echo "Listener isn't started." >> ${blackout_backup_log}
    echo "" >> ${blackout_backup_log}
    mail_bb
    exit 1;
fi

}

do_backup() {

echo "Deleting blackout $blackout_name" >> ${blackout_backup_log}
echo "" >> ${blackout_backup_log}
$AGENT_HOME/bin/emctl stop blackout $blackout_name >> ${blackout_backup_log}
echo "" >> ${blackout_backup_log}
echo "Starting backup for $ORACLE_SID" >> ${blackout_backup_log}
echo "" >> ${blackout_backup_log}
/oracle/$ORACLE_SID/dba/bin/archivelog_backup_nodg.sh $ORACLE_SID >> ${blackout_backup_log}
echo "" >> ${blackout_backup_log}
echo "Creating blackout $blackout_name" >> ${blackout_backup_log}
echo "" >> ${blackout_backup_log}
$AGENT_HOME/bin/emctl start blackout $blackout_name >> ${blackout_backup_log}
echo "" >> ${blackout_backup_log}
}

check_fra() {

empty_fra=`sqlplus -L -s / as sysdba <<EOF
set heading off
set feedback off
set head off
set verify off
set pagesize 0
SELECT trim(100-CEIL(SUM(PERCENT_SPACE_USED))) from V\\$RECOVERY_AREA_USAGE;
exit
EOF
`

#echo $empty_fra
if [[ "$empty_fra" -le "$FRA_USAGE" ]]; then
    if [[ "$DELETE_CHECK" == "N" ]]; then
        do_backup
    elif [[ "$DELETE_CHECK" == "Y" ]]; then
        delete_archive
    else
        echo "Invalid flag!" >> ${blackout_backup_log}
        fi
else
    echo "Current free space of FRA USAGE ($empty_fra) is above treshold $FRA_USAGE ." >> ${blackout_backup_log}
    echo "" >> ${blackout_backup_log}
fi

}



check_blackout
check_listener
check_fra
mail_bb

exit 0
