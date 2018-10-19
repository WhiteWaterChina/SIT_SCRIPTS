#!/bin/bash
CUR=$PWD
sutName=$1
confFile=$2
apcip=$3
apcport=$4
totalcount=$5

RES="$CUR/result/$sutName"
logfile="$RES/log.log"

if [ ! -d $RES ];then
  mkdir -p $RES
fi

if [ $# != 5 ];then
  echo "Usage:$0 sutName confFile apcip apcport totalcount"
  exit 1
fi
temp_len_sysip=`cat $confFile|grep systemIP|awk -F ':' '{print $2}'|awk -F ';' '{print NF}'`
len_sysip=`echo ${temp_len_sysip} -1|bc`
echo "start test!" >> $logfile
#sleep for system first poweoff
echo "start to sleep"
sleep 10
#get system ip for all nodes
for ((count=0;count<${len_sysip};count++))
do
  j=$(($count+1))
  sysiplist[$count]=`cat $confFile|grep systemIP|awk -F ':' '{print $2}'|awk -F ';' '{print $'$j'}'`
done
function apcoff ()
{
local n1=$1
local n2=$2
echo "apc power off uut once at $ni time at `date`" >> $logfile
$CUR/apc-off.exp $n1 $n2
if [ $? -ne 0 ];then
    sleep 3
    echo "apc power off uut once unsuccessful at $ni time at `date`,try again!" >> $logfile
    $CUR/apc-off.exp $n1 $n2 
	if [ $? -ne 0 ]; then
	    sleep 3
	    echo "apc power off uut twice unsuccessful at $ni time at `date`,try thrice!" >>  $logfile
	    $CUR/apc-off.exp $n1 $n2
	    if [ $? -ne 0 ];then
	        sleep 3
	        echo "apc power off uut thrice unsuccessful at $ni time at `date`" >> $logfile
	        exit 2
	    else
	        echo "apc power off uut thrice successful at $ni time at `date`" >> $logfile
	    fi
	else
	    echo "apc power off uut twice successful $ni times at `date`" >> $logfile
	fi
else
    echo "apc power off uut once successful $ni time at `date`" >> $logfile
fi
}

function apcon()
{
    echo "apc power on uut once at $i time at `date`" >> $logfile
    $CUR/apc-on.exp $1 $2
    if [ $? -ne 0 ];then
        sleep 3
        echo "apc power on uut once unsuccessful $i times at `date`, try again!" >> $logfile
        $CUR/apc-on.exp $1 $2
	    if [ $? -ne 0 ];then
	        sleep 3
	        echo "apc power on uut twice unsuccessful $i times at `date`, try thrice!" >> $logfile
	        $CUR/apc-on.exp $1 $2
		    if [ $? -ne 0 ];then
		        sleep 3
		        echo "apc power on uut thrice unsuccessful $i times at `date`, test fail!" >> $logfile
		    else
		        echo "apc power on uut thrice successful $i times at `date`" >> $logfile
		    fi
	    else
	        echo "apc power on uut twice successful $i times at `date`" >> $logfile
	    fi
    else
        echo "apc power on uut once successful $i times at `date`" >> $logfile
    fi
}
# get system ip status for all nodes
for ((i=1;i<=$totalcount;i++))
do
echo "loop $i" >> $logfile
while :;
do
  for nodeip in ${sysiplist[@]}
  do
    #get ping status
    echo $nodeip
    ping $nodeip -c 10 >> $RES/ipstatus.temp
    ping_count=`cat $RES/ipstatus.temp|grep time=|wc -l`
    rm -rf $RES/ipstatus.temp
    if [ ${ping_count} == 0 ];then
      echo "fail" >> $RES/status.temp
    else
      echo "ok" >> $RES/status.temp
    fi
  done
  
  off_num=`cat $RES/status.temp|grep fail|wc -l`
  rm -rf $RES/status.temp
  if [ ${off_num} == 2 ];then
    echo "${len_sysip} nodes are shutdown at time:!" >> $logfile
    date >> $logfile
    break
  else
    echo "Try one time to get systemip status for all nodes, but at least one node is still power on! Try another time!" >> $logfile
    sleep 30
  fi
done
# cut power for this sut!
apcoff $apcip $apcport
sleep 30
# set apc on
apcon $apcip $apcport
sleep 180
done
echo "AC test finished at `date`" >> $logfile
exit 0
