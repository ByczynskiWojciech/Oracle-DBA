#!/bin/bash

ORACLE_SID=PRDREST
file_dir=$1
RECPT=apobank-polanddbasupport@dxc.com
DATA=`date "+%Y%m%d_%H.%M%S"`
declare -a disk_id_wwn
declare -a mapper_nr
asm_data_nr=0
mkdir -p /oracle/${ORACLE_SID}/dba/logs
mkdir -p /oracle/${ORACLE_SID}/dba/${ORACLE_SID}
add_asm_log_file=/oracle/${ORACLE_SID}/dba/logs/add_asm_disks_${DATA}.log


     ORACLE_SID=+ASM
     ORAENV_ASK=NO
     . oraenv

cd $ORACLE_HOME

disk_status(){

# To be corrected
temp_i=0
for i in "${disk_id_wwn[@]}"; do
        echo "" >> ${add_asm_log_file}
        echo "FC ID (WWN): ${disk_id_wwn[$temp_i]}" >> ${add_asm_log_file}
        echo $i >> ${add_asm_log_file}

        device_name=`multipath -ll $i | head -n1 | awk '{print $1;}'`
        echo "Device name: $device_name" >> ${add_asm_log_file}

        temp=`fdisk -l /dev/mapper/$device_name | tail -1 | cut -b -3 | tr -d " "`
        temp1=

        if [ $temp == "1" ]
                then
                echo "!!!NOT OK!!! Partition already created on this $temp device." >> ${add_asm_log_file}
                echo "" >> ${add_asm_log_file}
                exit 1
        elif [ $temp == "#" ]
                then
                echo "!!! OK !!! Partition can be created." >> ${add_asm_log_file}
                echo "" >> ${add_asm_log_file}
                else
                echo "ERROR: Not supported exception" >> ${add_asm_log_file}
                echo "" >> ${add_asm_log_file}
                exit 1
        fi

        temp1=`oracleasm querydisk /dev/mapper/$device_name | cut -d " " -f 3-10`

        if [ "$temp1" == "is marked an ASM disk with the label" ]
                then
                echo "!!!NOT OK!!! ASM DISK already created on this $temp1 device." >> ${add_asm_log_file}
                exit 1
        elif [ "$temp1" == "is not marked as an ASM disk" ]
                then
                echo "!!! OK !!! ASM DISK can be created." >> ${add_asm_log_file}
        else
                echo "ERROR: Not supported exception" >> ${add_asm_log_file}
                exit 1
fi

temp_i=$((temp_i+1))
done

}

#header_status(){

#temp=`su - grid -c "$ORACLE_HOME/bin/sqlplus -s -l / as sysasm <<EOF
#set pagesize 0 verify off head off feedback off lines 300
#SELECT HEADER_STATUS FROM V$ASM_DISK;
#EOF"
#`


#       if [ "$temp" == "CANDIDATE" ]
#               then
#               echo "!!! OK !!! ASM DISK can be created." >> ${add_asm_log_file}
#       elif [ "$temp" == "PROVISIONED" ]
#               then
#               echo "!!! OK !!! ASM DISK can be created." >> ${add_asm_log_file}
#       else
#               echo "ERROR: Wrong header status, check logs for details." >> ${add_asm_log_file}
#               exit 1



#}

create_partitions(){

partprobe

for i in "${disk_id_wwn[@]}"; do
          echo "" >> ${add_asm_log_file}
          temp_i=0
          temp="1"
          temp1=

          echo "FC ID (WWN): ${disk_id_wwn[$temp_i]}" >> ${add_asm_log_file}
          echo "" >> ${add_asm_log_file}
          echo $i >> ${add_asm_log_file}

          device_name=`multipath -ll $i | head -n1 | awk '{print $1;}'`
          part_nr=`ls -ll /dev/mapper/$device_name | awk '{print $11}' | cut -d "-" -f2`
          echo "Device name: $device_name" >> ${add_asm_log_file}
          echo "" >> ${add_asm_log_file}
          echo "Device nr: $part_nr" >> ${add_asm_log_file}
          echo "" >> ${add_asm_log_file}

          #CREATING PARTITION
          parted -s -a optimal /dev/dm-$part_nr mklabel gpt mkpart primary 0% 100%

          temp="$device_name$temp"
          echo "Partition device name: $temp" >> ${add_asm_log_file}
          echo "" >> ${add_asm_log_file}

          temp1=`ls -ll /dev/mapper/$temp | awk '{print $11}' | cut -d "-" -f2`
          echo "Partition device nr: $temp1" >> ${add_asm_log_file}

          mapper_nr[${#mapper_nr[@]}]=$temp1
          echo "" >> ${add_asm_log_file}
          temp_i=$((temp_i+1))
done
}

check_if_afd(){

#check_afd="CONFIGURED"

check_afd=`su - grid -c "$ORACLE_HOME/bin/sqlplus -s -l / as sysasm <<EOF
set pagesize 0 verify off head off feedback off lines 300
SELECT SYS_CONTEXT('SYS_ASMFD_PROPERTIES', 'AFD_STATE') FROM DUAL;
EOF"
`

        echo "Czy to AFD: $check_afd" >> ${add_asm_log_file}
        echo ""

        if [ "$check_afd" = "CONFIGURED" ];
        then
          return 0
        else
          return 1
        fi

}

get_afd_disk_name(){

asm_data_nr=`asmcmd afd_lsdsk | grep AFD_DATA | tail -1 | awk '{print $1}' | cut -c 9-`
echo "ASM DATA NR $asm_data_nr"
echo ""
}


get_asm_disk_name(){

asm_data_nr=`oracleasm listdisks | grep ASM_DATA | cut -c 9- | sort -n | tail -1`
echo "ASM DATA NR $asm_data_nr"
echo ""
}


create_afd_asm_disk(){

#adding asm disks
for i in "${mapper_nr[@]}"; do
          get_afd_disk_name

          next_disk_nr=$asm_data_nr
          next_disk_nr="$(($next_disk_nr+1))"

          echo "CREATING AFD DISK" >> ${add_asm_log_file}
          echo "" >> ${add_asm_log_file}
          echo "afd_label AFD_DATA$next_disk_nr /dev/dm-$i" | asmcmd
          echo "CREATED AFD DISK AFD_DATA$next_disk_nr /dev/dm-$i" >> ${add_asm_log_file}
          echo "" >> ${add_asm_log_file}

          #ADDING DISKS TO DISKGROUP
su - grid -c "$ORACLE_HOME/bin/sqlplus -s -l / as sysasm <<EOF
set echo on feedback on
ALTER DISKGROUP DATA ADD DISK 'AFD:AFD_DATA$next_disk_nr' REBALANCE WITHOUT COMPACT POWER 5;
EOF"


#         su - grid -c "echo \"set echo on set feedback on ALTER DISKGROUP DATA ADD DISK 'AFD:AFD_DATA$next_disk_nr' REBALANCE WITHOUT COMPACT POWER 5;\" | $ORACLE_HOME/bin/sqlplus / as sysasm "
done
}

create_asmlib_disk(){

#adding asm disks
for i in "${mapper_nr[@]}"; do
        get_asm_disk_name

        next_disk_nr=$asm_data_nr
        next_disk_nr="$(($next_disk_nr+1))"

        echo "createdisk ASM_DATA$next_disk_nr /dev/dm-$i" | oracleasm
        echo "CREATED ASM DISK ASM_DATA$next_disk_nr /dev/dm-$i" >> ${add_asm_log_file}

        #adding disks to diskgroup
su - grid -c "$ORACLE_HOME/bin/sqlplus -s -l / as sysasm <<EOF
set echo on feedback on
ALTER DISKGROUP DATA ADD DISK 'ASM:ASM_DATA$next_disk_nr' REBALANCE WITHOUT COMPACT POWER 5;
EOF"

#       su - grid -c "echo \"set echo on set feedback on ALTER DISKGROUP DATA ADD DISK 'ASM:ASM_DATA$next_disk_nr' REBALANCE WITHOUT COMPACT POWER 5;\" | $ORACLE_HOME/bin/sqlplus / as sysasm "
done
}

mail_AASM() {

cat ${add_asm_log_file} | mail -s "Result of ADD ASM script executed on $ORACLE_SID." $RECPT
}

main() {

echo "Source file: $file_dir" >> ${add_asm_log_file}
echo "" >> ${add_asm_log_file}

readarray -t disk_id_wwn < $file_dir


echo "Disks to be added:" >> ${add_asm_log_file}
echo "" >> ${add_asm_log_file}

for value in "${disk_id_wwn[@]}"; do
        disk_status "$value"
done

        echo "Creating PARTITIONS" >> ${add_asm_log_file}
        echo "" >> ${add_asm_log_file}
        create_partitions

check_if_afd

if [[ $? -eq 0 ]]; then
        echo "Oracle ASM Filter Driver TRUE" >> ${add_asm_log_file}
        echo "" >> ${add_asm_log_file}
        create_afd_asm_disk

        else

        echo "Oracle ASM Filter Driver FALSE" >> ${add_asm_log_file}
        echo "" >> ${add_asm_log_file}
        create_asmlib_disk
fi
}

main
mail_AASM

