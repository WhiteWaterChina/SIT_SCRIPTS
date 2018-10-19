#!/bin/bash
for Order1 in {a..g}
do
smartctl -a /dev/sd$Order1 |grep -i "serial number"|awk '{print $3}' >> /root/order/base_one.txt
done

for Order2 in {h..n}
do
smartctl -a /dev/sd$Order2 |grep -i "serial number"|awk '{print $3}' >> /root/order/base_two.txt
done

for Order3 in {o..x}
do
smartctl -a /dev/sd$Order2 |grep -i "serial number"|awk '{print $3}' >> /root/order/base_three.txt
done

echo "sh /root/order/compare.sh &" >> /etc/rc.local
echo 1 > /root/count
reboot
