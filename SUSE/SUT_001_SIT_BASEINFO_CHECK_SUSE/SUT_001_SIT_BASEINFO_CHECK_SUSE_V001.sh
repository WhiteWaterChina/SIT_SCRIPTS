#!/bin/bash
###############################
#Name:SUT_001_SIT_BASEINFO_CHECK_SUSE
#Author:yanshuo
#Revision:
#Version:V001
#Date:2017-12-18
#Tracelist:V001-->First Version
#Function: get base info under suse
#No parameter!
#Usage:sh SUT_001_SIT_BASEINFO_CHECK_SUSE_Vxxx.sh
#
###############################

#check and create log dir
[ ! -d log ] && mkdir log
#create log file
time_start=`date +%Y%m%d%H%M%S`
log_file_name="${time_start}_SIT_BASEINFO_CHECK_SUSE.log"
current_path=`pwd`
log_path="${current_path}/log/${log_file_name}"
touch "${log_path}"
# write  start time
echo "Start Testing Time!" >> ${log_path}
echo ${time_start} >> ${log_path}

#OS info
#show info to screen
echo -e "\033[32mBelow is the OS Version! \033[0m"
main_ver=`cat /etc/SuSE-release |awk '{match($0,/VERSION = ([0-9]+)/,a);print a[1]}'|sed 's/ //g'`
patch_ver=`cat /etc/SuSE-release |awk '{match($0,/PATCHLEVEL = ([0-9]+)/,a);print a[1]}'|sed 's/ //g'`
os_ver="${main_ver}.${patch_ver}"
echo $os_ver
echo -e "\033[32mBelow is the OS Kernel! \033[0m"
echo `uname -r|awk '{match($0,/(([0-9]+\.)*[0-9]+-([0-9]+\.)*[0-9]+)/,a);print a[1]}'`
#write info to log file
echo "Below is the OS Version!" >> ${log_path}
echo $os_ver >> ${log_path}
echo "Below is the OS Kernel!" >> ${log_path}
uname -r|awk '{match($0,/(([0-9]+\.)*[0-9]+-([0-9]+\.)*[0-9]+)/,a);print a[1]}' >> ${log_path}

#CPU info
#show info to screen
cpu_number=`cat /proc/cpuinfo |grep "physical id"|sort|uniq -c|wc -l`
cpu_model=`cat /proc/cpuinfo |grep "model name"|sort|uniq -c|awk -F ':' '{print $2}'`
cpu_threads=`cat /proc/cpuinfo |grep "physical id"|sort|uniq -c|awk '{print $1}'`

echo -e "\033[32mBelow is the CPU Number! \033[0m"
echo $cpu_number
echo -e "\033[32mBelow is the CPU Model! \033[0m"
echo $cpu_model
echo -e "\033[32mBelow is the threads number of each CPU! \033[0m"
#write info to log file
echo "Below is the CPU Number!" >> ${log_path}
echo $cpu_number >> ${log_path}
echo "Below is the CPU Model!" >> ${log_path}
echo $cpu_model >> ${log_path}
echo "Below is the threads number of each CPU!" >> ${log_path}
for item_cpu in ${cpu_threads[@]}
do
echo $item_cpu
echo $item_cpu >> ${log_path}
done

#Mem info
#show info to screen
echo -e "\033[32mBelow is the total MEM size! \033[0m"
echo `dmesg |grep Memory|awk '{match($0,/\/(\w*).*?available/,a);print a[1]}'`
#write info to log file
echo "Below is the total MEM size!" >> ${log_path}
echo `dmesg |grep Memory|awk '{match($0,/\/(\w*).*?available/,a);print a[1]}'` >> ${log_path}

#HBA
echo "Below is the HBA info!" >> ${log_path}
find /sys -name port_name|grep -v -i permission|grep -e '/fc_host/host[0-9]*/port_name' > /dev/null
if [ $? != 0 ]; then
echo -e "\033[31mThere is no HBA in this machine!Skip this check! \033[0m"
echo "There is no HBA in this machine!Skip this check!" >> ${log_path}
else
echo -e "\033[32mBelow is the WWN of HBA! \033[0m"
echo "Below is the WWN of HBA!" >> ${log_path}
hba_info=`find /sys -name port_name|grep -v -i permission|grep -e '/fc_host/host[0-9]*/port_name'`
for item in ${hba_info[@]}
do
#show wwn to screen!
cat $item
#write wwn to log file!
cat $item >> ${log_path}
done
fi

#network
#show info to the screen
echo -e "\033[32mBelow is the network info! \033[0m"
echo "Below is the network info!" >> ${log_path}
echo -e "\033[32mBelow is the network name! \033[0m"
echo "Below is the network name!" >> ${log_path}
net_name=`ifconfig -a|sed -nr 's/^(\S+).*/\1/p'|grep -v "lo"|grep -v "virbr"|grep -v br|awk -F ":" '{print $1}'`
for item_netname in ${net_name[@]}
do
echo $item_netname
echo $item_netname >> ${log_path}
done

echo -e "\033[32mBelow is the MAC Address! \033[0m"
echo "Below is the MAC Address!" >> ${log_path}
for name in ${net_name[@]}
do
mac_address=`ifconfig $name|grep '\w\w:\w\w:\w\w:\w\w:\w\w:\w\w'|awk '{match($0,/(\w\w:\w\w:\w\w:\w\w:\w\w:\w\w)/,a);print a[1]}'`
echo $mac_address
echo $mac_address >> ${log_path}
done

#disk info
#lsscsi output
echo -e "\033[32mBelow is the Disk info from lsscsi! \033[0m"
echo "Below is the Disk info from lsscsi!" >> ${log_path}
lsscsi
lsscsi >> ${log_path}
#info from fdisk -l
echo -e "\033[32mBelow is the Disk info from fdisk -l! \033[0m"
echo "Below is the Disk info from fdisk -l!" >> ${log_path}
fdisk -l|grep '^Disk /dev/'|sort|grep -v loop|grep -v ram
fdisk -l|grep '^Disk /dev/'|sort|grep -v loop|grep -v ram >> ${log_path}
chmod 777 tool/nvme_id_ctrl
#smart info
filter_disk=`fdisk -l|grep '^Disk /dev/'|sort|grep -v loop|grep -v ram|awk '{print $2}'|awk -F ":" '{print $1}'`
echo -e "\033[32mBelow is the model/sn/firmware/size info for every disk!\033[0m"
echo "Below is the model/sn/firmware/size info for every disk!" >> ${log_path}
for item_disk in ${filter_disk[@]}
do
disk_info=`echo ${item_disk}|awk -F "/" '{print $3}'|awk '{match($0,/(nvme)/,a);print a[1]}'`
echo -e "\033[32mBelow is the  model/sn/firmware/size info for\033[0m \033[31m${item_disk} \033[0m"
echo "Below is the  model/sn/firmware/size info for ${item_disk}" >> ${log_path}
if [[ ${disk_info} == "nvme" ]]; then
model_write=`./tool/nvme_id_ctrl ${item_disk}|grep mn|awk -F ":" '{print $2}'|sed 's/^\s*//g'`
sn_write=`./tool/nvme_id_ctrl ${item_disk}|grep sn|awk -F ":" '{print $2}'|sed 's/^\s*//g'`
firmware_write=`./tool/nvme_id_ctrl ${item_disk}|grep fr|grep -v frmw|awk -F ":" '{print $2}'|sed 's/^\s*//g'`
size_write="Please find from fdisk -l output!"
else
model=`smartctl -a ${item_disk}|grep "Model"|awk -F ":" '{print $2}'|sed 's/^\s*//g'`
sn=`smartctl -a ${item_disk}|grep "Serial Number"|awk -F ":" '{print $2}'|sed 's/^\s*//g'`
firmware=`smartctl -a ${item_disk}|grep "Firmware"|awk -F ":" '{print $2}'|sed 's/^\s*//g'`
size=`smartctl -a ${item_disk}|grep "Capacity"|awk -F ":" '{print $2}'|sed 's/^\s*//g'`
if [ ${#model} == 0 ];then
model_write="None"
else
model_write=$model
fi
if [ ${#sn} == 0 ];then
sn_write="None"
else
sn_write=$sn
fi
if [ ${#firmware} == 0 ];then
firmware_write="None"
else
firmware_write=$firmware
fi
if [ ${#size} == 0 ];then
size_write="None"
else
size_write=$size
fi
fi
echo -e "\033[32mModel\033[0m:${model_write}"
echo -e "\033[32mSerial Number\033[0m:${sn_write}"
echo -e "\033[32mFirmware\033[0m:${firmware_write}"
echo -e "\033[32mSize\033[0m:${size_write}"
echo "Model:${model_write}" >> ${log_path}
echo "Serial Number:${sn_write}" >> ${log_path}
echo "Firmware:${firmware_write}" >> ${log_path}
echo "Size:${size_write}" >> ${log_path}
done

#ipmi info
#test ipmitool is installed or not
which ipmitool > /dev/null
if [ $? != 0 ]; then
echo -e "\033[31mipmitool is not installed! Please install ipmitool! \033[0m"
echo "ipmitool is not installed! Please  install ipmitool!" >> ${log_path}
exit 255
fi
if [ $main_ver == "12" ];then
systemctl restart ipmi.service >/dev/null 2>&1
elif [ $main_ver == "11" ]; then
/etc/init.d/ipmi restart >/dev/null 2>&1
fi
echo -e "\033[32mBelow is the BMC version! \033[0m"
echo "Below is the BMC version!" >> ${log_path}
bmc_version=`ipmitool mc info|grep "Firmware Revision"|awk -F ":" '{print $2}'`
echo $bmc_version
echo $bmc_version >> ${log_path}

#driver info
echo -e "\033[32mBelow is the Driver version info! \033[0m"
echo "Below is the Driver version info!" >> ${log_path}
echo -e "\033[32mBelow is the igb version \033[0m"
echo "Below is the igb version" >> ${log_path}
igb_version=`modinfo igb|grep ^version|awk -F ":" '{print $2}'`
echo $igb_version
echo $igb_version >> ${log_path}
echo -e "\033[32mBelow is the ixgbe version \033[0m"
echo "Below is the ixgbe version" >> ${log_path}
ixgbe_version=`modinfo ixgbe|grep ^version|awk -F ":" '{print $2}'`
echo $ixgbe_version
echo $ixgbe_version >> ${log_path}
echo -e "\033[32mBelow is the megaraid_sas version \033[0m"
echo "Below is the megaraid_sas version" >> ${log_path}
megaraid_sas_version=`modinfo megaraid_sas|grep ^version|awk '{print $2}'`
echo $megaraid_sas_version
echo $megaraid_sas_version >> ${log_path}
echo -e "\033[32mBelow is the mpt2sas version \033[0m"
echo "Below is the mpt2sas version" >> ${log_path}
mpt2sas_version=`modinfo mpt2sas|grep ^version|awk '{print $2}'`
echo $mpt2sas_version
echo $mpt2sas_version >> ${log_path}
echo -e "\033[32mBelow is the mpt3sas version \033[0m"
echo "Below is the mpt3sas version" >> ${log_path}
mpt3sas_version=`modinfo mpt3sas|grep ^version|awk '{print $2}'`
echo $mpt3sas_version
echo $mpt3sas_version >> ${log_path}
echo -e "\033[32mBelow is the aacraid version \033[0m"
echo "Below is the aacraid version" >> ${log_path}
aacraid_version=`modinfo aacraid|grep ^version|awk '{print $2}'`
echo $aacraid_version
echo $aacraid_version >> ${log_path}
echo -e "\033[32mBelow is the lpfc version \033[0m"
echo "Below is the lpfc version" >> ${log_path}
lpfc_version=`modinfo lpfc|grep ^version|awk '{print $2}'`
echo $lpfc_version
echo $lpfc_version >> ${log_path}
echo -e "\033[32mBelow is the qla2xxx version \033[0m"
echo "Below is the qla2xxx version" >> ${log_path}
qla2xxx_version=`modinfo qla2xxx|grep ^version|awk '{print $2}'`
echo $qla2xxx_version
echo $qla2xxx_version >> ${log_path}


echo -e "\033[32mBelow is the total lspci info! \033[0m"
echo -e "\033[32mBecause result is too long, only write them to log file! \033[0m"
echo "Below is the total lspci info!" >> ${log_path}
lspci >> ${log_path}
exit 0
