#!/bin/bash
CUR=$PWD
sutName=$1
confFile=$2
totalcount=$3

RES="$CUR/result/$sutName"
logfile="$RES/log.log"

if [ ! -d $RES ];then
  mkdir -p $RES
fi

if [ $# != 3 ];then
  echo "Usage:$0 sutName confFile apcip apcport totalcount"
  exit 1
fi
temp_len_sysip=`cat $confFile|grep systemIP|awk -F ':' '{print $2}'|awk -F ';' '{print NF}'`
len_sysip=`echo ${temp_len_sysip} -1|bc`
temp_len_mac=`cat $confFile|grep mac|awk -F ':' '{print $2}'|awk -F ';' '{print NF}'`
len_mac=`echo ${temp_len_mac} -1|bc`
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
for ((count=0;count<${len_mac};count++))
do
  j=$(($count+1))
  maclist[$count]=`cat $confFile|grep mac|awk -F ':' '{print $2}'|awk -F ';' '{print $'$j'}'`
done

function wolon()
{
    echo "wake on lan on uut $1 once at $i time at `date`" >> $logfile
    #ether-wake $1
    if [ $? -ne 0 ];then
        sleep 3
        echo "wake on lan on uut $1 once unsuccessful $i times at `date`, try again!" >> $logfile
	#ether-wake $1
    	if [ $? -ne 0 ];then
	        sleep 3
	        echo "wake on lan on uut $1  twice unsuccessful $i times at `date`, try thrice!" >> $logfile
	        #ether-wake $1
		    if [ $? -ne 0 ];then
		        sleep 3
		        echo "wake on lan  on uut $1 thrice unsuccessful $i times at `date`, test fail!" >> $logfile
		    else
		        echo "wake on lan on uut $1 thrice successful $i times at `date`" >> $logfile
		    fi
	    else
	        echo "wake on lan on uut $1 twice successful $i times at `date`" >> $logfile
	    fi
    else
        echo "wake on lan on uut $1 once successful $i times at `date`" >> $logfile
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
    sleep 30
    break
  else
    echo "Try one time to get systemip status for all nodes, but at least one node is still power on! Try another time!" >> $logfile
    sleep 30
  fi
done
# wake on lan for sut
for macad in ${maclist[@]}
do
  echo "$macad"
  wolon $macad
done

sleep 180
done
echo "WOL DC test finished at `date`" >> $logfile
exit 0
