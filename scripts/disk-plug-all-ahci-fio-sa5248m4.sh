#!/bin/bash
##########################################################################################
#function:此脚本测试使用mpt2sas驱动时的硬盘拔插测试，
#1. 在硬盘拔出来时会提示是哪个盘符被拔出，同时显示对于当前盘符来说是连续的第几次。同一个盘符必须是连续拔插，否则不会累计。
#2. 在硬盘插入时会提示哪个盘符被插入。同时显示对于当前盘符来说是连续的第几次。同一个盘符必须是连续拔插，否则不会累计。
#3. 在硬盘插入时会将当前所有硬盘的状态（包括SN、盘符、容量）。同时跟程序刚执行时的原始状态的文件进行对比，确认拔插是否引起了盘符等信息的变化。
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
#根据关键字removing判断是否有硬盘拔出，并识别拔出的硬盘的盘符，然后打印出来
Out=$(tail -n 5 /var/log/messages|grep 'Stopping disk'|awk '{print $8}');
length_out=$(echo "$Out"|awk '{print length($0)}');
i=$(expr $length_out - 1);
DEV_name_out=$(echo "$Out"|cut -b 2-$i);
echo -e "\033[44;37;5m $DEV_name_out \033[0m is pluged out";
flag_plug=0;
}

function plug_in()
{
#根据关键字Attached SCSI disk判断是否有硬盘插入，并识别插入的硬盘的盘符，然后打印出来。
local i;
In=$(tail -n 3 /var/log/messages|grep -i "Attached SCSI disk"|awk '{print $8}');
length_in=$(echo "$In"|awk '{print length($0)}');
i=$(expr $length_in - 1);
DEV_name_in=$(echo "$In"|cut -b 2-$i);
echo -e "\033[44;37;5m $DEV_name_in \033[0m is pluged in";
flag_plug=1;
#表头
echo "Disk_name">1.txt
echo "Serial_Number" >>1.txt
echo "Capacity" >>1.txt
#每个盘符对照如上三条生成一个文件
fdisk -l |grep "Disk /dev/sd" |awk '{print $2|"cut -b8"}'|sort > /root/disk.txt 2>&1
for Dev_name in `cat /root/disk.txt`
do
echo "sd$Dev_name" > $Dev_name.txt
smartctl -a /dev/sd$Dev_name |grep -i "serial number"|awk '{print $3}'>>$Dev_name.txt
smartctl -a /dev/sd$Dev_name |grep -i "capacity"|awk '{print $3}' >> $Dev_name.txt
done
#合并文件。
echo
for Dev_name in `cat /root/disk.txt`
do
paste -d " " 1.txt $Dev_name.txt > temp_in.txt
cat temp_in.txt > 1.txt
done
#判断新生成的文件是否跟baseline一致。一致就输出OK，不一致就输出ERROR。
diff baseline.xls 1.txt
if [ ! $? -eq 0 ]; then
echo "error" > status.txt 
echo -e "\033[41;37;5m error \033[0m"
else
echo "OK" > status.txt
echo -e "\033[42;37;5m OK \033[0m"
fi
paste 1.txt status.txt > temp_in.txt
cat temp_in.txt > 1.txt
#最后所有的信息汇总到plug.log文件中。
echo "Below is the data when $DEV_name_in is pluged out & in for one cycle!">> plug.log
date >> plug.log
cat 1.txt >> plug.log
nohup /usr/local/bin/fio --readwrite=randrw --rwmixread=50 --bs=4k --numjobs=1 --runtime=432000s --end_fsync=0 --group_reporting --direct=1 --ioengine=libaio --time_based --invalidate=1 --norandommap --randrepeat=0 --exitall --name=123 --filename=/dev/sdb >> $PWD/fio-log.log &
echo "Please wait for 10 seconds!"
sleep 10
echo "Please plug out the disk you want!"
}

function generate_baseline ()
{
echo "Disk_name">base.txt
echo "Serial_Number" >>base.txt
echo "Capacity" >>base.txt
#每个盘符对照如上三条生成一个文件
fdisk -l |grep "Disk /dev/sd" |awk '{print $2|"cut -b8"}'|sort > /root/disk.txt 2>&1
for Dev_name in `cat /root/disk.txt`
do
echo "sd$Dev_name" > $Dev_name.txt
smartctl -a /dev/sd$Dev_name |grep -i "serial number"|awk '{print $3}'>>$Dev_name.txt
smartctl -a /dev/sd$Dev_name |grep -i "capacity"|awk '{print $3}' >> $Dev_name.txt
done
#合并文件声成baseline。
echo
for Dev_name in `cat /root/disk.txt`
do
paste -d " " base.txt $Dev_name.txt > temp_base.txt
cat temp_base.txt > base.txt
done
cat base.txt >> baseline.xls
nohup /usr/local/bin/fio --readwrite=randrw --rwmixread=50 --bs=4k --numjobs=1 --runtime=432000s --end_fsync=0 --group_reporting --direct=1 --ioengine=libaio --time_based --invalidate=1 --norandommap --randrepeat=0 --exitall --name=123 --filename=/dev/sdb >> $PWD/fio-log.log &
}

#main
flag_plug=1;
j=0;
i=0;
DEV_name_out_temp_1=1;
DEV_name_out_temp_2=1;
DEV_name_in_temp_1=1;
DEV_name_in_temp_2=1;
generate_baseline;
echo "Baseline is generated successfully!"
while :;
do
#plug_out_test
Temp_out=$(tail -n 5 /var/log/messages|grep -i "Stopping disk");
if [ -n "$Temp_out" ] && [ "$flag_plug"x = 1x ]; then
plug_out;
DEV_name_out_temp_2=$DEV_name_out_temp_1;
DEV_name_out_temp_1=$DEV_name_out;
if [ "$DEV_name_out"x = "$DEV_name_out_temp_2"x ]; then
j=$(expr $j + 1);
echo -e "This is \033[44;37;5m $j \033[0m times";
else
j=1;
echo -e "This is \033[44;37;5m $j \033[0m times"
fi
continue;
fi

#plug_in_test
Temp_in=$(tail -n 1 /var/log/messages|grep -i "Attached SCSI disk");
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
