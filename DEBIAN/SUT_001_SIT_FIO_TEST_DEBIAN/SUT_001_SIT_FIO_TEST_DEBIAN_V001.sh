#!/bin/bash
###############################
#Name:SUT_001_SIT_FIO_TEST_DEBIAN
#Author:yanshuo
#Revision:
#Version:V001
#Date:2017-12-19
#Tracelist:V001-->First Version
#Function: storage test under debian with fio
#Parameter_1: total test seconds
#Parameter_2(optional):system disk
#Usage:bash SUT_001_SIT_FIO_TEST_DEBIAN_V001.sh Parameter_1 Parameter_2(optional)
#Example:bash SUT_001_SIT_FIO_TEST_DEBIAN_V001.sh 3600 || bash SUT_001_SIT_FIO_TEST_DEBIAN_V001.sh 3600 sda4
#Description: to start fio test under DEBIAN
###############################


#check and create log dir
[ ! -d log ] && mkdir log
#create log file
time_start=`date +%Y%m%d%H%M%S`
log_dir_name="${time_start}_SIT_FIO_TEST_DEBIAN"
log_file_name="${time_start}_SIT_FIO_TEST_DEBIAN.log"
current_path=`pwd`
log_path_dir="${current_path}/log/${log_dir_name}"
log_path="${log_path_dir}/${log_file_name}"
mkdir -p ${log_path_dir}
touch ${log_path}
# write  start time
echo "Start Testing Time!" >> ${log_path}
echo ${time_start} >> ${log_path}
echo -e "\033[32mBegin fio test!Start time:${time_start}! \033[0m"

#check input!
if [ $# == 1 ];then
total_time=$1
if [ $total_time -lt 600 ];then
    echo -e "\033[31mInput total test time is too short! Please increase it to at least 600 seconds! \033[0m"
    echo "Input total test time is too short! Please increase it to at least 600 seconds! " >> ${log_path}
    exit 255
fi
elif [ $# == 2 ];then
total_time=$1
if [ $total_time -lt 600 ];then
    echo -e "\033[31mInput total test time is too short! Please increase it to at least 600 seconds! \033[0m"
    echo "Input total test time is too short! Please increase it to at least 600 seconds! " >> ${log_path}
    exit 255
fi
sys_part=$2
else
echo -e "\033[31mInput Error! Usage:$0 total_time(seconds) sys_partition(Optional) \033[0m"
echo "Input Error! Usage:$0 total_time(seconds) sys_partition(Optional)" >> ${log_path}
exit 255
fi
main_ver=` cat /etc/debian_version |awk '{match($0,/([0-9]*)/,a);print a[1]}'`
if [ ${main_ver} != "9" -a ${main_ver} != "8" ];then
echo -e "\033[31mOS Version is not 9 or 8!This script is not supported!\033[0m"
echo "OS Version is not 9 or 8!This script is not supported!" >>${log_path}
exit 255
fi
#fio tool
which fio > /dev/null 2>&1
if [ $? != 0 ];then
if [ ${main_ver} == "9" ];then
dpkg -i tool/debian9/libnl-3-200_3.2.27-2_amd64.deb > /dev/null 2>&1
dpkg -i tool/debian9/libnl-route-3-200_3.2.27-2_amd64.deb > /dev/null 2>&1
dpkg -i tool/debian9/libboost-random1.62.0_1.62.0+dfsg-4_amd64.deb > /dev/null 2>&1
dpkg -i tool/debian9/libboost-iostreams1.62.0_1.62.0+dfsg-4_amd64.deb > /dev/null 2>&1
dpkg -i tool/debian9/libboost-thread1.62.0_1.62.0+dfsg-4_amd64.deb
dpkg -i tool/debian9/libboost-system1.62.0_1.62.0+dfsg-4_amd64.deb
dpkg -i tool/debian9/librados2_10.2.5-7.2_amd64.deb > /dev/null 2>&1
dpkg -i tool/debian9/librbd1_10.2.5-7.2_amd64.deb > /dev/null 2>&1
dpkg -i tool/debian9/libibverbs1_1.2.1-2_amd64.deb > /dev/null 2>&1
dpkg -i tool/debian9/librdmacm1_1.1.0-2_amd64.deb > /dev/null 2>&1
dpkg -i tool/debian9/libaio1_0.3.110-3_amd64.deb > /dev/null 2>&1
dpkg -i tool/debian9/fio_2.16-1_amd64.deb > /dev/null 2>&1
elif [ ${main_ver} == "8" ];then
dpkg -i tool/debian8/librados2_0.80.7-2+deb8u2_amd64.deb > /dev/null 2>&1
dpgk -i tool/debian8/librbd1_0.80.7-2+deb8u2_amd64.deb > /dev/null 2>&1
dpkg -i tool/debian8/libibverbs1_1.1.8-1.1_amd64.deb > /dev/null 2>&1
dpkg -i tool/debian8/librdmacm1_1.0.19.1-1_amd64.deb > /dev/null 2>&1
dpkg -i tool/debian8/libaio1_0.3.110-1_amd64.deb > /dev/null 2>&1
dpkg -i tool/debian8/fio_2.1.11-2_amd64.deb > /dev/null 2>&1
fi
which fio > /dev/null 2>&1
if [ $? != 0 ];then
echo -e "\033[31mFio install failed!Please check manually!\033[0m"
echo "Fio install failed!Please check manually!" >> ${log_path}
exit 255
fi
fi

#get disk info
#df |grep "/$"|awk '{print $1}'|awk '{match($0,/\/dev\/([a-zA-Z]+)/,a);print a[1]}'
fdisk -l|grep 'Disk /dev/sd'|awk '{match($0,/\/dev\/([a-zA-Z]+)/,a);print a[1]}' >> hdd.txt
fdisk -l|grep 'Disk /dev/df'|awk '{match($0,/\/dev\/([a-zA-Z]+)/,a);print a[1]}' >> dfx.txt
fdisk -l|grep '^Disk /dev/nvme'|awk '{match($0,/\/dev\/([a-zA-Z]+[0-9]+n[0-9])/,a);print a[1]}' >> nvme.txt
disk_temp=`df |grep "/$"|awk '{print $1}'|awk -F "/" '{print $3}'|awk '{match($0,/([a-zA-Z]+)/,a);print a[1]}'`
disk=${disk_temp:0:2}
if [ $disk == "nv" ]; then
    disk_system=`df |grep "/$"|awk '{print $1}'|awk '{match($0,/\/dev\/([a-zA-Z]+[[0-9]+n[0-9]]{0,})/,a);print a[1]}'`
    sed -i "/^${disk_system}.*$/d" nvme.txt
elif [ $disk == "sd" ];then
    disk_system=`df |grep "/$"|awk '{print $1}'|awk '{match($0,/\/dev\/([a-zA-Z]+)/,a);print a[1]}'`
    sed -i "/^${disk_system}[0-9]\{0,\}$/d" hdd.txt
elif [ $disk == "df"];then
    disk_system=`df |grep "/$"|awk '{print $1}'|awk '{match($0,/\/dev\/([a-zA-Z]+)/,a);print a[1]}'`
    sed -i "/^${disk_system}[0-9]\{0,\}$/d" dfx.txt
else
    echo "No system disk find!Exit!"
    exit 255
fi
#disk_system=`df |grep "/$"|awk '{print $1}'|awk '{match($0,/\/dev\/([a-zA-Z]+)/,a);print a[1]}'`
#sed -i "/^${disk_system}[0-9]\{0,\}$/d" hdd.txt
#sed -i "/^${disk_system}[0-9]\{0,\}$/d" nvme.txt
#sed -i "/^${disk_system}[0-9]\{0,\}$/d" dfx.txt
cat hdd.txt > diskname.txt
cat nvme.txt >> diskname.txt
cat dfx.txt >> diskname.txt
if [ $# == 2 ]; then
echo ${sys_part} >> diskname.txt
fi
rm -rf hdd.txt
rm -rf nvme.txt
rm -rf dfx.txt
rm -rf ${log_path_dir}/fio_conf
rm -rf ${log_path_dir}/result
rm -rf ${log_path_dir}/conf.txt
mkdir -p ${log_path_dir}/fio_conf
DIR=${log_path_dir}/fio_conf
time_policy=$[ total_time / 28 ]
#configure file for disk
for n in `cat diskname.txt`
do
    for i in read write randread randwrite
    do
        for j in 4k 16k 64k 128k 256k 512k 1024k
            do
                echo "[global]" >> $DIR/$i"-"$j"-"$n
                echo "bs=$j"  >> $DIR/$i"-"$j"-"$n
                echo "ioengine=libaio" >> $DIR/$i"-"$j"-"$n
                echo "rw=$i"  >> $DIR/$i"-"$j"-"$n
                echo "time_based"  >> $DIR/$i"-"$j"-"$n
                echo "direct=1"  >> $DIR/$i"-"$j"-"$n
                echo "group_reporting"  >> $DIR/$i"-"$j"-"$n
                echo "randrepeat=0"  >> $DIR/$i"-"$j"-"$n
                echo "norandommap"  >> $DIR/$i"-"$j"-"$n
                echo "iodepth=128"  >> $DIR/$i"-"$j"-"$n
                echo "numjobs=1"  >> $DIR/$i"-"$j"-"$n
                echo "timeout=8800"  >> $DIR/$i"-"$j"-"$n
                echo "runtime="${time_policy}  >> $DIR/$i"-"$j"-"$n
                echo "[$i]"  >> $DIR/$i"-"$j"-"$n
                echo "filename=/dev/$n" >> $DIR/$i"-"$j"-"$n
            done
    done
done
ls $DIR >> ${log_path_dir}/conf.txt
mkdir -p ${log_path_dir}/result
RES=${log_path_dir}/result
mkdir ${log_path_dir}/conf

while read line
do
    cat ${log_path_dir}/conf.txt|grep "$line" >> ${log_path_dir}/conf/$line.txt
done < diskname.txt
mkdir -p ${log_path_dir}/run
run_dir=${log_path_dir}/run

for bs in `cat diskname.txt`
do
while read line
do
echo "fio $DIR/$line >> $RES/$line.txt  2>&1" >> ${run_dir}/run-$bs.txt
done < ${log_path_dir}/conf/$bs.txt
done
echo -e "\033[32mBegin to run fio! \033[0m"
#clear log
echo "" > /var/log/syslog
dmesg --clear > /dev/null 2>&1
for bs in `cat diskname.txt `
do
nohup /bin/bash ${run_dir}/run-$bs.txt & >/dev/null  2>&1 
done
rm -rf diskname.txt
#check if fio ended!
sleep 60
while :;
do
ps -aux|grep fio|grep -v grep
if [ $? != 0 ];then
    break
else
sleep 60
fi
done
#rm -rf ${log_path_dir}/conf.txt ${log_path_dir}/conf/ ${log_path_dir}/fio_conf ${log_path_dir}/run/
time_end=`date +%Y%m%d%H%M%S`
echo -e "\033[32mFIO test is finished! End time:${time_end} \033[0m"
echo "End Testing Time!" >> ${log_path}
echo ${time_end} >> ${log_path}
#log
echo -e "\033[32mSystem logs is big!Only write them to log file! \033[0m"
echo "Below are the system log after filter!" >> ${log_path}
echo "Below is the syslog file content!" >> ${log_path}
#/var/log/syslog
if [ ! -f /var/log/syslog ];then
echo -e "\033[31m/var/log/syslog is not exist! Skip it! \033[0m"
echo "/var/log/syslog is not exist! Skip it!" >> ${log_path}
else
cat /var/log/syslog |grep -E -i "timeout|hard reset|unknow|throttle|hardware error|buffer i/o error|fail|error|critical" |grep -v -i "partition" >> ${log_path}
fi
#/var/log/mcelog
if [ ! -f /var/log/mcelog ];then
echo -e "\033[31m/var/log/mcelog is not exist! Skip it! \033[0m"
echo "/var/log/mcelog is not exist! Skip it!" >> ${log_path}
else
cat /var/log/mcelog |grep -E -i "MCE|fail|error|critical" >> ${log_path}
fi
#dmesg
dmesg|grep -E -i "timeout|hard reset|unknow|throttle" |grep -v -E -i "partition|support|part|fail|error|critical" >> ${log_path}
exit 0
