#!/bin/bash
Times=`cat /root/count`
sleep 45
echo "This is $Times times test!" >> /root/shunxu.log
rm -rf /root/serial-temp.csv
while read line
do
echo $line >> /root/shunxu.log
smartctl -a $line|grep "Serial" | awk '{print $3}' >> /root/serial-temp.csv
smartctl -a $line|grep "Serial" | awk '{print $3}' >> /root/shunxu.log
done < /root/order-disk.csv 
diff /root/serial-temp.csv /root/serial-all.csv

if [ ! $? -eq 0 ]
then
echo "error" >>/root/shunxu.log
else
echo "OK" >>/root/shunxu.log
fi

Times=`echo $Times +1|bc`
echo $Times >/root/count
sleep 10

reboot
