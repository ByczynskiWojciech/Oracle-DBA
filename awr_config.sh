#!/bin/bash

#####################################################################
# Script for viewing/changing AWR interval and retention
#####################################################################

     ORAENV_ASK=NO
     . oraenv

Usage() {
cat << EOF
#######################################################
# Script for viewing/changing AWR interval and retention
#######################################################
USAGE: ./blackout_backup.sh
        where:
                -I <interval of snap in minutes>     - Snapshot interval; how often to automatically take snapshots
                -R <retention of snap in days>       - Retention setting for the snapshots; amount of time to keep the snapshots
                -h                                   - Help screen

For example:
./blackout_backup.sh
./blackout_backup.sh -I 15 -R 30
./blackout_backup.sh -h

EOF
}

print_awr() {
sqlplus / as sysdba << EOF
col snap_interval for a20
col retention for a20
select snap_interval, retention from dba_hist_wr_control;
exit;
EOF
}

alt_int_ret() {
AWR_RETENTION=$((AWR_RETENTION * 60 * 24))
#echo "$AWR_INTERVAL"
#echo "$AWR_RETENTION"

echo "execute dbms_workload_repository.modify_snapshot_settings(interval =>$AWR_INTERVAL ,retention => $AWR_RETENTION);" | sqlplus / as sysdba

}


while getopts 'I:hR:' opt
do
  case ${opt} in
    I) AWR_INTERVAL="$OPTARG" ;;
    R) AWR_RETENTION="$OPTARG" ;;
    h) Usage && exit 0 ;;
    \?) echo  "Invalid parameter" && exit 1 ;;
  esac
done

main(){
if [ -z "$AWR_INTERVAL" ] && [ -z  "$AWR_RETENTION" ] ; then
    print_awr
  elif [ -n "$AWR_INTERVAL" ] && [ -n "$AWR_RETENTION" ] ; then
    alt_int_ret
    print_awr
  else
    echo "Variable I or R is empty"
fi
}

main
