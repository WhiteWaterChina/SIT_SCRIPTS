#!/bin/bash
function set_bmc_net_cfg()
{
if [ $# -ne 3 ];then
echo "Set BMC CFG input error!"
exit 0
fi
echo "SET BMC IP:$1,NETMASK:$2,GATEWAY:$3"

ipmitool -I open lan set 1 ipsrc static
ipmitool -I open lan set 1 ipaddr $1
ipmitool -I open lan set 1 netmask $2
ipmitool -I open lan set 1 defgw ipaddr $3
ipmitool -I open mc reset cold
}
function get_dmi_serialnumber()
{
	echo $(dmidecode | grep -A 4 "System Information" | grep "Serial Number") | awk -F ':' '{print $2}'
}
function get_array()
{
if [ $# -ne 1 ];then
echo "please input filename"
exit 0;
fi
SERIALNUMBER=`get_dmi_serialnumber`
echo "SERIAL: $SERIALNUMBER"
ARRAY=($(cat $1 | grep $SERIALNUMBER));
}
get _dmi_serialnumber
get_array
set_bmc_net_cfg ${ARRAY[1]} ${ARRAY[2] ${ARRAY[3]}
