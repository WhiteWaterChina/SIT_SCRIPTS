#!/bin/bash
###############################
#Name:SUT_001_SIT_NETPLUG_TEST_RHEL
#Author:yanshuo
#Revision:
#Version:V001
#Date:2018-01-12
#Tracelist:V001-->First Version
#Function: record network plug in & out info
#Parameter_1:target ip
#Parameter_2: total loop count
#Usage:sh SUT_001_SIT_NETPLUG_TEST_RHEL.sh Parameter_1 Parameter_2
#Example:sh SUT_001_SIT_NETPLUG_TEST_RHEL_V001.sh 100.2.36.2 20
###############################

DEV_name_out=
DEV_name_in=
DEV_name_out_temp_1=
DEV_name_out_temp_2=
DEV_name_in_temp_1=
DEV_name_in_temp_2=

function plug_out ()
{
local i;
#根据关键字NIC Link is Down判断是否有网线插入，并识别插入的网线的位置，然后打印出来
DEV_name_out=$(tail -n 1 /var/log/messages|grep -i "down"|awk '{match($0,/\((.*?)\)\]/,a);print a[1]}');
sleep 2
echo -e "\033[44;37;5m $DEV_name_out \033[0m is pluged out";
echo -e "\033[43;37;5m PLEASE PLUG IN $DEV_name_out \033[0m"
flag_plug=0;
}

function plug_in()
{
#根据关键字NIC Link is Up判断是否有网线插入，并识别插入的网线的位置，然后打印出来。
local i;
DEV_name_in=$(tail -n 1 /var/log/messages|grep -i "up"|awk '{match($0,/\((.*?)\)\]/,a);print a[1]}');
sleep 3
Current_speed_in=$(ethtool $DEV_name_in |grep Speed:|awk '{print $2}')
echo -e "\033[44;37;5m $DEV_name_in \033[0m is pluged in";
echo -e "Curernt Speed for \033[44;37;5m $DEV_name_in \033[0m is \033[44;37;5m $Current_speed_in \033[0m";
ifup $DEV_name_in 2>&1
current_ip_address=$(ifconfig $DEV_name_in|grep inet|grep -v inet6|awk '{match($0,/#*([0-9]+.[0-9]+.[0-9]+.[0-9]+)/,a);print a[1]}')
echo -e "Curernt IPADDRESS for \033[44;37;5m $DEV_name_in \033[0m is \033[44;37;5m $current_ip_address \033[0m"
flag_plug=1;
#baseline收集如下三方面信息
echo "Device_name"> $log_path_dir/base_temp.txt
echo "status" >>$log_path_dir/base_temp.txt
echo "speed" >>$log_path_dir/base_temp.txt

ifconfig -a|grep flag|grep -v "lo"|grep -v "virbr"|awk -F ":" '{print $1}' > $log_path_dir/network.txt 2>&1
for Dev_name in `cat $log_path_dir/network.txt`
do
echo "$Dev_name" > $log_path_dir/$Dev_name.txt
#当前所有网口连接状态
ethtool $Dev_name |grep "Link detected"|awk '{print $3}' >> $log_path_dir/$Dev_name.txt
#当前所有网口连接速度
ethtool $Dev_name |grep "Speed:"|awk '{print $2}' >> $log_path_dir/$Dev_name.txt
done
#合并文件。
echo
for Dev_name in `cat $log_path_dir/network.txt`
do
paste -d " " $log_path_dir/base_temp.txt $log_path_dir/$Dev_name.txt > $log_path_dir/temp_in.txt
cat $log_path_dir/temp_in.txt > $log_path_dir/base_temp.txt
done
cat $log_path_dir/base_temp.txt > $log_path_dir/baseline_temp.txt
#判断新生成的文件是否跟baseline一致。一致就输出OK，不一致就输出ERROR。
diff $log_path_dir/baseline.txt $log_path_dir/baseline_temp.txt  2>&1
if [ ! $? -eq 0 ]; then
echo "Baseline error" > $log_path_dir/status.txt
echo -e "\033[41;37;5m BASELINE CHECK ERROR \033[0m"
else
echo "Baseline OK" > $log_path_dir/status.txt
echo -e "\033[42;37;5m BASELINE CHECK OK \033[0m"
fi
paste $log_path_dir/baseline_temp.txt $log_path_dir/status.txt > $log_path_dir/temp_in.txt
cat $log_path_dir/temp_in.txt > $log_path_dir/1.txt
echo "Begin to check link status!"
sleep 5
ping -I $DEV_name_in -c 3 $dst_ip >> $log_path_dir/temp_link_status.txt
sleep 1
Number_ping=$(cat $log_path_dir/temp_link_status.txt|grep "time="|wc -l)
if [ $Number_ping != 3 ]; then
echo "LINK STATUS ERROR" >> $log_path_dir/1.txt
echo -e "\033[41;37;5m LINK STATUS CHECK ERROR \033[0m"
else
echo "LINK STATUS OK " >> $log_path_dir/1.txt
echo -e "\033[42;37;5m LINK STATUS CHECK OK \033[0m"
fi
rm -rf $log_path_dir/temp_link_status.txt

#最后所有的信息汇总到plug_network.log文件中。
echo "Below is the data when $DEV_name_in is pluged out & in for one cycle!">> $log_path
date >> $log_path
cat $log_path_dir/1.txt >> $log_path
echo -e "\033[43;37;5m PLEASE PLUG OUT $DEV_name_in \033[0m"
}

function generate_baseline ()
{
echo "Device_name"> $log_path_dir/base.txt
echo "status" >> $log_path_dir/base.txt
echo "speed" >> $log_path_dir/base.txt
#获取所有网口信息
ifconfig -a|grep flag|grep -v "lo"|grep -v "virbr"|awk -F ":" '{print $1}' > $log_path_dir/network.txt 2>&1
for Dev_name in `cat $log_path_dir/network.txt`
do
echo "$Dev_name" > $log_path_dir/$Dev_name.txt
#link status
ethtool $Dev_name |grep "Link detected"|awk '{print $3}' >> $log_path_dir/$Dev_name.txt
#speed
ethtool $Dev_name |grep "Speed:"|awk '{print $2}' >> $log_path_dir/$Dev_name.txt
done
#合并文件生成baseline。
for Dev_name in `cat $log_path_dir/network.txt`
do
paste -d " " $log_path_dir/base.txt $log_path_dir/$Dev_name.txt > $log_path_dir/temp_base.txt
cat $log_path_dir/temp_base.txt > $log_path_dir/base.txt
done
cat $log_path_dir/base.txt >> $log_path_dir/baseline.txt
}

#main
#check and create log dir
[ ! -d log ] && mkdir log
#create log file
time_start=`date +%Y%m%d%H%M%S`
log_dir_name="${time_start}_SIT_NETPLUG_TEST_RHEL"
log_file_name="${time_start}_SIT_NETPLUG_TEST_RHEL.log"
current_path=`pwd`
log_path_dir="${current_path}/log/${log_dir_name}"
log_path="${log_path_dir}/${log_file_name}"
mkdir -p ${log_path_dir}
touch ${log_path}
# write  start time
echo "Start Testing Time!" >> ${log_path}
echo ${time_start} >> ${log_path}

if [ $# != 2 ]; then
echo -e "\033[31mInput Error! Usage:$0 target_ip total_loop\033[0m"
echo "Input Error! Usage:$0 target_ip total_loop" >> $log_path
exit 255
fi
for count in {0..10}
do
echo 1 >> /var/log/messages
done

flag_plug=1;
j=0;
count=0;
DEV_name_out_temp_1=1;
DEV_name_out_temp_2=1;
DEV_name_in_temp_1=1;
DEV_name_in_temp_2=1;
generate_baseline;
echo "Baseline is generated successfully!"
echo "You can start to plug out one network!"
dst_ip=$1
total_loop=$2
total_loop=$(expr $total_loop - 1);
while :;
do
if [[ $count -gt $total_loop ]];then
break
else
#plug_out_test
Temp_out=$(tail -n 1 /var/log/messages|grep -i "down");
if [ -n "$Temp_out" ] && [ "$flag_plug"x = 1x ]; then
plug_out;
DEV_name_out_temp_2=$DEV_name_out_temp_1;
DEV_name_out_temp_1=$DEV_name_out;
fi

#plug_in_test
Temp_in=$(tail -n 1 /var/log/messages|grep -i "up"|grep -v -i "down");
if [ -n "$Temp_in" ] && [ "$flag_plug"x = 0x ]; then
plug_in;
DEV_name_in_temp_2=$DEV_name_in_temp_1;
DEV_name_in_temp_1=$DEV_name_in;
if [ "$DEV_name_in"x = "$DEV_name_in_temp_2"x ]; then
count=$(expr $count + 1);
echo -e "This is \033[44;37;5m $count \033[0m times";
else
count=1;
echo -e "This is \033[44;37;5m $count \033[0m times";
fi
continue;
fi
fi
done

rm -rf $log_path_dir/1.txt $log_path_dir/base* $log_path_dir/temp* $log_path_dir/network*
time_end=`date +%Y%m%d%H%M%S`
echo "End Testing Time!" >> ${log_path}
echo ${time_start} >> ${log_path}
exit 0
