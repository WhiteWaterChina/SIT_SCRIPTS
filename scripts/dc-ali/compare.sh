#!/bin/bash
sleep 60
ROOT_DIR=$PWD;
LOG_NAME=$ROOT_DIR/log.log
i=`cat $ROOT_DIR/count`
function get_base()
{
#echo "Below is the base information of this machine" >> $LOG_NAME
#Disk information,including HDD/SSD & NVME & Aliflash
#echo "####################" >> $LOG_NAME
fdisk -l |grep "^Disk./dev/sd"|sort >> $ROOT_DIR/temp-hdd-name.txt
HDD_NUM=`cat $ROOT_DIR/temp-hdd-name.txt|wc -l`
#echo "There are $HDD_NUM HDD/SSD" >> $LOG_NAME
#echo "The information of those HDDs is showing below:" >> $LOG_NAME
while read line
do
DISK_NAME=`echo $line |awk '{print $2}'|awk -F ':' '{print $1}'`
#echo $DISK_NAME >> $LOG_NAME
#smartctl -a $DISK_NAME|grep Model >> $LOG_NAME
smartctl -a $DISK_NAME|grep Model >> $ROOT_DIR/temp-hdd-model.txt
#smartctl -a $DISK_NAME|grep Serial >> $LOG_NAME
smartctl -a $DISK_NAME|grep Serial >> $ROOT_DIR/temp-hdd-serial.txt
#smartctl -a $DISK_NAME|grep Capacity >> $LOG_NAME
smartctl -a $DISK_NAME|grep Capacity >> $ROOT_DIR/temp-hdd-size.txt
done < $ROOT_DIR/temp-hdd-name.txt

#echo "####################" >> $LOG_NAME
fdisk -l |grep "^Disk./dev/nvme"|sort >> $ROOT_DIR/temp-nvme-name.txt
NVME_NUM=`cat $ROOT_DIR/temp-nvme-name.txt|wc -l`
#echo "There are $NVME_NUM NVME" >> $LOG_NAME
if [ $NVME_NUM = 0 ];then
rm -rf $ROOT_DIR/temp-nvme-name.txt
else
#echo "The information of those NVMEs is showing below:" >> $LOG_NAME
while read line
do
line2=`echo $line |awk '{print $2}'|awk -F ':' '{print $1}'`;
#echo $line2
#nvme_id_ctrl $line|grep mn|awk -F ':' '{print $2}' >> $LOG_NAME
/usr/local/sbin/nvme_id_ctrl $line2 |grep mn|awk -F ':' '{print $2}' >> $ROOT_DIR/temp-nvme-model.txt;
#nvme_id_ctrl $line|grep sn|awk -F ':' '{print $2}' >> $LOG_NAME
/usr/local/sbin/nvme_id_ctrl $line2 |grep sn|awk -F ':' '{print $2}' >> $ROOT_DIR/temp-nvme-serial.txt;
#nvme_id_ctol $line1|grep "fr"|grep -v "frmw"|awk '{print $3}' >> $LOG_NAME
/usr/local/sbin/nvme_id_ctrl $line2 |grep fr|grep -v 'frmw'|awk '{print $3}' >> $ROOT_DIR/temp-nvme-firmware.txt;
#fdisk -l |grep "^Disk./dev/nvme"|sort|awk '{print $3,$4}' >> $LOG_NAME
fdisk -l |grep $line2|grep "^Disk"|awk '{print $3,$4}' >> $ROOT_DIR/temp-nvme-size.txt;
done < $ROOT_DIR/temp-nvme-name.txt
fi

#echo "####################" >> $LOG_NAME
fdisk -l |grep "^Disk./dev/df"|sort >> $ROOT_DIR/temp-aliflash-name.txt
ALIFLASH_NUM=`cat $ROOT_DIR/temp-aliflash-name.txt|wc -l`
#echo "There are $ALIFLASH_NUM ALIFLASH" >> $LOG_NAME
if [ $ALIFLASH_NUM = 0 ];then
rm -rf $ROOT_DIR/temp-aliflash-name.txt
else
while read line
do
line1=`echo $line |awk '{print $2}'|awk -F ':' '{print $1}'`
#echo "Model:" >> $LOG_NAME
#aliflash-status -a|grep "Product Model"|awk '{print $3,$4,$5,$6,$7}' >> $LOG_NAME
aliflash-status -a|grep "Product Model"|awk '{print $3,$4,$5,$6,$7}' >> $ROOT_DIR/temp-aliflash-model.txt
#echo "Serial:" >> $LOG_NAME
#aliflash-status -a|grep "Serial Number"|awk '{print $3}' >> $LOG_NAME
aliflash-status -a|grep "Serial Number"|awk '{print $3}' >> $ROOT_DIR/temp-aliflash-serial.txt
#echo "Firmware:" >> $LOG_NAME
#aliflash-status -a|grep "Firmware Build"|awk '{print $3}' >> $LOG_NAME
aliflash-status -a|grep "Firmware Build"|awk '{print $3}' >> $ROOT_DIR/temp-aliflash-firmware.txt
#echo "Size:" >> $LOG_NAME
#aliflash-status -a |grep "Disk Capacity"|awk '{print $3,$4}'>> $LOG_NAME
aliflash-status -a |grep "Disk Capacity"|awk '{print $3,$4}'>> $ROOT_NAME/temp-aliflash-size.txt
done < $ROOT_DIR/temp-aliflash-name.txt
fi


#Memory information,including PartNumber && Manufacturer & Size
#echo "********************" >> $LOG_NAME
#echo "Below is the Memory information" >> $LOG_NAME
#echo "PartNumber:" >> $LOG_NAME
#dmidecode -t memory|grep 'Part Number'|sort|uniq|grep -v 'NO DIMM'|awk '{print $3}' >> $LOG_NAME
dmidecode -t memory|grep 'Part Number'|sort|uniq|grep -v 'NO DIMM'|awk '{print $3}' >> $ROOT_DIR/temp-mem-partnumber.txt
#echo "Manufacturer:" >> $LOG_NAME
#dmidecode -t memory|grep Manufacturer|sort|uniq|grep -v 'NO DIMM'|awk '{print $2}' >> $LOG_NAME
dmidecode -t memory|grep Manufacturer|sort|uniq|grep -v 'NO DIMM'|awk '{print $2}' >> $ROOT_DIR/temp-mem-manufacturer.txt
#echo "Size:" >> $LOG_NAME
#dmidecode -t memory|grep Size|sort|uniq|grep -v 'NO DIMM'|grep -v "No Module Installed"|awk '{print $2,$3}' >> $LOG_NAME
dmidecode -t memory|grep Size|sort|uniq|grep -v 'NO DIMM'|grep -v "No Module Installed"|awk '{print $2,$3}' >> $ROOT_DIR/temp-mem-size.txt
#echo "Number:" >> $LOG_NAME
#dmidecode -t memory|grep -i size|grep -v "No Module Installed"|wc -l >> $LOG_NAME
dmidecode -t memory|grep -i size|grep -v "No Module Installed"|wc -l >> $ROOT_DIR/temp-mem-num.txt

#CPU information,including CPU Number & CPU CoreNumber & CPU Speed
#echo "********************" >> $LOG_NAM
#echo "Below is the CPU information" >> $LOG_NAME
#echo "Model:" >> $LOG_NAME
#cat /proc/cpuinfo |grep 'model name'|sort|uniq|awk -F ':' '{print $2}'>> $LOG_NAME
cat /proc/cpuinfo |grep 'model name'|sort|uniq|awk -F ':' '{print $2}'>> $ROOT_DIR/temp-cpu-model.txt
#echo "CPU Number:" >> $LOG_NAME
#dmidecode -t processor | grep "Version"|wc -l >> $LOG_NAME
dmidecode -t processor | grep "Version"|wc -l >> $ROOT_DIR/temp-cpu-number.txt
#echo "CPU Core Number:" >> $LOG_NAME
#cat /proc/cpuinfo |grep 'model name'|wc -l >> $LOG_NAME
cat /proc/cpuinfo |grep 'model name'|wc -l >> $ROOT_DIR/temp-cpu-corenum.txt
#echo "Speed:" >> $LOG_NAME
#dmidecode -t processor|grep 'Current Speed'|sort|uniq|awk -F ':' '{print $2}' >> $LOG_NAME
dmidecode -t processor|grep 'Current Speed'|sort|uniq|awk -F ':' '{print $2}' >> $ROOT_DIR/temp-cpu-speed.txt
}

function compare_base()
{
diff $ROOT_DIR/temp-hdd-model.txt $ROOT_DIR/hdd-model.txt >/dev/null
if [ ! $? -eq 0 ]; then
echo "HDD/SSD Model test ERROR!" >> $LOG_NAME
cat $ROOT_DIR/temp-hdd-model.txt >> $LOG_NAME
else
echo "HDD/SSD Model test OK!" >> $LOG_NAME
fi

diff $ROOT_DIR/temp-hdd-serial.txt $ROOT_DIR/hdd-serial.txt >/dev/null
if [ ! $? -eq 0 ];then
echo "HDD/SSD Serial test ERROR!" >> $LOG_NAME
cat  $ROOT_DIR/temp-hdd-serial.txt >> $LOG_NAME
else
echo "HDD/SSD Serial test OK!" >> $LOG_NAME
fi

diff $ROOT_DIR/temp-hdd-size.txt $ROOT_DIR/hdd-size.txt >/dev/null
if [ ! $? -eq 0 ];then
echo "HDD/SSD Size test ERROR!" >> $LOG_NAME
cat $ROOT_DIR/temp-hdd-size.txt >> $LOG_NAME
else
echo "HDD/SSD Size test OK!" >> $LOG_NAME
fi

if [ -f "$ROOT_DIR/nvme-name.txt" ];then
diff $ROOT_DIR/temp-nvme-name.txt $ROOT_DIR/nvme-name.txt >/dev/null
if [ ! $? -eq 0 ];then
echo "NVME Name test ERROR!" >> $LOG_NAME
cat $ROOT_DIR/temp-nvme-name.txt >> $LOG_NAME
else
echo "NVME Name test OK!" >> $LOG_NAME
fi
diff $ROOT_DIR/temp-nvme-model.txt $ROOT_DIR/nvme-model.txt >/dev/null
if [ ! $? -eq 0 ];then
echo "NVME Model ERROR!" >> $LOG_NAME
cat $ROOT_DIR/temp-nvme-model.txt >> $LOG_NAME
else
echo "NVME Model OK!" >> $LOG_NAME
fi
diff $ROOT_DIR/temp-nvme-serial.txt $ROOT_DIR/nvme-serial.txt >/dev/null
if [ ! $? -eq 0 ];then
echo "NVME Serial ERROR!" >> $LOG_NAME
cat $ROOT_DIR/temp-nvme-serial.txt >> $LOG_NAME
else
echo "NVME Serial OK!" >> $LOG_NAME
fi
diff $ROOT_DIR/temp-nvme-size.txt $ROOT_DIR/nvme-size.txt >/dev/null
if [ ! $? -eq 0 ];then
echo "NVME Size ERROR!" >> $LOG_NAME
cat $ROOT_DIR/temp-nvme-size.txt >> $LOG_NAME
else
echo "NVME Size OK!" >> $LOG_NAME
fi
diff $ROOT_DIR/temp-nvme-firmware.txt $ROOT_DIR/nvme-firmware.txt >/dev/null
if [ ! $? -eq 0 ];then
echo "NVME Firmware ERROR!" >> $LOG_NAME
cat $ROOT_DIR/temp-nvme-firmware.txt >> $LOG_NAME
else
echo "NVME Firmware OK!" >> $LOG_NAME
fi
fi

if [ -f "$ROOT_DIR/aliflash-name.txt" ];then
diff $ROOT_DIR/temp-aliflash-name.txt $ROOT_DIR/aliflash-name.txt >/dev/null
if [ ! $? -eq 0 ];then
echo "Aliflash Name test ERROR!" >> $LOG_NAME
cat $ROOT_DIR/temp-aliflash-name.txt >> $LOG_NAME
else
echo "Aliflash Name test OK!" >> $LOG_NAME
fi
diff $ROOT_DIR/temp-aliflash-model.txt $ROOT_DIR/aliflash-model.txt >/dev/null
if [ ! $? -eq 0 ];then
echo "Aliflash Model ERROR!" >> $LOG_NAME
cat $ROOT_DIR/temp-aliflash-model.txt >> $LOG_NAME
else
echo "Aliflash Model OK!" >> $LOG_NAME
fi
diff $ROOT_DIR/temp-aliflash-serial.txt $ROOT_DIR/aliflash-serial.txt >/dev/null
if [ ! $? -eq 0 ];then
echo "Aliflash Serial ERROR!" >> $LOG_NAME
cat $ROOT_DIR/temp-aliflash-serial.txt >> $LOG_NAME
else
echo "Aliflash Serial OK!" >> $LOG_NAME
fi
diff $ROOT_DIR/temp-aliflash-size.txt $ROOT_DIR/aliflash-size.txt >/dev/null
if [ ! $? -eq 0 ];then
echo "Aliflash Size ERROR!" >> $LOG_NAME
cat $ROOT_DIR/temp-aliflash-size.txt >> $LOG_NAME
else
echo "Aliflash Size OK!" >> $LOG_NAME
fi
diff $ROOT_DIR/temp-aliflash-firmware.txt $ROOT_DIR/aliflash-firmware.txt >/dev/null
if [ ! $? -eq 0 ];then
echo "Aliflash Firmware ERROR!" >> $LOG_NAME
cat $ROOT_DIR/temp-aliflash-firmware.txt >> $LOG_NAME
else
echo "Aliflash Firmware OK!" >> $LOG_NAME
fi
fi



diff $ROOT_DIR/temp-mem-partnumber.txt $ROOT_DIR/mem-partnumber.txt >/dev/null
if [ ! $? -eq 0 ];then
echo "Memory ParNumber ERROR!" >> $LOG_NAME
cat $ROOT_DIR/temp-mem-partnumber.txt >> $LOG_NAME
else
echo "Memory ParNumber OK!" >> $LOG_NAME
fi
diff $ROOT_DIR/temp-mem-manufacturer.txt $ROOT_DIR/mem-manufacturer.txt >/dev/null
if [ ! $? -eq 0 ];then
echo "Memory Manufacturer ERROR!" >> $LOG_NAME
cat $ROOT_DIR/temp-mem-manufacturer.txt >> $LOG_NAME
else
echo "Memory Manufacturer OK!" >> $LOG_NAME
fi
diff $ROOT_DIR/temp-mem-size.txt $ROOT_DIR/mem-size.txt >/dev/null
if [ ! $? -eq 0 ];then
echo "Memory Size ERROR!" >> $LOG_NAME
cat $ROOT_DIR/temp-mem-size.txt >> $LOG_NAME
else
echo "Memory Size OK!" >> $LOG_NAME
fi
diff $ROOT_DIR/temp-mem-num.txt $ROOT_DIR/mem-num.txt >/dev/null 
if [ ! $? -eq 0 ];then
echo "Memory Number ERROR!" >> $LOG_NAME
cat $ROOT_DIR/temp-mem-num.txt >> $LOG_NAME
else
echo "Memory Number OK!" >> $LOG_NAME
fi

diff $ROOT_DIR/temp-cpu-model.txt $ROOT_DIR/cpu-model.txt >/dev/null
if [ ! $? -eq 0 ];then
echo "CPU Model ER
ROR!" >> $LOG_NAME
cat $ROOT_DIR/temp-cpu-model.txt >> $LOG_NAME
else
echo "CPU Model OK!" >> $LOG_NAME
fi
diff $ROOT_DIR/temp-cpu-number.txt $ROOT_DIR/cpu-number.txt >/dev/null
if [ ! $? -eq 0 ];then
echo "CPU Number ERROR!" >> $LOG_NAME
cat $ROOT_DIR/temp-cpu-number.txt >> $LOG_NAME
else
echo "CPU Number OK!" >> $LOG_NAME
fi
diff $ROOT_DIR/temp-cpu-corenum.txt $ROOT_DIR/cpu-corenum.txt >/dev/null
if [ ! $? -eq 0 ];then
echo "CPU Core Number ERROR!" >> $LOG_NAME
cat $ROOT_DIR/temp-cpu-corenumber.txt >> $LOG_NAME
else
echo "CPU Core Number OK!" >> $LOG_NAME
fi
diff $ROOT_DIR/temp-cpu-speed.txt $ROOT_DIR/cpu-speed.txt >/dev/null
if [ ! $? -eq 0 ];then
echo "CPU Speed ERROR!" >> $LOG_NAME
cat $ROOT_DIR/temp-cpu-speed.txt >> $LOG_NAME
else
echo "CPU Speed OK!" >> $LOG_NAME
fi

}


#main
echo "####################" >> $LOG_NAME
echo "This is $i times reboot/halt" >> $LOG_NAME
date >> $LOG_NAME
get_base
compare_base
rm -rf $ROOT_DIR/temp-*
i=`echo $i +1|bc`
echo "$i" > $ROOT_DIR/count
reboot
