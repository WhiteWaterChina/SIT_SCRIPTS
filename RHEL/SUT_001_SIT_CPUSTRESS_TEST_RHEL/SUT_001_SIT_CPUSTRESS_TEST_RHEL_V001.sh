#!/bin/bash
###############################
#Name:SUT_001_SIT_CPUSTRESS_TEST_RHEL
#Author:yanshuo
#Revision:
#Version:V001
#Date:2017-11-17
#Tracelist:V001-->First Version
#Function: CPU stress test under rhel
#Parameter_1: total test seconds
#Parameter_2:platform(purley/grantley)
#Usage:sh SUT_001_SIT_CPUSTRESS_TEST_RHEL_V001.sh Parameter_1 Parameter_2
#Example:sh SUT_001_SIT_CPUSTRESS_TEST_RHEL_V001.sh 3600 purley
###############################

[ ! -d log ] && mkdir log
#create log file
time_start=`date +%Y%m%d%H%M%S`
log_dir_name="${time_start}_SIT_CPUSTRESS_TEST_RHEL"
log_file_name="${time_start}_SIT_CPUSTRESS_TEST_RHEL.log"
current_path=`pwd`
log_path_dir="${current_path}/log/${log_dir_name}"
log_path="${log_path_dir}/${log_file_name}"
mkdir -p ${log_path_dir}
touch ${log_path}
# write  start time
echo -e "\033[32mBeing CPU test!\033[0m"
echo -e "Start time:\033[32m${time_start} \033[0m"
echo "Start Testing Time!" >> ${log_path}
echo ${time_start} >> ${log_path}
#check input!
if [ $# != 2 ];then
echo -e "\033[31mInput Error! Usage:$0 sleep_time(seconds) platform(purley/grantley)\033[0m"
echo "Input Error! Usage:$0 sleep_time(seconds) platform(purley/grantley)" >> $log_path
exit 255
else
test_time=$1
platform=$2
fi
#check ht
cores=`cat /proc/cpuinfo |grep "cpu cores" |uniq |awk '{printf "%10d",$4}'`
phycpu=`cat /proc/cpuinfo |grep "physical id" |sort |uniq |wc -l`
total=`cat /proc/cpuinfo |grep "GHz" |wc -l`
ht=`echo "$cores*$phycpu" |bc`
if [ $ht == $total ]; then
    echo -e "\033[31m May be HT is not Open,Please Check BIOS!\033[37m"
    exit 255
else
echo -e "\033[32mHT check pass!\033[0m"
fi
which gnuplot > /dev/null 2>&1
if [ $? != 0 ];then
echo -e "\033[31mgnuplot is not installed!Please wait while  install it!\033[0m"
echo "gnuplot is not installed!Please wait while install it!" >> ${log_path}
cd tool/gnuplot/
tar -zxf gnuplot-5.0.7.tar.gz
cd gnuplot-5.0.7/
./configure > /dev/null 2>&1
if [ $? != 0 ];then
echo -e "\033[31mgnuplot is installed failed!Please check if make/gcc/g++ is installed! \033[0m"
echo "gnuplot is installed failed!Please check if make/gcc/g++ is installed!" >> ${log_path}
exit 255
fi
make > /dev/null 2>&1
if [ $? != 0 ];then
echo -e "\033[31mgnuplot is installed failed!Please check if make/gcc/g++ is installed! \033[0m"
echo "gnuplot is installed failed!Please check if make/gcc/g++ is installed!" >> ${log_path}
exit 255
fi
make install > /dev/null 2>&1
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

#clean syslog
echo "" > /var/log/messages
dmesg --clear > /dev/null 2>&1
ptumon_time=$[ test_time - 20 ]
chmod -R 777 tool
if [ $platform == "grantley" -o $platform == "purley" ];then
./tool/$platform/ptugen -b 1 -t ${test_time} -y -q > /dev/null 2>&1 &
else
echo -e "\033[31mPlatform input incorrect!Please check!\033[0m"
echo "Platform input incorrect!Please check!" >> ${log_path}
exit 255
fi
sleep 10
if [ $platform == "grantley" ]; then
./tool/grantley/ptumon -d CPU -i 5000 -y -csv -t ${ptumon_time} >> ${log_path_dir}/cpu-ptumon-detail.csv
elif [ $platform == "purley" ]; then
./tool/purley/ptumon -filter 0x01 -i 5000 -y -csv -t ${ptumon_time} >> ${log_path_dir}/cpu-ptumon-detail.csv
fi
#sleep 20
#to insure ptugen is terminated
ps -aux|grep ptugen|grep -v grep > /dev/null 2>&1
if [ $# == 0 ];then
    killall -9 ptugen
fi
#filter data to plot
if [ $platform == "grantley" ]; then
cat ${log_path_dir}/cpu-ptumon-detail.csv|sed '1,/TIME,CPU,/d' >> ${log_path_dir}/filter-ptumon.csv
cpu_number=`cat ${log_path_dir}/filter-ptumon.csv|awk -F "," '{print $2}'|sort|uniq|wc -l`
#if [ $platform == "grantley" ]; then
for ((count=0;count<${cpu_number};count++))
do
    mkdir -p ${log_path_dir}/cpuinfo-$count
    #cpu cfreq, change M to G
    cat ${log_path_dir}/filter-ptumon.csv|awk -F "," '{if($2 == '$count'){print $5/1000}}' >> ${log_path_dir}/cpuinfo-$count/cpu-cfreq-tmp.txt
    #temp
    cat ${log_path_dir}/filter-ptumon.csv|awk -F "," '{if($2 == '$count'){print $9}}' >> ${log_path_dir}/cpuinfo-$count/cpu-temp-tmp.txt
    #power
    cat ${log_path_dir}/filter-ptumon.csv|awk -F "," '{if($2 == '$count'){print $11}}' >> ${log_path_dir}/cpuinfo-$count/cpu-power-tmp.txt
done
elif [ $platform == "purley" ]; then
cat ${log_path_dir}/cpu-ptumon-detail.csv|sed '1,/Time,Dev,/d'|sed '/Time,Dev,/d' >> ${log_path_dir}/filter-ptumon.csv
cpu_number=`cat ${log_path_dir}/filter-ptumon.csv|awk -F "," '{print $2}'|sort|uniq|wc -l`
for ((count=0;count<${cpu_number};count++))
do
    mkdir -p ${log_path_dir}/cpuinfo-$count
    #cpu cfreq, change M to G
    cat ${log_path_dir}/filter-ptumon.csv|awk -F "," '{if($2 == "'CPU$count' "){print $6/1000}}' >> ${log_path_dir}/cpuinfo-$count/cpu-cfreq-tmp.txt
    #temp
    cat ${log_path_dir}/filter-ptumon.csv|awk -F "," '{if($2 == "'CPU$count' "){print $11}}' >> ${log_path_dir}/cpuinfo-$count/cpu-temp-tmp.txt
    #power
    cat ${log_path_dir}/filter-ptumon.csv|awk -F "," '{if($2 == "'CPU$count' "){print $13}}' >> ${log_path_dir}/cpuinfo-$count/cpu-power-tmp.txt
done

fi
#length of the file
total_line=`cat ${log_path_dir}/filter-ptumon.csv|wc -l`
length=$[ total_line / cpu_number ]
#timestamp
for ((i=0,j=0;i<${length};i++))
do
echo $j >> ${log_path_dir}/timestamp.txt
j=$[ j + 5 ]
done
#paste
for ((count=0;count<${cpu_number};count++))
do
paste -d "," ${log_path_dir}/timestamp.txt ${log_path_dir}/cpuinfo-$count/cpu-cfreq-tmp.txt > ${log_path_dir}/cpuinfo-$count/cpu-cfreq.txt
#paste -d "," ${log_path_dir}/timestamp.txt ${log_path_dir}/cpuinfo-$count/cpu-usage-tmp.txt > ${log_path_dir}/cpuinfo-$count/cpu-usage.txt
paste -d "," ${log_path_dir}/timestamp.txt ${log_path_dir}/cpuinfo-$count/cpu-temp-tmp.txt > ${log_path_dir}/cpuinfo-$count/cpu-temp.txt
#paste -d "," ${log_path_dir}/timestamp.txt ${log_path_dir}/cpuinfo-$count/cpu-voltage-tmp.txt > ${log_path_dir}/cpuinfo-$count/cpu-voltage.txt
paste -d "," ${log_path_dir}/timestamp.txt ${log_path_dir}/cpuinfo-$count/cpu-power-tmp.txt > ${log_path_dir}/cpuinfo-$count/cpu-power.txt
done
#plot
for ((count=0;count<${cpu_number};count++))
do
x_time=$(echo "$ptumon_time-5"|bc)
#calculate the max and min
#max
max_cfreq=`cat ${log_path_dir}/cpuinfo-$count/cpu-cfreq-tmp.txt|sort -n -r|head -n 1|awk '{match($0,/([0-9]+\.*[0-9]*)/,a);print a[1]}'`
max_temp_temp=`cat ${log_path_dir}/cpuinfo-$count/cpu-temp-tmp.txt|sort -n -r|head -n 1|awk '{match($0,/([0-9]+\.*[0-9]*)/,a);print a[1]}'`
max_temp=`echo $max_temp_temp|awk '{printf "%.2f",$NF}'`
max_power=`cat ${log_path_dir}/cpuinfo-$count/cpu-power-tmp.txt|sort -n -r|head -n 1|awk '{match($0,/([0-9]+\.*[0-9]*)/,a);print a[1]}'`
echo $max_temp > ${log_path_dir}/cpuinfo-$count/max.txt
echo $max_power >> ${log_path_dir}/cpuinfo-$count/max.txt
max_y_left=$(echo "${max_cfreq}*1.1"|bc)
max_y_right_temp=`cat ${log_path_dir}/cpuinfo-$count/max.txt|sort -n -r|head -n 1`
max_y_right=$(echo "${max_y_right_temp}*1.1"|bc)
#min
min_cfreq=`cat ${log_path_dir}/cpuinfo-$count/cpu-cfreq-tmp.txt|sort -n|head -n 1|awk '{match($0,/([0-9]+\.*[0-9]*)/,a);print a[1]}'`
min_temp_temp=`cat ${log_path_dir}/cpuinfo-$count/cpu-temp-tmp.txt|sort -n|head -n 1|awk '{match($0,/([0-9]+\.*[0-9]*)/,a);print a[1]}'`
min_temp=`echo $min_temp_temp|awk '{printf "%.2f",$NF}'`
min_power=`cat ${log_path_dir}/cpuinfo-$count/cpu-power-tmp.txt|sort -n|head -n 1|awk '{match($0,/([0-9]+\.*[0-9]*)/,a);print a[1]}'`
echo $min_temp > ${log_path_dir}/cpuinfo-$count/min.txt
echo $min_power >> ${log_path_dir}/cpuinfo-$count/min.txt
min_y_left=$(echo "${min_cfreq}*0.9"|bc)
min_y_right_temp=`cat ${log_path_dir}/cpuinfo-$count/min.txt|sort -n|head -n 1`
min_y_right=$(echo "${min_y_right_temp}*0.9"|bc)
gnuplot<<- END
set terminal svg
set title 'MONITOR_INFO_CPU$count'
set datafile separator ','
set ytics nomirror
set y2tics
set xlabel 'Time(s)'
set ylabel 'CFreq(GHz)'
set y2label 'POWER(W)/Temperature(Celsius)'
set xrange [0:$ptumon_time]
set yrange [${min_y_left}:${max_y_left}]
set y2range [${min_y_right}:${max_y_right}]
set output "Image_MONITOR_INFO_CPU${count}.svg"
set border
set key box
plot '${log_path_dir}/cpuinfo-$count/cpu-cfreq.txt' title 'CPU CFreq' w lines lt 1 axis x1y1, '${log_path_dir}/cpuinfo-$count/cpu-power.txt' title 'CPU POWER' w lines lt 5 axis x1y2,\
 '${log_path_dir}/cpuinfo-$count/cpu-temp.txt' title 'CPU Temperature' w lines lt 3 axis x1y2
set output
END
mv Image_MONITOR_INFO_CPU${count}.svg ${log_path_dir}/
rm -rf ${log_path_dir}/cpuinfo-$count
done
rm -rf ${log_path_dir}/filter-ptumon* ${log_path_dir}/timestamp.txt 

#log check
echo -e "\033[32mBegin to check log file! \033[0m"
echo -e "\033[32mBegin to check /var/log/messages! \033[0m"
echo "Below is the log from /var/log/messages!" >> ${log_path}
if [ ! -f /var/log/messages ];then
echo -e "\033[31m/var/log/messages is not exist! Skip it! \033[0m"
echo "/var/log/messages is not exist! Skip it!" >> ${log_path}
else
cat /var/log/messages|grep -E -i "timeout|hard reset|unknow|throttle|hardware error|buffer i/o error|fail|error|critical" |grep -v -i "partition" >> ${log_path}
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
echo -e "\033[32mTest Finished!\033[0m"
echo -e "End Time:\033[32m$time_end\033[0m"
exit 0
