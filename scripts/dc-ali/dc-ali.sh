#!/bin/bash
sleep 5
ROOT_DIR=$PWD;
LOG_NAME=$ROOT_DIR/log.log;

function get_base()
{
echo "Below is the base information of this machine" >> $LOG_NAME

#Disk information,including HDD/SSD & NVME & Aliflash
echo "####################" >> $LOG_NAME
fdisk -l |grep "^Disk./dev/sd"|sort >> $ROOT_DIR/hdd-name.txt
HDD_NUM=`cat $ROOT_DIR/hdd-name.txt|wc -l`
echo "There are $HDD_NUM HDD/SSD" >> $LOG_NAME
echo "The information of those HDDs is showing below:" >> $LOG_NAME
while read line
do
DISK_NAME=`echo $line |awk '{print $2}'|awk -F ':' '{print $1}'`
echo $DISK_NAME >> $LOG_NAME
smartctl -a $DISK_NAME|grep Model >> $LOG_NAME
smartctl -a $DISK_NAME|grep Model >> $ROOT_DIR/hdd-model.txt
smartctl -a $DISK_NAME|grep Serial >> $LOG_NAME
smartctl -a $DISK_NAME|grep Serial >> $ROOT_DIR/hdd-serial.txt
smartctl -a $DISK_NAME|grep Capacity >> $LOG_NAME
smartctl -a $DISK_NAME|grep Capacity >> $ROOT_DIR/hdd-size.txt
done < $ROOT_DIR/hdd-name.txt

echo "####################" >> $LOG_NAME
fdisk -l |grep "^Disk./dev/nvme"|sort >> $ROOT_DIR/nvme-name.txt
NVME_NUM=`cat $ROOT_DIR/nvme-name.txt|wc -l`
echo "There are $NVME_NUM NVME" >> $LOG_NAME
if [ $NVME_NUM = 0 ];then
rm -rf $ROOT_DIR/nvme-name.txt
else
echo "The information of those NVMEs is showing below:" >> $LOG_NAME
while read line
do
line1=`echo $line |awk '{print $2}'|awk -F ':' '{print $1}'`
echo "Model:" >> $LOG_NAME
nvme_id_ctrl $line1|grep mn|awk -F ':' '{print $2}' >> $LOG_NAME
nvme_id_ctrl $line1|grep mn|awk -F ':' '{print $2}' >> $ROOT_DIR/nvme-model.txt
echo "Serial:" >> $LOG_NAME
nvme_id_ctrl $line1|grep sn|awk -F ':' '{print $2}' >> $LOG_NAME
nvme_id_ctrl $line1|grep sn|awk -F ':' '{print $2}' >> $ROOT_DIR/nvme-serial.txt
echo "Firmware:" >> $LOG_NAME
nvme_id_ctrl $line1|grep "fr"|grep -v "frmw"|awk '{print $3}' >> $LOG_NAME
nvme_id_ctrl $line1|grep "fr"|grep -v "frmw"|awk '{print $3}' >> $ROOT_DIR/nvme-firmware.txt
echo "Size:" >> $LOG_NAME
fdisk -l |grep "$line1"|grep "^Disk"|awk '{print $3,$4}' >> $LOG_NAME
fdisk -l |grep "$line1"|grep "^Disk"|awk '{print $3,$4}' >> $ROOT_DIR/nvme-size.txt
done < $ROOT_DIR/nvme-name.txt
fi

echo "####################" >> $LOG_NAME
fdisk -l |grep "^Disk./dev/df"|sort >> $ROOT_DIR/aliflash-name.txt
ALIFLASH_NUM=`cat $ROOT_DIR/aliflash-name.txt|wc -l`
echo "There are $ALIFLASH_NUM ALIFLASH" >> $LOG_NAME
if [ $ALIFLASH_NUM = 0 ];then
rm -rf $ROOT_DIR/aliflash-name.txt
else
echo "The information of those Aliflashs is showing below:" >> $LOG_NAME
while read line
do
line1=`echo $line |awk '{print $2}'|awk -F ':' '{print $1}'`
echo "Model:" >> $LOG_NAME
aliflash-status -a|grep "Product Model"|awk '{print $3,$4,$5,$6,$7}' >> $LOG_NAME
aliflash-status -a|grep "Product Model"|awk '{print $3,$4,$5,$6,$7}' >> $ROOT_DIR/aliflash-model.txt
echo "Serial:" >> $LOG_NAME
aliflash-status -a|grep "Serial Number"|awk '{print $3}' >> $LOG_NAME
aliflash-status -a|grep "Serial Number"|awk '{print $3}' >> $ROOT_DIR/aliflash-serial.txt
echo "Firmware:" >> $LOG_NAME
aliflash-status -a|grep "Firmware Build"|awk '{print $3}' >> $LOG_NAME
aliflash-status -a|grep "Firmware Build"|awk '{print $3}' >> $ROOT_DIR/aliflash-firmware.txt
echo "Size:" >> $LOG_NAME
aliflash-status -a |grep "Disk Capacity"|awk '{print $3,$4}'>> $LOG_NAME
aliflash-status -a |grep "Disk Capacity"|awk '{print $3,$4}'>> $ROOT_NAME/aliflash-size.txt
done < $ROOT_DIR/aliflash-name.txt
fi

#Memory information,including PartNumber && Manufacturer & Size
echo "####################" >> $LOG_NAME
echo "Below is the Memory information" >> $LOG_NAME
echo "PartNumber:" >> $LOG_NAME
dmidecode -t memory|grep 'Part Number'|sort|uniq|grep -v 'NO DIMM'|awk '{print $3}' >> $LOG_NAME
dmidecode -t memory|grep 'Part Number'|sort|uniq|grep -v 'NO DIMM'|awk '{print $3}' >> $ROOT_DIR/mem-partnumber.txt
echo "Manufacturer:" >> $LOG_NAME
dmidecode -t memory|grep Manufacturer|sort|uniq|grep -v 'NO DIMM'|awk '{print $2}' >> $LOG_NAME
dmidecode -t memory|grep Manufacturer|sort|uniq|grep -v 'NO DIMM'|awk '{print $2}' >> $ROOT_DIR/mem-manufacturer.txt
echo "Size:" >> $LOG_NAME
dmidecode -t memory|grep Size|sort|uniq|grep -v 'NO DIMM'|grep -v "No Module Installed"|awk '{print $2,$3}' >> $LOG_NAME
dmidecode -t memory|grep Size|sort|uniq|grep -v 'NO DIMM'|grep -v "No Module Installed"|awk '{print $2,$3}' >> $ROOT_DIR/mem-size.txt
echo "Number:" >> $LOG_NAME
dmidecode -t memory|grep -i size|grep -v "No Module Installed"|wc -l >> $LOG_NAME
dmidecode -t memory|grep -i size|grep -v "No Module Installed"|wc -l >> $ROOT_DIR/mem-num.txt

#CPU information,including CPU Number & CPU CoreNumber & CPU Speed
echo "####################" >> $LOG_NAME
echo "Below is the CPU information" >> $LOG_NAME
echo "Model:" >> $LOG_NAME
cat /proc/cpuinfo |grep 'model name'|sort|uniq|awk -F ':' '{print $2}'>> $LOG_NAME
cat /proc/cpuinfo |grep 'model name'|sort|uniq|awk -F ':' '{print $2}'>> $ROOT_DIR/cpu-model.txt
echo "CPU Number:" >> $LOG_NAME
dmidecode -t processor | grep "Version"|wc -l >> $LOG_NAME
dmidecode -t processor | grep "Version"|wc -l >> $ROOT_DIR/cpu-number.txt
echo "CPU Core Number:" >> $LOG_NAME
cat /proc/cpuinfo |grep 'model name'|wc -l >> $LOG_NAME
cat /proc/cpuinfo |grep 'model name'|wc -l >> $ROOT_DIR/cpu-corenum.txt
echo "Speed:" >> $LOG_NAME
dmidecode -t processor|grep 'Current Speed'|sort|uniq|awk -F ':' '{print $2}' >> $LOG_NAME
dmidecode -t processor|grep 'Current Speed'|sort|uniq|awk -F ':' '{print $2}' >> $ROOT_DIR/cpu-speed.txt
}

echo 1 > $ROOT_DIR/count
get_base
echo "sh $ROOT_DIR/compare.sh &" >> /etc/rc.d/rc.local
sed -i 's#$PWD#'$ROOT_DIR'#g' $ROOT_DIR/compare.sh
sleep 10
reboot
