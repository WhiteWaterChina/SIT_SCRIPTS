#!/bin/bash
function get_disk_name()
{
fdisk -l | grep "^Disk./dev/sd"|sort > /root/tmp.txt
Num=`cat /root/tmp.txt|wc -l`
Dev_Name=""
while read line
do
Disk_Name=`echo $line | awk '{print $2}' | awk -F: '{print $1}'`
echo $line | awk '{print $2}' | awk -F: '{print $1}' >> /root/order-disk.csv
echo $Disk_Name
done < /root/tmp.txt
}
function get_serial()
{
while read line
do
smartctl -a $line|grep "Serial" | awk '{print $3}' >> /root/serial-all.csv
done < /root/order-disk.csv 
}
get_disk_name
get_serial
echo "sh $PWD/compare.sh &" >> /etc/rc.d/rc.local
echo 1 >/root/count
sleep 40
chmod 777 /etc/rc.d/rc.local
reboot
