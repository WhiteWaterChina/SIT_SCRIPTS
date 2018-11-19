#!/bin/bash
##############################
#Name:SUT_001_SIT_REBOOT_TEST_RHEL
#Author:Ward Yan
#Revision:
#Version:A01
#Date:2018-10-15
#Tracelist:A01-->First Version
#Function:reboot test under ubuntu
#Parameter_1:reboot type.only "reboot"or"dc"
#Parameter_2:total test seconds
#Parameter_3: max test loop
#Parameter_4: sleep time
#Parameter_5: upi switch(if check upi speed)
#Usage:bash SUT_001_SIT_REBOOT_TEST_RHEL_V001.sh Parameter_1 Parameter_2 Parameter_3　Parameter_4 Parameter_5
#Example:
#1.reboot  bash SUT_001_SIT_REBOOT_TEST_RHEL_V001.sh reboot 43200 500 40 upi
#2.dc/ac   bash SUT_001_SIT_REBOOT_TEST_RHEL_V001.sh dc 43200 500 40 upi
###############################


#check and create log dir
[ ! -d log ] && mkdir log
#create log file
time_start=`date +%Y%m%d%H%M%S`
log_dir_name="${time_start}_SIT_REBOOT_TEST_RHEL"
log_file_name="${time_start}_SIT_REBOOT_TEST_RHEL.log"
error_file_name="${time_start}_SIT_REBOOT_TEST_RHEL_ERROR.log"
current_path=`pwd`
log_path_dir="${current_path}/log/${log_dir_name}"
log_path="${current_path}/log/${log_dir_name}/${log_file_name}"
error_log_path="${current_path}/log/${log_dir_name}/${error_file_name}"
dmesg_log_path="${current_path}/log/${log_dir_name}/dmesg-log"

mkdir -p ${log_path_dir}
mkdir -p ${dmesg_log_path}
touch ${log_path}
# write  start time
echo "Start Testing Time!" >> ${log_path}
echo ${time_start} >> ${log_path}


#check input!Need:1.reboot type;2.total time;3.max loop;4.sleep time;
if [[ $# != 4 && $# != 5 && $# != 1 ]];then
    echo -e "\033[31mInput Error! Usage:$0 reboot_type(reboot/dc)/stop total_time(seconds)  max_loop sleep_time(seconds) upi(optional) \033[0m"
    echo "Input Error! Usage:$0 reboot_type(reboot/dc)/stop total_time(seconds)  max_loop sleep_time(seconds) upi(optional)" >> ${log_path}
    exit 255
else
  if [ $# == 4 ];then
    reboot_type=$1
    total_time=$2
    max_loop=$3
    sleep_time=$4
	upi_switch="0"
  elif [ $# == 5 ];then
    reboot_type=$1
    total_time=$2
    max_loop=$3
    sleep_time=$4
	upi_switch=$5
  elif [ $# == 1 ];then
    stop_ornot=$1
	if [ ${stop_ornot} == "stop" ];then
	  echo -e "\033[32mStop reboot test!Will reboot for another one time!\033[0m"
	  echo "Stop reboot test!Will reboot for another one time!" >> ${log_path}
      rm -rf /etc/rc.d/rc.local
	  rm -rf /home/log_path_dir.txt /home/reboot.sh
	  killall -9 sh
	  killall -9 sleep
	  exit 0
	else
	  echo -e "\033[31mInput Error! Usage:$0 reboot_type(reboot/dc)/stop total_time(seconds)  max_loop sleep_time(seconds) upi(optional) \033[0m"
      exit 255
	fi
  fi
fi

#write reboot type to a config file to use
echo ${reboot_type} > ${log_path_dir}/reboot_type.txt
#write total time to a config file to use
echo  ${total_time} > ${log_path_dir}/total_time.txt
#write max loop to a config file to use
echo ${max_loop} > ${log_path_dir}/max_loop.txt
#write sleep time to a config file to use
echo ${sleep_time} > ${log_path_dir}/sleep_time.txt
#write log path to a config file to use
echo ${log_path_dir} > /home/log_path_dir.txt
#write log file to a config file to use
echo ${log_file_name} > ${log_path_dir}/log_name.txt
#write log file name to a config file
echo ${error_file_name} > ${log_path_dir}/error_log_name.txt
#write dmesg log path
echo ${dmesg_log_path} > ${log_path_dir}/dmesg-log-path.txt

# check upi input
if [[ ${upi_switch} == "0" ]];then
  echo "No need to check UPI!" >> ${log_path}
  echo "0" > ${log_path_dir}/upiswitch.txt
else
  if [[ ${upi_switch} == "upi" || ${upi_switch} == "UPI" ]];then
    echo "Need to check UPI!" >> ${log_path}
	echo "1" > ${log_path_dir}/upiswitch.txt
  else
    echo -e "\033[31mInvalid input for UPI!\033[0m"
    echo "Invalid input for UPI!" >>${log_path}
	exit 255
  fi
fi
#generate base
function generate_base()
{
echo "Below is the base infomation!" >> ${log_path}
#cpu info
#show info to screen
cpu_number=`cat /proc/cpuinfo |grep "physical id"|sort|uniq -c|wc -l`
cpu_model=`cat /proc/cpuinfo |grep "model name"|sort|uniq -c|awk -F ':' '{print $2}'`
cpu_cores=`cat /proc/cpuinfo |grep "cpu cores"|sort|uniq -c|awk -F ':' '{print $2}'|sed s/[[:space:]]//g`
#cpu_threads=`cat /proc/cpuinfo |grep "physical id"|sort|uniq -c`

echo -e "\033[32mBelow is the CPU Number! \033[0m"
echo $cpu_number
echo -e "\033[32mBelow is the CPU Model! \033[0m"
echo $cpu_model

#write info to log file
echo "Below is the CPU Number!" >> ${log_path}
echo $cpu_number >> ${log_path}
echo "Below is the CPU Model!" >> ${log_path}
echo $cpu_model >> ${log_path}
rm -rf ${log_path_dir}/base_cpu_threads.txt
rm -rf ${log_path_dir}/base_cpu_cores.txt
#cpu cores
echo -e "\033[32mBelow is the CPU cores number for each CPU! \033[0m"
echo "Below is the CPU cores number for each CPU!" >> ${log_path}

for cpu_count_core in `seq $cpu_number`
do
  count_cores=$(($cpu_count_core -1 |bc))
  echo $count_cores: $cpu_cores
  echo $count_cores: $cpu_cores >> ${log_path}
  echo $count_cores: $cpu_cores >> ${log_path_dir}/base_cpu_cores.txt
done
#cpu threads
echo -e "\033[32mBelow is the CPU threads number for each CPU! \033[0m"
echo "Below is the CPU threads number for each CPU!" >> ${log_path}
for cpu_count in `seq $cpu_number`
do
  count_threads=$(($cpu_count -1 |bc))
  threads=`cat /proc/cpuinfo |grep "physical id"|sort|uniq -c|sed s/[[:space:]]//g|grep "physicalid:${count_threads}"|awk '{match($0,/([0-9]*)/,a);print a[1]}'`
  echo $count_threads: $threads
  echo $count_threads: $threads >> ${log_path}
  echo $count_threads: $threads >> ${log_path_dir}/base_cpu_threads.txt
done

#write other info to  base file
echo ${cpu_number} > ${log_path_dir}/base_cpu_number.txt
echo ${cpu_model} > ${log_path_dir}/base_cpu_model.txt

#mem info
#show info to screen
echo -e "\033[32mBelow is the total MEM size! \033[0m"
echo `dmesg |grep Memory|awk '{match($0,/\/(\w*)\s*available/,a);print a[1]}'`
#write info to log file
echo "Below is the total MEM size!" >> ${log_path}
dmesg |grep Memory|awk '{match($0,/\/(\w*)\s*available/,a);print a[1]}' >> ${log_path}
#write info to base file
dmesg |grep Memory|awk '{match($0,/\/(\w*)\s*available/,a);print a[1]}' > ${log_path_dir}/base_mem_size.txt

#network
#show info to the screen
rm -rf ${log_path_dir}/base_net_name_mac.txt
echo -e "\033[32mBelow is the network info! \033[0m"
echo "Below is the network info!" >> ${log_path}
echo -e "\033[32mBelow is the network name and its MAC! \033[0m"
echo "Below is the network name and its MAC!" >> ${log_path}
net_name=`ifconfig -a|sed -nr 's/^(\S+).*/\1/p'|grep -v "lo"|grep -v "virbr"|awk -F ":" '{print $1}'`

for name in ${net_name[@]}
do
	mac_address=`ifconfig $name|grep '\w\w:\w\w:\w\w:\w\w:\w\w:\w\w'|awk '{match($0,/(\w\w:\w\w:\w\w:\w\w:\w\w:\w\w)/,a);print a[1]}'`
	echo $name-$mac_address
	echo $name-$mac_address >> ${log_path}
	echo $name-$mac_address >> ${log_path_dir}/base_net_name_mac.txt
done

#disk
which lsscsi > /dev/null
if [ $? != 0 ]; then
	echo -e "\033[31mlssci is not installed! Please use apt-get install lsscsi to install it! \033[0m"
	echo "lssci is not installed! Please use apt-get install lsscsi to install it!" >> ${log_path}
	exit 255
else
	echo -e "\033[32mBelow is the Disk info from lsscsi! \033[0m"
	echo "Below is the Disk info from lsscsi!" >> ${log_path}
	lsscsi
	lsscsi >> ${log_path}
	lsscsi > ${log_path_dir}/base_lsscsi.txt
fi
#info from fdisk -l
rm -rf ${log_path_dir}/base_disk_model.txt
rm -rf ${log_path_dir}/base_disk_sn.txt
rm -rf ${log_path_dir}/base_disk_firmware.txt
rm -rf ${log_path_dir}/base_disk_size.txt
echo -e "\033[32mBelow is the Disk info from fdisk -l! \033[0m"
echo "Below is the Disk info from fdisk -l!" >> ${log_path}
fdisk -l|grep '^Disk /dev/'|grep -v loop|grep -v ram|sort
fdisk -l|grep '^Disk /dev/'|grep -v loop|grep -v ram|sort >> ${log_path}
fdisk -l|grep '^Disk /dev/'|grep -v loop|grep -v ram|sort > ${log_path_dir}/base_disk_fdisk.txt
filter_disk=`fdisk -l|grep '^Disk /dev/'|grep -v loop|grep -v ram|sort|awk '{print $2}'|awk -F ":" '{print $1}'`
for item_disk in ${filter_disk[@]}
do
	echo -e "\033[32mBelow is the smartctl info for\033[0m \033[31m${item_disk} \033[0m"
	echo "Below is the smartctl info for ${item_disk}" >> ${log_path}
	model=`smartctl -a ${item_disk}|grep -i "Device Model:"|awk -F ":" '{print $2}'|sed 's/^\s*//g'`
	sn=`smartctl -a ${item_disk}|grep -i "Serial Number:"|awk -F ":" '{print $2}'|sed 's/^\s*//g'`
	firmware=`smartctl -a ${item_disk}|grep -i "Firmware Version:"|awk -F ":" '{print $2}'|sed 's/^\s*//g'`
	size=`smartctl -a ${item_disk}|grep -i "User Capacity:"|awk -F ":" '{print $2}'|sed s/[[:space:]]//g|awk '{match($0,/\[(.*)\]/,a);print a[1]}'`
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
  echo -e "\033[32m${item_disk}:Model:\033[0m${model_write}"
  echo -e "\033[32m${item_disk}:Serial Number:\033[0m${sn_write}"
  echo -e "\033[32m${item_disk}:Firmware:\033[0m${firmware_write}"
  echo -e "\033[32m${item_disk}:Size:\033[0m${size_write}"
  echo "${item_disk}:Model:${model_write}" >> ${log_path}
  echo "${item_disk}:Serial Number:${sn_write}" >> ${log_path}
  echo "${item_disk}:Firmware:${firmware_write}" >> ${log_path}
  echo "${item_disk}:Size:${size_write}" >> ${log_path}
  echo "${item_disk}:${model_write}" >> ${log_path_dir}/base_disk_model.txt
  echo "${item_disk}:${sn_write}" >> ${log_path_dir}/base_disk_sn.txt
  echo "${item_disk}:${firmware_write}" >> ${log_path_dir}/base_disk_firmware.txt
  echo "${item_disk}:${size_write}" >> ${log_path_dir}/base_disk_size.txt
done
#lspci
echo "Below is the lspci info!" >> ${log_path}
lspci >> ${log_path}
lspci > ${log_path_dir}/base_lspci.txt
#pcie speed
#get all pcie device BDF
rm -rf ${log_path_dir}/base_pcie_speed.txt
echo -e "\033[32mBelow is the PCIe Device Speed info！\033[0m"
echo "Below is the PCIe Device Speed info！" >> ${log_path}
bdf=`lspci |awk '{print $1}'|sed s/[[:space:]]//g`
for item_bdf in ${bdf[@]}
do
  speed_info=`lspci -s ${item_bdf} -vvv -xxx|grep LnkSta:|awk -F ':' '{print $2}'|awk -F ',' '{print $1 $2}'|sed 's/^[ \t]*//g'`
  length_speed=`echo $speed_info|awk -F "" '{print NF}'`
  if [ ${length_speed} != 0 ];then
    echo "`lspci|grep ${item_bdf}`: ${speed_info}"
	echo "`lspci|grep ${item_bdf}`:${speed_info}" >> ${log_path}
	echo "`lspci|grep ${item_bdf}`:${speed_info}" >> ${log_path_dir}/base_pcie_speed.txt
  fi
done
# upi speed
upi_switch=`cat ${log_path_dir}/upiswitch.txt|head -n 1`
if [[ ${upi_switch} == "0" ]];then
  echo "No need to check UPI!" >> ${log_path}
else
  echo -e "\033[32mBelow are the UPI info!\033[0m"
  echo "Below are the UPI info!" >> ${log_path}
  lspci|grep -i 205b > /dev/null
  if [ $? != 0 ];then
    echo -e "\033[31mCan not find UPI(205b) from lspci!\033[0m"
    echo "Can not find UPI(205b) from lspci!" >>${log_path}	
	exit 255
  else
    upilist=`lspci|grep 205b|awk '{print $1}'`
    for upi in ${upilist[@]}
    do
      upispeed=`lspci -s $upi -xxx -vvv|grep d0:|awk '{print $6}'`
	  echo "${upi}-${upispeed}"
      echo "${upi}-${upispeed}" >> ${log_path_dir}/base_upispeed.txt
	  echo "${upi}-${upispeed}" >> ${log_path}
    done
  fi
fi

#generate count file
echo 1 > ${log_path_dir}/count.txt
#write start seconds to 1970
date +"%s" > ${log_path_dir}/start_seconds.txt
}

cat << 'EOF' > /home/reboot.sh
#!/bin/bash
#get log path
log_path_dir=`cat /home/log_path_dir.txt`
#get reboot type
reboot_type=`cat ${log_path_dir}/reboot_type.txt`
#get log file
log_path_temp=`cat ${log_path_dir}/log_name.txt`
log_path="${log_path_dir}/${log_path_temp}"
#error log file
error_log_path_temp=`cat ${log_path_dir}/error_log_name.txt`
error_log_path="${log_path_dir}/${error_log_path_temp}"
dmesg_log_path=`cat ${log_path_dir}/dmesg-log-path.txt`
#get total time
total_time=`cat ${log_path_dir}/total_time.txt`
#max_loop
max_loop=`cat ${log_path_dir}/max_loop.txt`
#sleep time
sleep_time=`cat ${log_path_dir}/sleep_time.txt`
#start_seconds
startseconds=`cat ${log_path_dir}/start_seconds.txt`
sleep $sleep_time

#get current count
current_count=`cat ${log_path_dir}/count.txt`
#now seconds
nowseconds=`date +"%s"`
total_seconds=$[nowseconds-startseconds]
now_date=`date +%Y%m%d%H%M%S`
if [[ ${total_seconds} -gt ${total_time} || ${current_count} -gt ${max_loop} ]]; then
echo "Total time reached!End Test!" >> ${log_path}
rm -rf /home/log_path_dir.txt
rm -rf  ${log_path_dir}/base* ${log_path_dir}/reboot_type.txt ${log_path_dir}/log_name.txt ${log_path_dir}/total_time.txt ${log_path_dir}/max_loop.txt ${log_path_dir}/sleep_time.txt ${log_path_dir}/start_seconds.txt /home/reboot.sh ${log_path_dir}/upiswitch.txt
rm -rf /etc/rc.d/rc.local ${log_path_dir}/dmesg-log-path.txt
rm -rf ${log_path_dir}/error_log_name.txt
#copy messages file to log dir
cp /var/log/messages* ${log_path_dir}
echo "End Test!End Time:${now_date}" >> ${log_path}
exit 0
fi
#write things to error log file
echo "###################################################" >> ${error_log_path}
echo "This is ${current_count} loop!" >> ${error_log_path}
date >> ${error_log_path}

#log count
echo "Below is the info for loop ${current_count}" >> ${log_path}
# dmesg
dmesg > ${dmesg_log_path}/dmesg-${current_count}.txt
#log temp info
#cpu info
cpu_number=`cat /proc/cpuinfo |grep "physical id"|sort|uniq -c|wc -l`
cpu_model=`cat /proc/cpuinfo |grep "model name"|sort|uniq -c|awk -F ':' '{print $2}'`
cpu_cores=`cat /proc/cpuinfo |grep "cpu cores"|sort|uniq -c|awk -F ':' '{print $2}'|sed s/[[:space:]]//g`
echo "Below is the CPU Number!" >> ${log_path}
echo $cpu_number >> ${log_path}
echo "Below is the CPU Model!" >> ${log_path}
echo $cpu_model >> ${log_path}
echo "Below is the CPU cores number for each CPU!" >> ${log_path}
rm -rf ${log_path_dir}/temp_cpu_cores.txt
rm -rf ${log_path_dir}/temp_cpu_threads.txt
for cpu_count_core in `seq $cpu_number`
do
  count_cores=$(($cpu_count_core -1 |bc))
  echo $count_cores: $cpu_cores >> ${log_path}
  echo $count_cores: $cpu_cores >> ${log_path_dir}/temp_cpu_cores.txt
done

echo "Below is the CPU threads number for each CPU!" >> ${log_path}
for cpu_count in `seq $cpu_number`
do
  count_threads=$(($cpu_count -1 |bc))
  threads=`cat /proc/cpuinfo |grep "physical id"|sort|uniq -c|sed s/[[:space:]]//g|grep "physicalid:${count_threads}"|awk '{match($0,/([0-9]*)/,a);print a[1]}'`
  echo $count_threads: $threads >> ${log_path}
  echo $count_threads: $threads >> ${log_path_dir}/temp_cpu_threads.txt
done

echo ${cpu_number} > ${log_path_dir}/temp_cpu_number.txt
echo ${cpu_model} > ${log_path_dir}/temp_cpu_model.txt
#mem
echo "Below is the total MEM size!" >> ${log_path}
dmesg |grep Memory|awk '{match($0,/\/(\w*)\s*available/,a);print a[1]}' >> ${log_path}

dmesg |grep Memory|awk '{match($0,/\/(\w*)\s*available/,a);print a[1]}' > ${log_path_dir}/temp_mem_size.txt

#network
net_name=`ifconfig -a|sed -nr 's/^(\S+).*/\1/p'|grep -v "lo"|grep -v "virbr"|awk -F ":" '{print $1}'`
echo "Below is the network name and its MAC!" >> ${log_path}
for name in ${net_name[@]}
do
	mac_address=`ifconfig $name|grep '\w\w:\w\w:\w\w:\w\w:\w\w:\w\w'|awk '{match($0,/(\w\w:\w\w:\w\w:\w\w:\w\w:\w\w)/,a);print a[1]}'`
	echo "$name: $mac_address" >> ${log_path}
	base_net_name_mac=`cat ${log_path_dir}/base_net_name_mac.txt|grep $name|awk -F "-" '{print $2}'|sed s/[[:space:]]//g`
	if [[ ${base_net_name_mac} != ${mac_address} ]];then
	  echo "fail" >> ${log_path_dir}/netstatus.txt
	  echo "Network $name test fail! Need ${base_net_name_mac}, but now ${mac_address}!" >> ${error_log_path}
        else
          echo "pass" >> ${log_path_dir}/netstatus.txt
	fi
done


#lsscsi
echo "Below is the lsscsi info!" >> ${log_path}
lsscsi >> ${log_path}
lsscsi >${log_path_dir}/temp_lsscsi.txt
#disk
rm -rf ${log_path_dir}/modelstatus.txt
rm -rf ${log_path_dir}/snstatus.txt
rm -rf ${log_path_dir}/firmwarestatus.txt
rm -rf ${log_path_dir}/sizestatus.txt
fdisk -l|grep '^Disk /dev/'|grep -v loop|grep -v ram|sort > ${log_path_dir}/temp_disk_fdisk.txt
echo "Below is the Disk info from fdisk -l!" >> ${log_path}
fdisk -l|grep '^Disk /dev/'|grep -v loop|grep -v ram|sort >> ${log_path}

filter_disk=`fdisk -l|grep '^Disk /dev/'|grep -v loop|grep -v ram|sort|awk '{print $2}'|awk -F ":" '{print $1}'|sed s/[[:space:]]//g`
for item_disk in ${filter_disk[@]}
do
  model=`smartctl -a ${item_disk}|grep -i "Device Model:"|awk -F ":" '{print $2}'|sed 's/^\s*//g'`
  sn=`smartctl -a ${item_disk}|grep -i "Serial Number:"|awk -F ":" '{print $2}'|sed 's/^\s*//g'`
  firmware=`smartctl -a ${item_disk}|grep -i "Firmware Version:"|awk -F ":" '{print $2}'|sed 's/^\s*//g'`
  size=`smartctl -a ${item_disk}|grep -i "User Capacity:"|awk -F ":" '{print $2}'|sed s/[[:space:]]//g|awk '{match($0,/\[(.*)\]/,a);print a[1]}'`
  base_model=`cat ${log_path_dir}/base_disk_model.txt|grep ${item_disk}|awk -F ":" '{print $2}'`
  base_sn=`cat ${log_path_dir}/base_disk_sn.txt|grep ${item_disk}|awk -F ":" '{print $2}'`
  base_firmware=`cat ${log_path_dir}/base_disk_firmware.txt|grep ${item_disk}|awk -F ":" '{print $2}'`
  base_size=`cat ${log_path_dir}/base_disk_size.txt|grep ${item_disk}|awk -F ":" '{print $2}'`

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

  echo "${item_disk}:Model:${model_write}" >> ${log_path}
  echo "${item_disk}:Serial Number:${sn_write}" >> ${log_path}
  echo "${item_disk}:Firmware:${firmware_write}" >> ${log_path}
  echo "${item_disk}:Size:${size_write}" >> ${log_path}
  if [[ ${base_model} != ${model_write} ]];then
	echo "fail" >> ${log_path_dir}/modelstatus.txt
	echo "Disk Model for ${item_disk} test fail! Need ${base_model}, but now ${model_write}!" >> ${error_log_path}
  else
    echo "pass" >> ${log_path_dir}/modelstatus.txt
  fi
  if [[ ${base_sn} != ${sn_write} ]];then
	echo "fail" >> ${log_path_dir}/snstatus.txt
	echo "Disk SN for ${item_disk} test fail! Need ${base_sn}, but now ${sn_write}!" >> ${error_log_path}
  else
    echo "pass" >> ${log_path_dir}/snstatus.txt
  fi
  if [[ ${base_firmware} != ${firmware_write} ]];then
	echo "fail" >> ${log_path_dir}/firmwarestatus.txt
	echo "Disk Firmware for ${item_disk} test fail! Need ${base_firmware}, but now ${firmware_write}!" >> ${error_log_path}
  else
    echo "pass" >> ${log_path_dir}/firmwarestatus.txt
  fi
  if [[ ${base_size} != ${size_write} ]];then
	echo "fail" >> ${log_path_dir}/sizestatus.txt
	echo "Disk Size for ${item_disk} test fail! Need ${base_size}, but now ${size_write}!" >> ${error_log_path}
  else
    echo "pass" >> ${log_path_dir}/sizestatus.txt
  fi

done

#lspci
echo "Below is the lspci info!" >> ${log_path}
lspci >> ${log_path}
lspci > ${log_path_dir}/temp_lspci.txt
rm -rf ${log_path_dir}/lspcistatus.txt
while read line
do
  bdf_pcie=`echo $line|awk '{print $1}'`
  line_temp=`echo $line|tr -d ['\n']`
  tempinfo=`cat ${log_path_dir}/temp_lspci.txt|grep ${bdf_pcie}|tr -d ['\n']`
  if [ $? != 0 ];then
    echo "fail" >> ${log_path_dir}/lspcistatus.txt
	echo "Lspci info for ${bdf_pcie} check fail! Missing in temp file!" >> ${error_log_path}
  else
    if [[ ${tempinfo} != ${line_temp} ]];then
	  echo "fail" >> ${log_path_dir}/lspcistatus.txt
	  echo "Lspci info for ${bdf_pcie} check fail! Need ${line_temp}, but now ${tempinfo}!" >> ${error_log_path}
    else
	  echo "pass" >> ${log_path_dir}/lspcistatus.txt
	fi
  fi
done < ${log_path_dir}/base_lspci.txt

while read line
do
  bdf_pcie=`echo $line|awk '{print $1}'`
  tempinfo=`cat ${log_path_dir}/base_lspci.txt|grep ${bdf_pcie}`
  if [ $? != 0 ];then
    echo "fail" >> ${log_path_dir}/lspcistatus.txt
	echo "Lspci info for ${bdf_pcie} check fail! Missing in base file!" >> ${error_log_path}
  else
	echo "pass" >> ${log_path_dir}/lspcistatus.txt
  fi
done < ${log_path_dir}/temp_lspci.txt

#pcie device speed
rm -rf ${log_path_dir}/pciespeedstatus.txt
echo "Below is the PCIe Device Speed info！" >> ${log_path}
bdf=`lspci |awk '{print $1}'|sed s/[[:space:]]//g`
for item_bdf in ${bdf[@]}
do
  speed_info=`lspci -s ${item_bdf} -vvv -xxx|grep LnkSta:|awk -F ':' '{print $2}'|awk -F ',' '{print $1 $2}'|sed 's/^[ \t]*//g'`
  length_speed=`echo ${speed_info}|awk -F "" '{print NF}'`
  if [[ ${length_speed} != 0 ]];then
    lenBasePcieSpeed=`cat ${log_path_dir}/base_pcie_speed.txt|grep ${item_bdf}|awk -F ":" '{print NF}'`
    base_pcie_speed=`cat ${log_path_dir}/base_pcie_speed.txt|grep ${item_bdf}|awk -F ":" '{print $'$lenBasePcieSpeed'}'`
	echo "`lspci|grep $item_bdf`:${speed_info}" >> ${log_path}
	if [[ ${base_pcie_speed} != ${speed_info} ]];then
	  echo "PCIe Device Speed for ${item_bdf} test fail!Need: ${base_pcie_speed}; but now:${speed_info}!" >> ${error_log_path}
	  echo "fail" >> ${log_path_dir}/pciespeedstatus.txt
	else
	  echo "pass" >> ${log_path_dir}/pciespeedstatus.txt
	fi
  fi
done

# upi speed
rm -rf ${log_path_dir}/upispeedstatus.txt
echo "Below is the UPI Speed info！" >> ${log_path}
upi_switch=`cat ${log_path_dir}/upiswitch.txt|head -n 1`
if [[ ${upi_switch} == "0" ]];then
  echo "No need to check UPI!" >> ${log_path}
else
  upilist=`lspci|grep 205b|awk '{print $1}'`
  for upi in ${upilist[@]}
  do
    upispeed=`lspci -s $upi -xxx -vvv|grep d0:|awk '{print $6}'`
	echo "$upi-$upispeed" >> ${log_path}
	base_upispeed=`cat ${log_path_dir}/base_upispeed.txt|grep $upi|awk -F "-" '{print $2}'`
	if [[ ${upispeed} != ${base_upispeed} ]];then
	  echo "UPI Speed for ${upi} check fail!Need: ${base_upispeed}; but now:${upispeed}!" >> ${error_log_path}
	  echo "fail" >> ${log_path_dir}/upispeedstatus.txt
	else
	  echo "pass" >> ${log_path_dir}/upispeedstatus.txt
	fi
  done
fi
#generate md5sum
#base
md5_base_cpu_number=`md5sum ${log_path_dir}/base_cpu_number.txt|awk '{print $1}'|sed 's/ //g'`
md5_base_cpu_model=`md5sum ${log_path_dir}/base_cpu_model.txt|awk '{print $1}'|sed 's/ //g'`
md5_base_cpu_threads=`md5sum ${log_path_dir}/base_cpu_threads.txt|awk '{print $1}'|sed 's/ //g'`
md5_base_cpu_cores=`md5sum ${log_path_dir}/base_cpu_cores.txt|awk '{print $1}'|sed 's/ //g'`
md5_base_mem_size=`md5sum ${log_path_dir}/base_mem_size.txt|awk '{print $1}'|sed 's/ //g'`
md5_base_lsscsi=`md5sum ${log_path_dir}/base_lsscsi.txt|awk '{print $1}'|sed 's/ //g'`
md5_base_disk_fdisk=`md5sum ${log_path_dir}/base_disk_fdisk.txt|awk '{print $1}'|sed 's/ //g'`

#temp
md5_temp_cpu_number=`md5sum ${log_path_dir}/temp_cpu_number.txt|awk '{print $1}'|sed 's/ //g'`
md5_temp_cpu_model=`md5sum ${log_path_dir}/temp_cpu_model.txt|awk '{print $1}'|sed 's/ //g'`
md5_temp_cpu_threads=`md5sum ${log_path_dir}/temp_cpu_threads.txt|awk '{print $1}'|sed 's/ //g'`
md5_temp_cpu_cores=`md5sum ${log_path_dir}/temp_cpu_cores.txt|awk '{print $1}'|sed 's/ //g'`
md5_temp_mem_size=`md5sum ${log_path_dir}/temp_mem_size.txt|awk '{print $1}'|sed 's/ //g'`
md5_temp_lsscsi=`md5sum ${log_path_dir}/temp_lsscsi.txt|awk '{print $1}'|sed 's/ //g'`
md5_temp_disk_fdisk=`md5sum ${log_path_dir}/temp_disk_fdisk.txt|awk '{print $1}'|sed 's/ //g'`

#test the difference
if [ ${md5_base_cpu_number} != ${md5_temp_cpu_number} ];then
  echo "CPU Number test fail for loop ${current_count}!" >> ${log_path}
  echo "CPU Number test fail for loop ${current_count}!" >> ${error_log_path}
  echo "fail" >> ${log_path_dir}/status.txt
  echo "Need:" >> ${error_log_path}
  cat ${log_path_dir}/base_cpu_number.txt >> ${error_log_path}
  echo "But now:" >> ${error_log_path}
  cat ${log_path_dir}/temp_cpu_number.txt >>${error_log_path}
else
  echo "CPU Number test pass for loop ${current_count}!" >> ${log_path}
  echo "pass" >> ${log_path_dir}/status.txt
fi

if [ ${md5_base_cpu_model} != ${md5_temp_cpu_model} ];then
	echo "CPU Model test fail for loop ${current_count}!" >> ${log_path}
    echo "CPU Model test fail for loop ${current_count}!" >> ${error_log_path}
	echo "fail" >> ${log_path_dir}/status.txt
	echo "Need:" >> ${error_log_path}
	cat ${log_path_dir}/base_cpu_model.txt >> ${error_log_path}
	echo "But now:" >> ${error_log_path}
	cat ${log_path_dir}/temp_cpu_model.txt >>${error_log_path}
else
	echo "CPU Model test pass for loop ${current_count}!" >> ${log_path}
	echo "pass" >> ${log_path_dir}/status.txt
fi

if [ ${md5_base_cpu_cores} != ${md5_temp_cpu_cores} ];then
	echo "CPU cores test fail for loop ${current_count}!" >> ${log_path}
    echo "CPU cores test fail for loop ${current_count}!" >> ${error_log_path}
	echo "fail" >> ${log_path_dir}/status.txt
	echo "Need:" >> ${error_log_path}
	cat ${log_path_dir}/base_cpu_cores.txt >> ${error_log_path}
	echo "But now:" >> ${error_log_path}
	cat ${log_path_dir}/temp_cpu_cores.txt >>${error_log_path}
else
	echo "CPU cores test pass for loop ${current_count}!" >> ${log_path}
	echo "pass" >> ${log_path_dir}/status.txt
fi
if [ ${md5_base_cpu_threads} != ${md5_temp_cpu_threads} ];then
	echo "CPU Threads test fail for loop ${current_count}!" >> ${log_path}
    echo "CPU Threads test fail for loop ${current_count}!" >> ${error_log_path}
	echo "fail" >> ${log_path_dir}/status.txt
	echo "Need:" >> ${error_log_path}
	cat ${log_path_dir}/base_cpu_threads.txt >> ${error_log_path}
	echo "But now:" >> ${error_log_path}
	cat ${log_path_dir}/temp_cpu_threads.txt >>${error_log_path}
else
	echo "CPU Threads test pass for loop ${current_count}!" >> ${log_path}
	echo "pass" >> ${log_path_dir}/status.txt
fi
if [ ${md5_base_mem_size} != ${md5_temp_mem_size} ];then
	echo "Mem Size test fail for loop ${current_count}!" >> ${log_path}
    echo "Mem Size test fail for loop ${current_count}!" >> ${error_log_path}
	echo "fail" >> ${log_path_dir}/status.txt
	echo "Need:" >> ${error_log_path}
	cat ${log_path_dir}/base_mem_size.txt >> ${error_log_path}
	echo "But now:" >> ${error_log_path}
	cat ${log_path_dir}/temp_mem_size.txt >>${error_log_path}
else
	echo "Mem Size test pass for loop ${current_count}!" >> ${log_path}
	echo "pass" >> ${log_path_dir}/status.txt
fi

if [ ${md5_base_lsscsi} != ${md5_temp_lsscsi} ];then
	echo "Lsscsi test fail for loop ${current_count}!" >> ${log_path}
    echo "Lsscsi test fail for loop ${current_count}!" >> ${error_log_path}
	echo "fail" >> ${log_path_dir}/status.txt
	echo "Need:" >> ${error_log_path}
	cat ${log_path_dir}/base_lsscsi.txt >> ${error_log_path}
	echo "But now:" >> ${error_log_path}
	cat ${log_path_dir}/temp_lsscsi.txt >>${error_log_path}
else
	echo "Lsscsi test pass for loop ${current_count}!" >> ${log_path}
	echo "pass" >> ${log_path_dir}/status.txt
fi
if [ ${md5_base_disk_fdisk} != ${md5_temp_disk_fdisk} ];then
	echo "Disk fdisk info test fail for loop ${current_count}!" >> ${log_path}
    echo "Disk fdisk info test fail for loop ${current_count}!" >> ${error_log_path}
	echo "fail" >> ${log_path_dir}/status.txt
	echo "Need:" >> ${error_log_path}
	cat ${log_path_dir}/base_disk_fdisk.txt >> ${error_log_path}
	echo "But now:" >> ${error_log_path}
	cat ${log_path_dir}/temp_disk_fdisk.txt >>${error_log_path}
else
	echo "Disk fdisk info test pass for loop ${current_count}!" >> ${log_path}
	echo "pass" >> ${log_path_dir}/status.txt
fi

#check lspci status
len_lspci_status=`cat ${log_path_dir}/lspcistatus.txt|grep fail|wc -l`
if [[ ${len_lspci_status} != 0 ]];then
  echo "fail" >> ${log_path_dir}/status.txt
  echo "Lspci test fail for loop ${current_count}!" >> ${log_path}
  echo "Lspci test fail for loop ${current_count}!" >> ${error_log_path}

else
  echo "Lspci test pass for loop ${current_count}!" >> ${log_path}
  echo "pass" >> ${log_path_dir}/status.txt
fi
rm -rf ${log_path_dir}/lspcistatus.txt

#check network status
len_status=`cat ${log_path_dir}/netstatus.txt|grep fail|wc -l`
if [[ ${len_status} != 0 ]];then
  echo "fail" >> ${log_path_dir}/status.txt
  echo "Network name & MAC test fail for loop ${current_count}!" >> ${log_path}
  echo "Network name & MAC test fail for loop ${current_count}!" >> ${error_log_path}
else
  echo "Network name & MAC test pass for loop ${current_count}!" >> ${log_path}
  echo "pass" >> ${log_path_dir}/status.txt
fi
rm -rf ${log_path_dir}/netstatus.txt

#check disk status
len_model_status=`cat ${log_path_dir}/modelstatus.txt|grep fail|wc -l`
len_sn_status=`cat ${log_path_dir}/snstatus.txt|grep fail|wc -l`
len_firmware_status=`cat ${log_path_dir}/firmwarestatus.txt|grep fail|wc -l`
len_size_status=`cat ${log_path_dir}/sizestatus.txt|grep fail|wc -l`
if [[ ${len_model_status} != 0 || ${len_sn_status} != 0 || ${len_firmware_status} != 0 || ${len_size_status} != 0 ]];then
  echo "fail" >> ${log_path_dir}/status.txt
  echo "Disk info(Model/SN/Firmware/Size) test fail for loop ${current_count}!" >> ${log_path}
  echo "Disk info(Model/SN/Firmware/Size) test fail for loop ${current_count}!" >> ${error_log_path}
else
  echo "Disk info(Model/SN/Firmware/Size) test pass for loop ${current_count}!" >> ${log_path}
  echo "pass" >> ${log_path_dir}/status.txt
fi
rm -rf ${log_path_dir}/modelstatus.txt
rm -rf ${log_path_dir}/snstatus.txt
rm -rf ${log_path_dir}/firmwarestatus.txt
rm -rf ${log_path_dir}/sizestatus.txt

#check pcie speed status
pciespeed_status=`cat ${log_path_dir}/pciespeedstatus.txt|grep fail|wc -l`
if [[ ${pciespeed_status} != 0 ]];then
  echo "fail" >> ${log_path_dir}/status.txt
  echo "PCIe Speed test fail for loop ${current_count}!" >> ${log_path}
  echo "PCIe Speed test fail for loop ${current_count}!" >> ${error_log_path}
else
  echo "pass" >> ${log_path_dir}/status.txt
  echo "PCIe Speed test pass for loop ${current_count}!" >> ${log_path}
fi
rm -rf ${log_path_dir}/pciespeedstatus.txt

#check upi speed status
upi_switch=`cat ${log_path_dir}/upiswitch.txt|head -n 1`
if [[ ${upi_switch} == "1" ]];then
  upispeed_status=`cat ${log_path_dir}/upispeedstatus.txt|grep fail|wc -l`
  if [[ ${upispeed_status} != 0 ]];then
    echo "fail" >> ${log_path_dir}/status.txt
    echo "UPI Speed test fail for loop ${current_count}!" >> ${log_path}
	echo "UPI Speed test fail for loop ${current_count}!" >> ${error_log_path}
  else
    echo "pass" >> ${log_path_dir}/status.txt
    echo "UPI Speed test pass for loop ${current_count}!" >> ${log_path}
  fi
fi
rm -rf ${log_path_dir}/upispeedstatus.txt


cat ${log_path_dir}/status.txt|grep fail > /dev/null 2>&1
if [ $? == 0 ];then
  echo "Total FAIL for loop ${current_count}!" >> ${log_path}
else
  echo "Total PASS for loop ${current_count}!" >> ${log_path}
fi
count_next=$[ current_count + 1 ] 
echo $count_next > ${log_path_dir}/count.txt
rm -rf ${log_path_dir}/temp* ${log_path_dir}/status.txt
if [ $reboot_type == "reboot" ];then
reboot
elif [ $reboot_type == "dc" ];then
poweroff
else
reboot
fi
EOF


# main
generate_base
echo -e "\033[32mThe Base infomation is shown above! Please check it and input y/Y to contiune or n/N to break test!"
read confirm
if [[ $confirm == "y" || $confirm == "Y" ]];then
  echo -e "\033[32mThe Base information is correct,and we will reboot in $sleep_time seconds!\033[0m"
  sleep $sleep_time
  echo "#!/bin/bash" > /etc/rc.d/rc.local
  echo "/bin/bash /home/reboot.sh &" >> /etc/rc.d/rc.local
  chmod 777 /etc/rc.d/rc.local
  if [ $reboot_type == "reboot" ];then
    systemctl reboot
  elif [ $reboot_type == "dc" ];then
    systemctl poweroff
  else
    systemctl reboot
  fi
else
  echo -e "\033[31mThe Base information is incorrect,and we will break the test!\033[0m"
  rm -rf /home/log_path_dir.txt /home/reboot.sh ${log_path_dir}/upiswitch.txt
  exit 255
fi
