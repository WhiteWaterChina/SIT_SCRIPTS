#!/bin/bash
Times=`cat /root/count`
sleep 45
echo "This is $Times times test!" >> /root/order/log
cd /root/order/
rm -rf temp_*
for Order1 in {a..g}
do
smartctl -a /dev/sd$Order1 |grep -i "serial number"|awk '{print $3}' >> /root/order/temp_one.txt
done

for Order2 in {h..n}
do
smartctl -a /dev/sd$Order2 |grep -i "serial number"|awk '{print $3}' >> /root/order/temp_two.txt
done

for Order3 in {o..x}
do
smartctl -a /dev/sd$Order2 |grep -i "serial number"|awk '{print $3}' >> /root/order/temp_three.txt
done
#compare one
while read line
do
    Temp_name=`echo $line`
    Dev_name=`cat base_one.txt|grep $Temp_name`
    if [ -z  "$Dev_name" ] ; then
      echo "Error" >> /root/order/log
      sleep 2
      echo "error one"
      Times=`echo $Times +1|bc`
      echo $Times > /root/count
      reboot
    fi
    
done < temp_one.txt

#compare two
while read line
do
    Temp_name=`echo $line`
    Dev_name=`cat base_two.txt|grep $Temp_name`
    if [ -z "$Dev_name" ] ; then
      echo "Error" >> /root/order/log
      sleep 2
      echo "error two"
      Times=`echo $Times +1|bc`
      echo $Times > /root/count
      reboot
    fi
    
done < temp_two.txt

#compare three
while read line
do
    Temp_name=`echo $line`
    Dev_name=`cat base_three.txt|grep $Temp_name`
    if [ -z "$Dev_name" ] ; then
      echo "Error" >> /root/order/log
      sleep 2
      echo "error three"
      Times=`echo $Times +1|bc`
      echo $Times > /root/count
      reboot
    fi
    
done < temp_three.txt

echo "OK" >> /root/order/log
Times=`echo $Times +1|bc`
echo $Times > /root/count
