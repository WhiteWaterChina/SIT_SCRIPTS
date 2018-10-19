#!/bin/bash
##########################################################################################
#function:此脚本测试网线拔插时的信息记录和提示，并检测ip是否能够被获取，并通过此IP往外ping通。
#Author:yanshuo
#Mail:yanshuo@inspur.com
#########################################################################################

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
DEV_name_out=$(tail -n 1 /var/log/messages|grep -i "down"|awk '{match($0,/[0-9]+:\w+:[0-9]+.[0-9]+\s(\w*)/,a);print a[1]}');
sleep 2
echo -e "\033[44;37;5m $DEV_name_out \033[0m is pluged out";
echo -e "\033[43;37;5m PLEASE PLUG IN $DEV_name_out \033[0m"
flag_plug=0;
}

function plug_in()
{
#根据关键字NIC Link is Up判断是否有网线插入，并识别插入的网线的位置，然后打印出来。
local i;
DEV_name_in=$(tail -n 1 /var/log/messages|grep -i "up"|awk '{match($0,/[0-9]+:\w+:[0-9]+.[0-9]+\s(\w*)/,a);print a[1]}');
#Current_speed_in=$(tail -n 1 /var/log/messages|grep "NIC Link is Up"|awk '{match($0,/[0-9]+:\w+:[0-9]+.[0-9]+\s(\w*):\sNIC\sLink\sis\sUp\s([0-9]+)/,a);print a[2]}')
#echo "$DEV_name_in"
sleep 3
Current_speed_in=$(ethtool $DEV_name_in |grep Speed:|awk '{print $2}')
echo -e "\033[44;37;5m $DEV_name_in \033[0m is pluged in";
echo -e "Curernt Speed for \033[44;37;5m $DEV_name_in \033[0m is \033[44;37;5m $Current_speed_in \033[0m";
ifup $DEV_name_in 2>&1
current_ip_address=$(ifconfig $DEV_name_in|grep inet|grep -v inet6|awk '{match($0,/#*([0-9]+.[0-9]+.[0-9]+.[0-9]+)/,a);print a[1]}')
echo -e "Curernt IPADDRESS for \033[44;37;5m $DEV_name_in \033[0m is \033[44;37;5m $current_ip_address \033[0m"
flag_plug=1;
#baseline收集如下三方面信息
echo "Device_name"> $RES/base_temp.txt
echo "status" >>$RES/base_temp.txt
echo "speed" >>$RES/base_temp.txt

ifconfig -a|grep flag|grep -v "lo"|grep -v "virbr"|awk -F ":" '{print $1}' > $RES/network.txt 2>&1
for Dev_name in `cat $RES/network.txt`
do
echo "$Dev_name" > $RES/$Dev_name.txt
#当前所有网口连接状态
ethtool $Dev_name |grep "Link detected"|awk '{print $3}' >> $RES/$Dev_name.txt
#当前所有网口连接速度
ethtool $Dev_name |grep "Speed:"|awk '{print $2}' >> $RES/$Dev_name.txt
done
#合并文件。
echo
for Dev_name in `cat $RES/network.txt`
do
paste -d " " $RES/base_temp.txt $RES/$Dev_name.txt > $RES/temp_in.txt
cat $RES/temp_in.txt > $RES/base_temp.txt
done
cat $RES/base_temp.txt > $RES/baseline_temp.txt
#判断新生成的文件是否跟baseline一致。一致就输出OK，不一致就输出ERROR。
diff $RES/baseline.txt $RES/baseline_temp.txt  2>&1
if [ ! $? -eq 0 ]; then
echo "Baseline error" > $RES/status.txt
echo -e "\033[41;37;5m BASELINE CHECK ERROR \033[0m"
else
echo "Baseline OK" > $RES/status.txt
echo -e "\033[42;37;5m BASELINE CHECK OK \033[0m"
fi
paste $RES/baseline_temp.txt $RES/status.txt > $RES/temp_in.txt
cat $RES/temp_in.txt > $RES/1.txt
echo "Begin to check link status!"
ping -I $DEV_name_in -c 3 $dst_ip >> $RES/temp_link_status.txt
sleep 1
Number_ping=$(cat $RES/temp_link_status.txt|grep "time="|wc -l)
if [ $Number_ping != 3 ]; then
echo "LINK STATUS ERROR" >> $RES/1.txt
echo -e "\033[41;37;5m LINK STATUS CHECK ERROR \033[0m"
else
echo "LINK STATUS OK " >> $RES/1.txt
echo -e "\033[42;37;5m LINK STATUS CHECK OK \033[0m"
fi
rm -rf $RES/temp_link_status.txt

#最后所有的信息汇总到plug_network.log文件中。
echo "Below is the data when $DEV_name_in is pluged out & in for one cycle!">> $RES/plug_network.log
date >> $RES/plug_network.log
cat $RES/1.txt >> $RES/plug_network.log
echo -e "\033[43;37;5m PLEASE PLUG OUT $DEV_name_in \033[0m"
}

function generate_baseline ()
{
echo "Device_name"> $RES/base.txt
echo "status" >> $RES/base.txt
echo "speed" >> $RES/base.txt
#获取所有网口信息
ifconfig -a|grep flag|grep -v "lo"|grep -v "virbr"|awk -F ":" '{print $1}' > $RES/network.txt 2>&1
for Dev_name in `cat $RES/network.txt`
do
echo "$Dev_name" > $RES/$Dev_name.txt
#link status
ethtool $Dev_name |grep "Link detected"|awk '{print $3}' >> $RES/$Dev_name.txt
#speed
ethtool $Dev_name |grep "Speed:"|awk '{print $2}' >> $RES/$Dev_name.txt
done
#合并文件生成baseline。
for Dev_name in `cat $RES/network.txt`
do
paste -d " " $RES/base.txt $RES/$Dev_name.txt > $RES/temp_base.txt
cat $RES/temp_base.txt > $RES/base.txt
done
cat $RES/base.txt >> $RES/baseline.txt
}

#main
if [ $# != 1 ]; then
echo "Usage:$0 Destination_IP"
exit 1
fi
for count in {0..10}
do
echo 1 >> /var/log/messages
done

RES=`date +"%Y%m%d_%H%M%S"`
mkdir -p $RES
flag_plug=1;
j=0;
i=0;
DEV_name_out_temp_1=1;
DEV_name_out_temp_2=1;
DEV_name_in_temp_1=1;
DEV_name_in_temp_2=1;
generate_baseline;
echo "Baseline is generated successfully!"
echo "You can start to plug out one network!"
dst_ip=$1

while :;
do
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
i=$(expr $i + 1);
echo -e "This is \033[44;37;5m $i \033[0m times";
else
i=1;
echo -e "This is \033[44;37;5m $i \033[0m times";
fi
continue;
fi
done
