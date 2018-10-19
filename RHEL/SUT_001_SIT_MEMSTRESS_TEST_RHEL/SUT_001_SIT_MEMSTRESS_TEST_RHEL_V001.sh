#!/bin/bash
###############################
#Name:SUT_001_SIT_MEMSTRESS_TEST_RHEL
#Author:yanshuo
#Revision:
#Version:V001
#Date:2017-12-12
#Tracelist:V001-->First Version
#Function: memory test under rhel
#Parameter_1:total test seconds
#Usage:bash SUT_001_SIT_MEMSTRESS_TEST_RHEL_V001.sh Parameter_1
#Example:bash SUT_001_SIT_MEMSTRESS_TEST_RHEL_V001.sh 3600
###############################


#check and create log dir
[ ! -d log ] && mkdir log
#create log file
time_start=`date +%Y%m%d%H%M%S`
log_dir_name="${time_start}_SIT_MEMSTRESS_TEST_RHEL"
log_file_name="${time_start}_SIT_MEMSTRESS_TEST_RHEL.log"
current_path=`pwd`
log_path_dir="${current_path}/log/${log_dir_name}"
log_path="${log_path_dir}/${log_file_name}"
mkdir -p ${log_path_dir}
touch ${log_path}
# write  start time
echo "Start Testing Time!" >> ${log_path}
echo ${time_start} >> ${log_path}
echo -e "\033[32mBegin memtester test! Start time:${time_start} \033[0m"
#check input!
if [ $# != 1 ];then
echo -e "\033[31mInput Error! Usage:$0 sleep_time(seconds) \033[0m"
echo "Input Error! Usage:$0 sleep_time(seconds)" >> $log_path
exit 255
else
sleep_time=$1
fi
chmod -R 777 tool
#install memtester-4.3.0
cd tool
tar -zxf memtester-4.3.0.tar.gz
cd memtester-4.3.0

#test if /usr/local/man/man8 is exist
if [ ! -d /usr/local/man/man8 ]; then
if [ ! -d /usr/local/man/man1 ]; then
mkdir -p /usr/local/man/man8
else
sed -i 's/\$(INSTALLPATH)\/man\/man8/\$(INSTALLPATH)\/man\/man1/g' Makefile
fi
fi
make > /dev/null 2>&1 && make install > /dev/null 2>&1
if [ $? != 0 ];then
echo -e "\033[31mmemtester is installed failed!Please check if make/gcc is intalled! \033[0m"
echo "memtester is installed failed!Please check if make/gcc is installed!" >> ${log_path}
exit 255
fi
#install gnuplot
which gnuplot > /dev/null 2>&1
if [ $? != 0 ];then
echo -e "\033[31mgnuplot is not installed!Please wait while  install it!\033[0m"
echo "gnuplot is not installed!Please wait while install it!" >> ${log_path}
cd tool/gnuplot/
tar -zxf gnuplot-5.0.7.tar.gz
cd gnuplot-5.0.7/
./configure > /dev/null 2>&1 && make > /dev/null 2>&1 && make install > /dev/null 2>&1
if [ $? != 0 ];then
echo -e "\033[31mgnuplot is installed failed!Please check if make/gcc/g++ is installed! \033[0m"
echo "gnuplot is installed failed!Please check if make/gcc/g++ is installed!" >> ${log_path}
exit 255
fi
cd $current_path
which gnuplot > /dev/null 2>&1
if [ $? != 0 ];then
echo -e "\033[31mgnuplot is installed failed! \033[0m"
echo "gnuplot is installed failed!" >> ${log_path}
exit 255
fi
fi
CPU=`cat /proc/cpuinfo |grep process |wc -l`
FREE_MEM1=`free |grep Mem |awk -F ' ' '{print $4}'`
FREE_MEM2=`free |grep Mem |awk -F ' ' '{print $4}'`
FREE_MEM3=`free |grep Mem |awk -F ' ' '{print $4}'`
FREE_MEM=`echo "($FREE_MEM1+$FREE_MEM2+$FREE_MEM3)/3" |bc`
rate=995
if [ $FREE_MEM -lt 129000000 ] ;then rate=995;fi
if [ $FREE_MEM -lt 33000000 ] ;then rate=985;fi
if [ $FREE_MEM -lt 9000000 ] ;then rate=965;fi
TEST_MEM=`echo "$FREE_MEM/1024/$CPU*$rate/1000" |bc`
cat /proc/cpuinfo |grep process |awk -F ' ' '{print $3}' >> 1.txt
#clear syslog
echo "" > /var/log/messages
dmesg --clear >/dev/null 2>&1
for i in `cat 1.txt`
do
	memtester $TEST_MEM 10000 >> ${log_path_dir}/memtest.log &
done 
rm -rf 1.txt

# monitor mem use utilize and draw image
mon_time=$[ sleep_time - 20 ]

sleep 2
free -w -k -s 1 -c ${mon_time}|grep Mem >> ${log_path_dir}/mem-use.txt
#sleep 20
#filter data to plot
total_line=`cat ${log_path_dir}/mem-use.txt|wc -l`
while read line
do
total=`echo $line|awk '{print $2}'|awk '{printf "%.2f",$NF}'`
used=`echo $line|awk '{print $3}'|awk '{printf "%.2f",$NF}'`
usage=$(echo "scale=2;$used/$total"|bc)
echo $usage >> ${log_path_dir}/mem-filter.txt
done < ${log_path_dir}/mem-use.txt
#length of the file
#timestamp
for ((i=0;i<${total_line};i++))
do
echo $i >> ${log_path_dir}/timestamp.txt
done
#paste
paste -d "," ${log_path_dir}/timestamp.txt ${log_path_dir}/mem-filter.txt > ${log_path_dir}/mem.txt

#plot
x_time=$mon_time
#calculate the max and min
#max
max_usage_temp=`cat ${log_path_dir}/mem-filter.txt|sort -n -r|head -n 1`
max_usage=$(echo "${max_usage_temp}*1.1"|bc)
#min
min_usage_temp=`cat ${log_path_dir}/mem-filter.txt|sort -n|head -n 1`
min_usage=$(echo "${min_usage_temp}*0.9"|bc)
gnuplot<<- END
set terminal svg
set title 'MONITOR_MEM_UTILIZATION'
set datafile separator ','
set ytics nomirror
set xlabel 'Time(s)'
set ylabel 'Usage'
set xrange [0:$mon_time]
set yrange [${min_usage}:${max_usage}]
set output "IMAGE_MONITOR_MEM_UTILIZATION.svg"
set border
set key box
plot '${log_path_dir}/mem.txt' title 'MEM UTILIZATION' w lines lt 1 axis x1y1
set output
END
mv IMAGE_MONITOR_MEM_UTILIZATION.svg ${log_path_dir}/
#end memtester  test
sleep 60
killall -9 memtester > /dev/null 2>&1
killall -9 memtester > /dev/null 2>&1
#collect system log
echo -e "\033[32mSystem logs is big!Not show here, only write them to log file! \033[0m"
echo "Below are the system log after filter!" >> ${log_path}
echo "Below is the messages file content!" >> ${log_path}
#/var/log/syslog
if [ ! -f /var/log/messages ];then
echo -e "\033[31m/var/log/messages is not exist! Skip it! \033[0m"
echo "/var/log/messages is not exist! Skip it!" >> ${log_path}
else
cat /var/log/messages |grep -E -i "timeout|hard reset|unknow|throttle|hardware error|buffer i/o error|fail|error|critical" |grep -v -i "partition" >> ${log_path}
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

time_end=`date +%Y%m%d%H%M%S`
echo -e "\033[32mFinish memtester test! End time:${time_end} \033[0m"
echo "End Testing Time!" >> ${log_path}
echo ${time_end} >> ${log_path}

exit 0
