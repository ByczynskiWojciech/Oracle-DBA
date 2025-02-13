#!/bin/bash

RECPT=

SCRIPT_SOURCE=$1
OUT_FILE=/oracle/$ORACLE_SID/dba/sql/tmp/out1.csv


#echo $user_name
$ORACLE_HOME/bin/sqlplus -s "/ as sysdba" << EOF
whenever sqlerror exit 2
set trimspool on
set feedback off linesize 10000
set termout off
set echo off
set pagesize 0
set verify off

set markup csv on
spool $OUT_FILE

@$SCRIPT_SOURCE

spool off
set markup csv off
exit;
EOF

  echo -e "Dear all, \n \nResult of script attached: $last_reort \n \nMessage was generated automatically(please do not respond to it), in case of any problems contact : "ApoBank-PolandDBASupport@dxc.com" \n \nRegards DBA Team" | \

mail -s "SQL SCRIPT RESULT" -a ${OUT_FILE} -r "DBA Support team <DO_NOT_REPLY@$HOSTNAME.localdomain>"  $RECPT
