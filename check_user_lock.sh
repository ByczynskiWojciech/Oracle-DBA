#!/bin/bash

####################################
# To execute this sript you need to pass location to file containing in new lines USER seperated by "," than PASSWORD
# or user it for single user by passing two variables $1 username and $2 password
#
#File example:
#USER1,PASSWORD1
#USER2,PASSWORD2
#USER3,PASSWORD3
#
# Execution example ./check_user_lock.sh /oracle/WBDEV01/wojtek/users_list.txt
# or ./check_user_lock.sh user1 password1
####################################

if [ -z "$1" ]
then

        echo "ERROR: \$1 file variable is empty"
        echo "Execute scrip againt with valid file variable!"
        exit 1
#else
#       echo "$1 is NOT empty"
fi

if [ -z "$2" ]
then
        user_txt_loc=$1
        lines_number=`cat $user_txt_loc | wc -l`
        userna=
        passw=
else
userna=$1
passw=$2
fi

echo $user_txt_loc
#echo $lines_number


check_locked () {
temp_z=$(sqlplus  -L -s / as sysdba << EOF
set pagesize 0
set verify off
set head off
set lines 300
SELECT ACCOUNT_STATUS FROM DBA_USERS WHERE USERNAME = '${userna}';
#exit;
exit
EOF
)
        echo "User $userna is $temp_z."

}

check_password () {
temp_z=$(sqlplus -S ${userna}/${passw} << EOF
exit
EOF
)
        #echo $userna
        #echo $passw
        echo $temp_z
        if [[ $temp_z =~ "account is locked" ]]
        then
        echo "Password to be checked after user unlock."
        elif [[ $temp_z =~ "invalid username/password" ]]
        then
        echo "Password is not correct."
        else
        echo "Password is correct."
        fi
}


check_exist () {
temp_z=$(sqlplus  -L -s / as sysdba << EOF
set pagesize 0
set verify off
set head off
set lines 300
SELECT USERNAME FROM DBA_USERS WHERE USERNAME = '${userna}';
#exit;
exit
EOF
)
        #echo $temp_z
        if [[ $temp_z =~ "no rows selected" ]];
        then
        echo "User $userna does not exists."
        echo ""
        else
        echo "User $userna exists."
        check_locked

        if [ -z "$passw" ]
        then
        echo "Password is empty"
        else
        check_password
        fi
        echo ""
        fi

}

if [ -z "$2" ]
then

        for (( i=1; i<=$lines_number; i++))
        do
                #echo "i= $i"
                userna=$(awk -v i=$i -F, '{if(NR==i) print $1}' $user_txt_loc)
                #temp_z=$(awk -v i=$i -F, '{if(NR==i) print $1}' $user_txt_loc)
                #temp_z=$(awk -F, '{if(NR==$i) print $1}' $user_txt_loc)
                #echo $temp_z
                #temp_z=$(awk -v i=$i -F, '{if(NR==i) print $2}' $user_txt_loc)
                #temp_z= cat $user_txt_loc | awk -F, '{print $2}'
                #echo $temp_z
                #echo $userna
                passw=$(awk -v i=$i -F, '{if(NR==i) print $2}' $user_txt_loc)
                #echo $passw
                check_exist

        done

else
        check_exist
fi
