#!/bin/bash
###############################
#Name:SUT_001_SIT_CPUSTRESS_TEST_UBUNTU
#Author:yanshuo
#Revision:
#Version:V001
#Date:2017-11-17
#Tracelist:A01-->First Version
#Function: CPU stress test under ubuntu
#Parameter_1: total test seconds
#Usage:bash SUT_001_SIT_CPUSTRESS_TEST_UBUNTU_V001.sh Parameter_1
#Example:bash SUT_001_SIT_CPUSTRESS_TEST_UBUNTU_V001.sh 3600
###############################

[ ! -d log ] && mkdir log
#create log file
time_start=`date +%Y%m%d%H%M%S`
log_file_name="${time_start}_SIT_CPUSTRESS_TEST_UBUNTU.log"
current_path=`pwd`
log_path="${current_path}/log/${log_file_name}"
touch ${log_path}
# write  start time
echo "Start Testing Time!" >> ${log_path}
echo ${time_start} >> ${log_path}
#check input!
if [ $# != 1 ];then
echo -e "\033[31mInput Error! Usage:$0 sleep_time(seconds) \033[0m"
echo "Input Error! Usage:$0 sleep_time(seconds)" >> $log_path
exit 255
else
sleep_time=$1
fi

#check stress is installed or not!
which stress > /dev/null
if [ $? != 0 ];then
echo -e "\033[31mstress is not installed!Please wait while install it! \033[0m"
echo "stress is not installed!Please wait while install it!" >> $log_path
cd tool
tar -zxf stress-1.0.4.tar.gz
cd stress-1.0.4
./configure > /dev/null 2>&1
if [ $? != 0 ];then
echo -e "\033[31mstress is installed failed!Please use apt-get -y install make/gcc/g++ to finish the preperation! \033[0m"
echo "stress is installed failed!Please use apt-get -y install make/gcc/g++ to finish the preperation!" >> ${log_path}
exit 255
fi
make > /dev/null 2>&1
if [ $? != 0 ];then
echo -e "\033[31mstress is installed failed!Please use apt-get -y install make/gcc/g++ to finish the preperation! \033[0m"
echo "stress is installed failed!Please use apt-get -y install make/gcc/g++ to finish the preperation!" >> ${log_path}
exit 255
fi
make install > /dev/null 2>&1
if [ $? != 0 ];then
echo -e "\033[31mstress is installed failed!Please use apt-get -y install make/gcc/g++ to finish the preperation! \033[0m"
echo "stress is installed failed!Please use apt-get -y install make/gcc/g++ to finish the preperation!" >> ${log_path}
exit 255
fi
cd $current_path
which stress > /dev/null
if [ $? != 0 ]; then
echo -e "\033[31mstress is installed failed!Please confirm! \033[0m"
echo "stress is installed failed!Please confirm!Exit test!" >> ${Log_path}
exit 255
fi
fi
#clear log
echo "" > /var/log/syslog
dmesg --clear > /dev/null 2>&1
#caculate cpu threads numbers!
echo -e "\033[32mBegin to start CPU stress test!Please wait ${sleep_time} seconds to finish test! \033[0m"
cpu_number=`cat /proc/cpuinfo | grep processor | wc -l`
stress -c ${cpu_number} -t ${sleep_time} >> ${log_path}
#log check
echo -e "\033[32mBegin to check log file! \033[0m"
echo -e "\033[32mBegin to check /var/log/syslog! \033[0m"
echo "Below is the log from /var/log/syslog!" >> ${log_path}
if [ ! -f /var/log/syslog ];then
echo -e "\033[31m/var/log/syslog is not exist! Skip it! \033[0m"
echo "/var/log/syslog is not exist! Skip it!" >> ${log_path}
else
cat /var/log/syslog |grep -E -i "timeout|hard reset|unknow|throttle|hardware error|buffer i/o error|fail|error|critical" |grep -v -i "partition" >> ${log_path}
echo -e "\033[32m/var/log/syslog check finished! \033[0m"
fi
#/var/log/mcelog
echo -e "\033[32mBegin to check /var/log/mcelog! \033[0m"
echo "Below is the log from /var/log/mcelog!" >> ${log_path}
if [ ! -f /var/log/mcelog ];then
echo -e "\033[31m/var/log/mcelog is not exist! Skip it! \033[0m"
echo "/var/log/mcelog is not exist! Skip it!" >> ${log_path}
else
cat /var/log/mcelog |grep -E -i "MCE|fail|error|critical" >> ${log_path}
echo -e "\033[32m/var/log/mcelog check finished! \033[0m"
fi
#dmesg
echo -e "\033[32mBegin to check dmesg! \033[0m"
echo "Below is the log from dmesg!" >> ${log_path}
dmesg|grep -E -i "timeout|hard reset|unknow|throttle" |grep -v -E -i "partition|support|part|fail|error|critical" >> ${log_path}
echo -e "\033[32mdemsg check finished! \033[0m"
#write end time
time_end=`date +%Y%m%d%H%M%S`
echo "End Testing Time!" >> ${log_path}
echo ${time_end} >> ${log_path}
exit 0
