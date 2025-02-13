#!/bin/bash

##############################################################

echo "This is script which prints basic information about system and database"
echo "To print help menu ./healt_check.sh -h"
echo

##############################################################


cpu_treshold=20
io_treshold=
ram_treshold=20
fra_treshold=30

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color


cpu_usage=`top -n 1 | awk 'FNR == 3 {print $8}'`
io_usage=
ram_total=`free -h | awk 'FNR == 2 {print $2}' |  tr -d -c 0-9`
ram_sign=`free -h | awk 'FNR == 2 {print $7}' | tr -d '0123456789'`
ram_free=`free -h | awk 'FNR == 2 {print $7}' |  tr -d -c 0-9`
ram_usage="$(echo "$ram_free * 100 / $ram_total" | bc)"

fra_usage=`sqlplus  -L -s / as sysdba << EOF
set pagesize 0
set verify off
set head off
set feedback off
set linesize 400
select CONCAT(round(sum(PERCENT_SPACE_USED),2)-round(sum(PERCENT_SPACE_RECLAIMABLE),2),' ') from  v\\$RECOVERY_AREA_USAGE;
exit;
EOF
`

fra_total=`sqlplus  -L -s / as sysdba << EOF
set pagesize 0
set verify off
set head off
set feedback off
set linesize 400
select trim(SPACE_LIMIT/1024/1024/1024) FROM V\\$RECOVERY_FILE_DEST;
exit;
EOF
`
fra_used=`sqlplus  -L -s / as sysdba << EOF
set pagesize 0
set verify off
set head off
set feedback off
set linesize 400
select trim(SPACE_USED/1024/1024/1024) FROM V\\$RECOVERY_FILE_DEST;
exit;
EOF
`

fra_usage="${fra_usage//[$'\t\r\n ']}"
fra_usage="$(echo 100 - $fra_usage | bc)"

warning_msg(){

echo -e "${RED}$1${NC}"

}

ok_msg(){

echo -e "${GREEN}$1${NC}"

}

banner_msg(){

echo -e "${YELLOW}$1${NC}"

}


#warning_msg "$test1"
#ok_msg "$test1"

#CPU_USAGE

print_tresholds(){

banner_msg "CPU TRESHOLD $cpu_treshold"
banner_msg "RAM TRESHOLD $ram_treshold"
banner_msg "FRA TRESHOLD $fra_treshold"
echo
}

print_cpu(){
echo "********************************************************"
echo "CPU"
echo "********************************************************"
if [[ `echo "$cpu_usage $cpu_treshold" | awk '{print ($1 >= $2)}'` == 1 ]] ; then
                #banner_msg "CPU TRESHOLD $cpu_treshold"
                ok_msg "CPU IDLE                $cpu_usage%"
        else
                warning_msg "CPU IDLE            $cpu_usag%"
fi

echo
}


print_ram(){
echo "********************************************************"
echo "RAM"
echo "********************************************************"
if [[ `echo "$ram_usage $ram_treshold" | awk '{print ($1 >= $2)}'` == 1 ]] ; then
                #banner_msg "RAM TRESHOLD $ram_treshold"
                ok_msg "RAM FREE                $ram_usage%"
                ok_msg "TOTAL RAM AVAIABLE:     $ram_total $ram_sign"
                ok_msg "FREE RAM SPACE:         $ram_free $ram_sign"
        else
                warning_msg "RAM FREE                   $ram_usage%"
                warning_msg "TOTAL RAM AVAIABLE:        $ram_total $ram_sign"
                warning_msg "FREE RAM SPACE:            $ram_free $ram_sign"

fi

echo
}

#FRA USAGE
print_fra(){
echo "********************************************************"
echo "FRA SPACE"
echo "********************************************************"
if [[ `echo "$fra_usage $fra_treshold" | awk '{print ($1 >= $2)}'` == 1 ]] ; then
                #banner_msg "FRA TRESHOLD $fra_treshold"
                ok_msg "FRA FREE                $fra_usage%"
                ok_msg "TOTAL FRA SPACE         $fra_total G"
                ok_msg "BUSY FRA SPACE          $fra_used G"
        else
                warning_msg "FRA FREE            $fra_usage%"
                warning_msg "TOTAL FRA SPACE     $fra_total G"
                warning_msg "BUSY FRA SPACE      $fra_used G"
fi

echo
}

main_database(){
print_fra
}

main_system(){
print_cpu
print_ram
}

main(){
main_database
main_system
}

print_help() {

cat << EOF
#######################################################
# If you want to print all options script has to be executed without parameters, if you wish to limit results you can do it by:
#######################################################
USAGE: ./blackout_backup.sh -F <space_left_on_FRA_DB>
        where:
                -d                            - Option which prints results only related to database
                -s                            - Option which prints results only related to system
                -t                            - Prints tresholds which were set for script
                -h                            - Help screen

For example:
./health_check.sh
./health_check.sh -d
./health_check.sh -st

EOF
}

###############################################################################
# Read command line arguments
###############################################################################
while getopts 'htds' opt
do
  case ${opt} in
    t) print_tresholds ;;
    d) main_database ;;
    s) main_system  ;;
    "") main ;;
    h) print_help && exit 0 ;;
    \?) echo  "Invalid parameter" && exit 1 ;;
  esac
done


exit 0
         
