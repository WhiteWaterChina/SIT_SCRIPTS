#!/bin/bash
##############################
#Name:SUT_001_SIT_REBOOT_TEST_DEBIAN
#Author:yanshuo
#Revision:
#Version:V001
#Date:2017-12-20
#Tracelist:V001-->First Version
#Function:reboot test under debian
#Parameter_1:reboot type.only "reboot"or"dc"
#Parameter_2:total test seconds
#Paramter_3: max test loop
#Paramter_4: sleep time
#Usage:bash SUT_001_SIT_REBOOT_TEST_DEBIAN_V001.sh Parameter_1 Parameter_2 Parameter_3　Parameter_4
#Example:
#1.reboot  bash SUT_001_SIT_REBOOT_TEST_DEBIAN_V001.sh reboot 43200 500 40
#2.dc/ac   bash SUT_001_SIT_REBOOT_TEST_DEBIAN_V001.sh dc 43200 500 40
###############################


#check and create log dir
[ ! -d log ] && mkdir log
#create log file
time_start=`date +%Y%m%d%H%M%S`
log_dir_name="${time_start}_SIT_REBOOT_TEST_DEBIAN"
log_file_name="${time_start}_SIT_REBOOT_TEST_DEBIAN.log"
current_path=`pwd`
log_path_dir="${current_path}/log/${log_dir_name}"
log_path="${current_path}/log/${log_dir_name}/${log_file_name}"
mkdir -p ${log_path_dir}
touch ${log_path}
# write  start time
echo "Start Testing Time!" >> ${log_path}
echo ${time_start} >> ${log_path}


#check input!Need:1.reboot type;2.total time;3.max loop;4.sleep time;
if [ $# != 4 ];then
    echo -e "\033[31mInput Error! Usage:$0 reboot_type(reboot/dc) total_time(seconds)  max_loop sleep_time(seconds) \033[0m"
    echo "Input Error! Usage:$0 reboot_type(reboot/dc) total_time(seconds)  max_loop sleep_time(seconds)" >> $log_path
    exit 255
else
    reboot_type=$1
    total_time=$2
    max_loop=$3
    sleep_time=$4
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
#generate base
function generate_base()
{
echo "Below is the base infomation!" >> ${log_path}
#cpu info
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
	echo $item_cpu >> ${log_path_dir}/base_cpu_threads.txt
done

#write info to  base file
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
echo -e "\033[32mBelow is the network info! \033[0m"
echo "Below is the network info!" >> ${log_path}
echo -e "\033[32mBelow is the network name! \033[0m"
echo "Below is the network name!" >> ${log_path}
net_name=`ifconfig -a|sed -nr 's/^(\S+).*/\1/p'|grep -v "lo"|grep -v "virbr"|awk -F ":" '{print $1}'`
for item_netname in ${net_name[@]}
do
	echo $item_netname
	echo $item_netname >> ${log_path}
	echo $item_netname >> ${log_path_dir}/base_net_name.txt
done
echo -e "\033[32mBelow is the MAC Address! \033[0m"
echo "Below is the MAC Address!" >> ${log_path}
for name in ${net_name[@]}
do
	mac_address=`ifconfig $name|grep '\w\w:\w\w:\w\w:\w\w:\w\w:\w\w'|awk '{match($0,/(\w\w:\w\w:\w\w:\w\w:\w\w:\w\w)/,a);print a[1]}'`
	echo $mac_address
	echo $mac_address >> ${log_path}
	echo ${mac_address} >> ${log_path_dir}/base_net_mac.txt
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
fi
#info from fdisk -l
echo -e "\033[32mBelow is the Disk info from fdisk -l! \033[0m"
echo "Below is the Disk info from fdisk -l!" >> ${log_path}
fdisk -l|grep '^Disk /dev/'|grep -v loop|grep -v ram|sort
fdisk -l|grep '^Disk /dev/'|grep -v loop|grep -v ram|sort >> ${log_path}
fdisk -l|grep '^Disk /dev/'|grep -v loop|grep -v ram|sort > ${log_path_dir}/base_disk_fdisk.txt
#smart info
which smartctl > /dev/null
if [ $? != 0 ];then
	echo -e "\033[31msmartctl is not installed!Please wait while installing it! \033[0m"
	echo "smartctl is not installed!Please wait while installing it!" >> ${log_path}
	cd tool
	tar -zxf smartmontools-6.4.tar.gz
	cd smartmontools-6.4/
	./configure > /dev/null 2>&1
if [ $? != 0 ];then
echo -e "\033[31msmartctl is installed failed!Please use apt-get -y install make/gcc/g++ to finish the preperation! \033[0m"
echo "smartctl is installed failed!Please use apt-get -y install make/gcc/g++ to finish the preperation!" >> ${log_path}
exit 255
fi
make > /dev/null 2>&1
if [ $? != 0 ];then
	echo -e "\033[31msmartctl is installed failed!Please use apt-get -y install make/gcc/g++ to finish the preperation! \033[0m"
	echo "smartctl is installed failed!Please use apt-get -y install make/gcc/g++ to finish the preperation!" >> ${log_path}
	exit 255
fi
make install > /dev/null 2>&1
if [ $? != 0 ];then
	echo -e "\033[31msmartctl is installed failed!Please use apt-get -y install make/gcc/g++ to finish the preperation! \033[0m"
	echo "smartctl is installed failed!Please use apt-get -y install make/gcc/g++ to finish the preperation!" >> ${log_path}
	exit 255
fi
cd $current_path
which smartctl > /dev/null
if [ $? != 0 ];then
	echo -e "\033[31msmartctl is installed failed! \033[0m"
	echo "smartctl is installed failed!" >> ${log_path}
	exit 255
fi
fi
filter_disk=`fdisk -l|grep '^Disk /dev/'|grep -v loop|grep -v ram|sort|awk '{print $2}'|awk -F ":" '{print $1}'`
for item_disk in ${filter_disk[@]}
do
	echo -e "\033[32mBelow is the smartctl info for\033[0m \033[31m${item_disk} \033[0m"
	echo "Below is the smartctl info for ${item_disk}" >> ${log_path}
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
echo -e "\033[32mModel\033[0m:${model_write}"
echo -e "\033[32mSerial Number\033[0m:${sn_write}"
echo -e "\033[32mFirmware\033[0m:${firmware_write}"
echo -e "\033[32mSize\033[0m:${size_write}"
echo "Model:${model_write}" >> ${log_path}
echo "Serial Number:${sn_write}" >> ${log_path}
echo "Firmware:${firmware_write}" >> ${log_path}
echo "Size:${size_write}" >> ${log_path}
echo "${model_write}" >> ${log_path_dir}/base_disk_model.txt
echo "${sn_write}" >> ${log_path_dir}/base_disk_sn.txt
echo "${firmware_write}" >> ${log_path_dir}/base_disk_firmware.txt
echo "${size_write}" >> ${log_path_dir}/base_disk_size.txt
done
#lspci
echo "Below is the lspci info!" >> ${log_path}
lspci >> ${log_path}
lspci > ${log_path_dir}/base_lspci.txt
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
rm -rf  ${log_path_dir}/base* ${log_path_dir}/reboot_type.txt ${log_path_dir}/log_name.txt ${log_path_dir}/total_time.txt ${log_path_dir}/max_loop.txt ${log_path_dir}/sleep_time.txt ${log_path_dir}/start_seconds.txt /home/reboot.sh
rm -rf /etc/rc.local
echo "End Test!End Time:${now_date}" >> ${log_path}
exit 0
fi
#log count
echo "Below is the info for loop ${current_count}" >> ${log_path}
#log temp info
#cpu info
cpu_number=`cat /proc/cpuinfo |grep "physical id"|sort|uniq -c|wc -l`
cpu_model=`cat /proc/cpuinfo |grep "model name"|sort|uniq -c|awk -F ':' '{print $2}'`
cpu_threads=`cat /proc/cpuinfo |grep "physical id"|sort|uniq -c|awk '{print $1}'`
echo "Below is the CPU Number!" >> ${log_path}
echo $cpu_number >> ${log_path}
echo "Below is the CPU Model!" >> ${log_path}
echo $cpu_model >> ${log_path}
echo "Below is the threads number of each CPU!" >> ${log_path}
for item_cpu in ${cpu_threads[@]}
do
echo $item_cpu >> ${log_path}
echo $item_cpu >> ${log_path_dir}/temp_cpu_threads.txt
done

echo ${cpu_number} > ${log_path_dir}/temp_cpu_number.txt
echo ${cpu_model} > ${log_path_dir}/temp_cpu_model.txt

#mem
echo "Below is the total MEM size!" >> ${log_path}
dmesg |grep Memory|awk '{match($0,/\/(\w*)\s*available/,a);print a[1]}' >> ${log_path}

dmesg |grep Memory|awk '{match($0,/\/(\w*)\s*available/,a);print a[1]}' > ${log_path_dir}/temp_mem_size.txt
#network
net_name=`ifconfig -a|sed -nr 's/^(\S+).*/\1/p'|grep -v "lo"|grep -v "virbr"|awk -F ":" '{print $1}'`
echo "Below is the network name!" >> ${log_path}
for item_netname in ${net_name[@]}
do
echo $item_netname
echo $item_netname >> ${log_path_dir}/temp_net_name.txt
done
for name in ${net_name[@]} 
do  
    mac_address=`ifconfig $name|grep '\w\w:\w\w:\w\w:\w\w:\w\w:\w\w'|awk '{match($0,/(\w\w:\w\w:\w\w:\w\w:\w\w:\w\w)/,a);print a[1]}'`
    echo $mac_address >> ${log_path}
    echo ${mac_address} >> ${log_path_dir}/temp_net_mac.txt
done

#disk
fdisk -l|grep '^Disk /dev/'|grep -v loop|grep -v ram|sort > ${log_path_dir}/temp_disk_fdisk.txt
echo "Below is the Disk info from fdisk -l!" >> ${log_path}
fdisk -l|grep '^Disk /dev/'|grep -v loop|grep -v ram|sort >> ${log_path}

filter_disk=`fdisk -l|grep '^Disk /dev/'|grep -v loop|grep -v ram|sort|awk '{print $2}'|awk -F ":" '{print $1}'`
for item_disk in ${filter_disk[@]}
do
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
echo "Model:${model_write}" >> ${log_path}
echo "Serial Number:${sn_write}" >> ${log_path}
echo "Firmware:${firmware_write}" >> ${log_path}
echo "Size:${size_write}" >> ${log_path}

echo "${model_write}" >> ${log_path_dir}/temp_disk_model.txt
echo "${sn_write}" >> ${log_path_dir}/temp_disk_sn.txt
echo "${firmware_write}" >> ${log_path_dir}/temp_disk_firmware.txt
echo "${size_write}" >> ${log_path_dir}/temp_disk_size.txt
done
#lspci
echo "Below is the lspci info!" >> ${log_path}
lspci >> ${log_path}
lspci > ${log_path_dir}/temp_lspci.txt

#generate md5sum
#base
md5_base_cpu_number=`md5sum ${log_path_dir}/base_cpu_number.txt|awk '{print $1}'|sed 's/ //g'`
md5_base_cpu_model=`md5sum ${log_path_dir}/base_cpu_model.txt|awk '{print $1}'|sed 's/ //g'`
md5_base_cpu_threads=`md5sum ${log_path_dir}/base_cpu_threads.txt|awk '{print $1}'|sed 's/ //g'`
md5_base_mem_size=`md5sum ${log_path_dir}/base_mem_size.txt|awk '{print $1}'|sed 's/ //g'`
md5_base_net_name=`md5sum ${log_path_dir}/base_net_name.txt|awk '{print $1}'|sed 's/ //g'`
md5_base_net_mac=`md5sum ${log_path_dir}/base_net_mac.txt|awk '{print $1}'|sed 's/ //g'`
md5_base_disk_fdisk=`md5sum ${log_path_dir}/base_disk_fdisk.txt|awk '{print $1}'|sed 's/ //g'`
md5_base_disk_model=`md5sum ${log_path_dir}/base_disk_model.txt|awk '{print $1}'|sed 's/ //g'`
md5_base_disk_sn=`md5sum ${log_path_dir}/base_disk_sn.txt|awk '{print $1}'|sed 's/ //g'`
md5_base_disk_firmware=`md5sum ${log_path_dir}/base_disk_firmware.txt|awk '{print $1}'|sed 's/ //g'`
md5_base_disk_size=`md5sum ${log_path_dir}/base_disk_size.txt|awk '{print $1}'|sed 's/ //g'`
md5_base_lcpsi=`md5sum ${log_path_dir}/base_lspci.txt|awk '{print $1}'|sed 's/ //g'`

#temp
md5_temp_cpu_number=`md5sum ${log_path_dir}/temp_cpu_number.txt|awk '{print $1}'|sed 's/ //g'`
md5_temp_cpu_model=`md5sum ${log_path_dir}/temp_cpu_model.txt|awk '{print $1}'|sed 's/ //g'`
md5_temp_cpu_threads=`md5sum ${log_path_dir}/temp_cpu_threads.txt|awk '{print $1}'|sed 's/ //g'`
md5_temp_mem_size=`md5sum ${log_path_dir}/temp_mem_size.txt|awk '{print $1}'|sed 's/ //g'`
md5_temp_net_name=`md5sum ${log_path_dir}/temp_net_name.txt|awk '{print $1}'|sed 's/ //g'`
md5_temp_net_mac=`md5sum ${log_path_dir}/temp_net_mac.txt|awk '{print $1}'|sed 's/ //g'`
md5_temp_disk_fdisk=`md5sum ${log_path_dir}/temp_disk_fdisk.txt|awk '{print $1}'|sed 's/ //g'`
md5_temp_disk_model=`md5sum ${log_path_dir}/temp_disk_model.txt|awk '{print $1}'|sed 's/ //g'`
md5_temp_disk_sn=`md5sum ${log_path_dir}/temp_disk_sn.txt|awk '{print $1}'|sed 's/ //g'`
md5_temp_disk_firmware=`md5sum ${log_path_dir}/temp_disk_firmware.txt|awk '{print $1}'|sed 's/ //g'`
md5_temp_disk_size=`md5sum ${log_path_dir}/temp_disk_size.txt|awk '{print $1}'|sed 's/ //g'`
md5_temp_lcpsi=`md5sum ${log_path_dir}/temp_lspci.txt|awk '{print $1}'|sed 's/ //g'`

#test the difference
if [ ${md5_base_cpu_number} != ${md5_temp_cpu_number} ];then
    echo "CPU Number test fail!" >> ${log_path}
    echo "fail" >> ${log_path_dir}/status.txt
else
    echo "CPU Number test pass!" >> ${log_path}
    echo "pass" >> ${log_path_dir}/status.txt
fi

if [ ${md5_base_cpu_model} != ${md5_temp_cpu_model} ];then
	echo "CPU Model test fail!" >> ${log_path}
	echo "fail" >> ${log_path_dir}/status.txt
else
	echo "CPU Model test pass!" >> ${log_path}
	echo "pass" >> ${log_path_dir}/status.txt
fi
if [ ${md5_base_cpu_threads} != ${md5_temp_cpu_threads} ];then
	echo "CPU Threads test fail!" >> ${log_path}
	echo "fail" >> ${log_path_dir}/status.txt
else
	echo "CPU Threads test pass!" >> ${log_path}
	echo "pass" >> ${log_path_dir}/status.txt
fi
if [ ${md5_base_mem_size} != ${md5_temp_mem_size} ];then
	echo "Mem Size test fail!" >> ${log_path}
	echo "fail" >> ${log_path_dir}/status.txt
else
	echo "Mem Size test pass!" >> ${log_path}
	echo "pass" >> ${log_path_dir}/status.txt
fi
if [ ${md5_base_net_name} != ${md5_temp_net_name} ];then
	echo "Net Name test fail!" >> ${log_path}
	echo "fail" >> ${log_path_dir}/status.txt
else
	echo "Net name test pass!" >> ${log_path}
	echo "pass" >> ${log_path_dir}/status.txt
fi
if [ ${md5_base_net_mac} != ${md5_temp_net_mac} ];then
	echo "Net Mac test fail!" >> ${log_path}
	echo "fail" >> ${log_path_dir}/status.txt
else
	echo "Net Mac test pass!" >> ${log_path}
	echo "pass" >> ${log_path_dir}/status.txt
fi
if [ ${md5_base_disk_fdisk} != ${md5_temp_disk_fdisk} ];then
	echo "Disk fdisk info test fail!" >> ${log_path}
	echo "fail" >> ${log_path_dir}/status.txt
else
	echo "Disk fdisk info test pass!" >> ${log_path}
	echo "pass" >> ${log_path_dir}/status.txt
fi
if [ ${md5_base_disk_model} != ${md5_temp_disk_model} ];then
	echo "Disk Model test fail!" >> ${log_path}
	echo "fail" >> ${log_path_dir}/status.txt
else
	echo "Disk Model test pass!" >> ${log_path}
	echo "pass" >> ${log_path_dir}/status.txt
fi
if [ ${md5_base_disk_sn} != ${md5_temp_disk_sn} ];then
	echo "Disk SN test fail!" >> ${log_path}
	echo "fail" >> ${log_path_dir}/status.txt
else
	echo "Disk SN test pass!" >> ${log_path}
	echo "pass" >> ${log_path_dir}/status.txt
fi
if [ ${md5_base_disk_firmware} != ${md5_temp_disk_firmware} ];then
	echo "Disk Firmware test fail!" >> ${log_path}
	echo "fail" >> ${log_path_dir}/status.txt
else
	echo "Disk Firmware test pass!" >> ${log_path}
	echo "pass" >> ${log_path_dir}/status.txt
fi
if [ ${md5_base_disk_size} != ${md5_temp_disk_size} ];then
	echo "Disk Size test fail!" >> ${log_path}
	echo "fail" >> ${log_path_dir}/status.txt
else
	echo "Disk Size test pass!" >> ${log_path}
	echo "pass" >> ${log_path_dir}/status.txt
fi
cat ${log_path_dir}/status.txt|grep fail > /dev/null 2>&1
if [ $? == 0 ];then
echo "FAIL!" >> ${log_path}
else
echo "PASS!" >> ${log_path}
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

generate_base
echo -e "\033[32mThe Base infomation is shown above! Please check it and input y/Y to contiune or n/N to break test!"
read confirm
if [[ $confirm == "y" || $confirm == "Y" ]];then
echo -e "\033[32mThe Base information is right,and we will reboot in $sleep_time seconds!\033[0m"
sleep $sleep_time
echo "#!/bin/bash -e" > /etc/rc.local
echo "/bin/bash /home/reboot.sh &" >> /etc/rc.local
echo "exit 0" >> /etc/rc.local
chmod 777 /etc/rc.local
if [ $reboot_type == "reboot" ];then
reboot
elif [ $reboot_type == "dc" ];then
poweroff
else
reboot
fi
else
echo -e "\033[31mThe Base information is incorrect,and we will break the test!\033[0m"
exit 255
fi
