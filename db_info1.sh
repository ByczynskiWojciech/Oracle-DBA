#!/bin/bash
ORACLE_SID=$1
export ORACLE_SID
export PATH=$PATH:$ORACLE_HOME/bin
declare -a RESULTS

DPSPICHECK=`sqlplus  -L -s / as sysdba << EOF
set pagesize 0
set verify off
set head off
set feedback off
select 'CONNECTED' from dual;
exit;
EOF
`

INSTANCE_STATUS=`sqlplus -L -s / as sysdba <<EOF
set pagesize 0
set verify off
set head off
set feedback off
SELECT status FROM v\\$instance;
exit;
EOF
`

db_check(){

RESULTS=`sqlplus  -L -s / as sysdba << EOF
set pagesize 0
set verify off
set head off
set feedback off
set linesize 400
select version from v\\$instance;
select REPLACE(LOG_MODE, ' ','_') from v\\$database;
select REPLACE(OPEN_MODE, ' ','_') from v\\$database;
select REPLACE(DATABASE_ROLE, ' ','_') from v\\$database;
select REPLACE(FLASHBACK_ON, ' ','_') from v\\$database;
select REPLACE(FORCE_LOGGING, ' ','_') from v\\$database;
select CONCAT(round(sum(PERCENT_SPACE_USED),2)-round(sum(PERCENT_SPACE_RECLAIMABLE),2),' ') from  v\\$RECOVERY_AREA_USAGE;
select VALUE/1024/1024/1024||'G'  from v\\$PARAMETER where NAME='db_recovery_file_dest_size';
SELECT REPLACE(CONCAT(CONCAT(VALUE,'/alert_'),CONCAT(INSTANCE_NAME,'.log')), ' ','') A FROM V\\$DIAG_INFO, V\\$INSTANCE where NAME='Diag Trace';
select VALUE from   v\\$parameter where name = 'dg_broker_start';
select VALUE NLS_CHARACTERSET from nls_database_parameters where parameter='NLS_CHARACTERSET';
select TRIM(k.base#.session_level) from dual;
exit;
EOF
`
DBVERSION=`echo ${RESULTS[0]} | cut -d' ' -f1`
DBLOGMODE=`echo ${RESULTS[0]} | cut -d' ' -f2`
DBOPENMODE=`echo ${RESULTS[0]} | cut -d' ' -f3`
DBROLE=`echo ${RESULTS[0]} | cut -d' ' -f4`
DBFLASHBACK=`echo ${RESULTS[0]} | cut -d' ' -f5`
DBFORCELOGIN=`echo ${RESULTS[0]} | cut -d' ' -f6`
DBFRAPERCENTUSAGE=`echo ${RESULTS[0]} | cut -d' ' -f7`
DBFRASIZE=`echo ${RESULTS[0]} | cut -d' ' -f8`
ALERTLOG=`echo ${RESULTS[0]} | cut -d' ' -f9`
BROKER=`echo ${RESULTS[0]} | cut -d' ' -f10`
DBNLS=`echo ${RESULTS[0]} | cut -d' ' -f11`
SL_LVL=`echo ${RESULTS[0]} | cut -d' ' -f12`

#echo $DBVERSION
#echo $DBLOGMODE
#echo $DBOPENMODE
#echo $DBROLE
#echo $DBFLASHBACK
#echo $DBFORCELOGIN
#echo $DBNLS
#echo $DBFRAPERCENTUSAGE
#echo $DBFRASIZE
#echo $ALERTLOG
#echo $BROKER
#echo $SL_LVL


if [ "$DBOPENMODE" = "MOUNTED" ] ;
        then
                DBNLS=""
fi

if [ "$DBOPENMODE" = "MOUNTED" ] ;
        then
                SL_LVL=""
fi

LISTENER=`
if tnsping $ORACLE_SID > /dev/null; then
  echo RUNNING
else
  echo NOT RUNNING
fi
`

if [ "$BROKER" = "TRUE" ]
        then
                DG_BROKER_START='TRUE'
                DG=`echo -e "show configuration"|${ORACLE_HOME}/bin/dgmgrl / | grep -A 1 "Configuration Status" | grep -v "Configuration Status"| awk '{ print $1}'`
                if [ "$DG" = "SUCCESS" ] ;
                        then
                                DATAGUARD="SUCCESS"
                        else
                                RED='\033[0;31m'
                                NC='\033[0m' # No Color
                                DATAGUARD=${RED}${DG}${NC}
                fi
        else
                DG_BROKER_START='FALSE'
                DATAGUARD='NOT CONFIGURED'
fi

BLACKOUT=`/oracle/${ORACLE_SID}/agent/agent_inst/bin/emctl status blackout | head -3 | tail -1`
BLACKOUT_NAME=`echo $BLACKOUT | cut -d " " -f 3`

msnap_disable="/oracle/$ORACLE_SID/dba/$ORACLE_SID/msnap/msnap_disable.txt"
disable_until=
disable_since=
CURR_DATE=$(date +%Y%m%d)
if [ -f "$msnap_disable" ]; then
    disable_until=`grep -rnw "$msnap_disable" -e 'DISABLE_UNTIL'`
    disable_until=`echo $disable_until | cut -f2 -d"=" | tr -d "-"`
    disable_since=`grep -rnw "$msnap_disable" -e 'DISABLE_SINCE'`
    disable_since=`echo $disable_since | cut -f2 -d"=" | tr -d "-"`
fi

}

db_check_nomount(){

RESULTS=`sqlplus  -L -s / as sysdba << EOF
set pagesize 0
set verify off
set head off
set feedback off
set linesize 400
select version from v\\$instance;
select VALUE/1024/1024/1024||'G'  from v\\$PARAMETER where NAME='db_recovery_file_dest_size';
SELECT REPLACE(CONCAT(CONCAT(VALUE,'/alert_'),CONCAT(INSTANCE_NAME,'.log')), ' ','') A FROM V\\$DIAG_INFO, V\\$INSTANCE where NAME='Diag Trace';
exit;
EOF
`
DBVERSION=`echo ${RESULTS[0]} | cut -d' ' -f1`
DBFRASIZE=`echo ${RESULTS[0]} | cut -d' ' -f2`
ALERTLOG=`echo ${RESULTS[0]} | cut -d' ' -f3`

#echo $DBVERSION
#echo $DBLOGMODE
#echo $DBOPENMODE
#echo $DBROLE
#echo $DBFLASHBACK
#echo $DBFORCELOGIN
#echo $DBNLS
#echo $DBFRAPERCENTUSAGE
#echo $DBFRASIZE
#echo $ALERTLOG
#echo $BROKER
#echo $SL_LVL


DBNLS=""
DBLOGMODE=""
DBOPENMODE="NOMOUNT"
DBROLE=""
DBFLASHBACK=""
DBFORCELOGIN=""
DBFRAPERCENTUSAGE=""
SL_LVL=""
BROKER=""


LISTENER=`
if tnsping $ORACLE_SID > /dev/null; then
  echo RUNNING
else
  echo NOT RUNNING
fi
`

if [ "$BROKER" = "TRUE" ]
        then
                DG_BROKER_START='TRUE'
                DG=`echo -e "show configuration"|${ORACLE_HOME}/bin/dgmgrl / | grep -A 1 "Configuration Status" | grep -v "Configuration Status"| awk '{ print $1}'`
                if [ "$DG" = "SUCCESS" ] ;
                        then
                                DATAGUARD="SUCCESS"
                        else
                                RED='\033[0;31m'
                                NC='\033[0m' # No Color
                                DATAGUARD=${RED}${DG}${NC}
                fi
        else
                DG_BROKER_START='FALSE'
                DATAGUARD='NOT CONFIGURED'
fi

BLACKOUT=`/oracle/${ORACLE_SID}/agent/agent_inst/bin/emctl status blackout | head -3 | tail -1`
BLACKOUT_NAME=`echo $BLACKOUT | cut -d " " -f 3`

msnap_disable="/oracle/$ORACLE_SID/dba/$ORACLE_SID/msnap/msnap_disable.txt"
disable_until=
disable_since=
CURR_DATE=$(date +%Y%m%d)
if [ -f "$msnap_disable" ]; then
    disable_until=`grep -rnw "$msnap_disable" -e 'DISABLE_UNTIL'`
    disable_until=`echo $disable_until | cut -f2 -d"=" | tr -d "-"`
    disable_since=`grep -rnw "$msnap_disable" -e 'DISABLE_SINCE'`
    disable_since=`echo $disable_since | cut -f2 -d"=" | tr -d "-"`
fi

}

print_var(){
printf "+----------------------------------------------------\n"
printf "|ORACLE_SID         = $ORACLE_SID        \n"
printf "|OPEN_MODE          = $DBOPENMODE        \n"
printf "|LOG_MODE           = $DBLOGMODE         \n"
printf "|DATABASE_ROLE      = $DBROLE            \n"
printf "|FLASHBACK_ON       = $DBFLASHBACK       \n"
printf "|FORCE_LOGGING      = $DBFORCELOGIN      \n"
printf "|NLS_LANG           = $DBNLS             \n"
printf "|FRA PERCENT USAGE  = $DBFRAPERCENTUSAGE \n"
printf "|FRA SIZE           = $DBFRASIZE         \n"
printf "|DG_BROKER_START    = $DG_BROKER_START   \n"
printf "|DATAGUARD          = $DATAGUARD         \n"
printf "|ORACLE_HOME        = $ORACLE_HOME       \n"
printf "|VERSION            = $DBVERSION         \n"
printf "|LISTENER           = $LISTENER          \n"
printf "|ALERT LOG          = $ALERTLOG          \n"
if [ "$BLACKOUT" = "No Blackout registered." ]
        then
printf "|BLACKOUT           = No Blackout registered.     \n"
        :
        else
printf "|BLACKOUT           = $BLACKOUT_NAME     \n"
fi
if [[ "$ORACLE_SID" == *"ACP"* ]]
        then
printf "|SESION LEVEL       = $SL_LVL            \n"
        else
printf "|SESION LEVEL       = Non ACP database.            \n"
fi
if [ -f "$msnap_disable" ]; then

unt_date="$unt_date`echo $disable_until | cut -b 1,2,3,4 `"
unt_date="$unt_date-"
unt_date="$unt_date`echo $disable_until | cut -b 5,6 `"
unt_date="$unt_date-"
unt_date="$unt_date`echo $disable_until | cut -b 7,8 `"
sin_date="$sin_date`echo $disable_since | cut -b 1,2,3,4 `"
sin_date="$sin_date-"
sin_date="$sin_date`echo $disable_since | cut -b 5,6 `"
sin_date="$sin_date-"
sin_date="$sin_date`echo $disable_since | cut -b 7,8 `"

        if [[ "$disable_since" -ge "$CURR_DATE" ]]; then
                if [[ "$disable_until" -ge "$CURR_DATE" ]]; then
                printf "|AUTOCLONE          = Clone is disabled since $sin_date until $unt_date         \n"
                else
                printf "|AUTOCLONE          = Allowed            \n"
                fi

        else

                if [[ "$disable_until" -ge "$CURR_DATE" ]]; then
                printf "|AUTOCLONE          = Clone is disabled until $unt_date         \n"
                else
                printf "|AUTOCLONE          = Allowed            \n"
                fi
        fi
fi

printf "+----------------------------------------------------\n"
}

#Main logic
if [ "$DPSPICHECK" = "CONNECTED" ]
then
if [ "$INSTANCE_STATUS" == "STARTED" ]; then
        db_check_nomount
        print_var
else

        db_check
        print_var

fi

else
        printf "${RED}Cannot connect to $ORACLE_SID ... ${NC} \n"
fi



