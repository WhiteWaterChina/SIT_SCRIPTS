#!/bin/bash
#/***********************************************/#
#Function:this script can pick the key statistical data from the windows iometer result.
# And redirected them into  the file named result-iometer-filter.csv
#Author:yanshuo
#Mail:yanshuo@inspur.com
#/**********************************************/#
if [ $# -ne 1 ]; then {
echo "Usage:(./filter_iometer.sh name_iometer_result)"
sleep 1
exit
}
fi
filename=$1
echo -e "size(B)\tread_percentage\trandom_percentage">1.csv
cat $1 |sed -n "/^'size,/{n;p}"|awk -F "," '{print $1"\t"$3"\t"$4"\t"}'>>1.csv
echo -e "write_iops\twrite_MBps\tread_iops\tread_MBps">2.csv
cat $1 |sed -n "/^'Target Type,/{n;p}"|awk -F "," '{print $9"\t"$12"\t"$8"\t"$11"\t"}'>>2.csv
paste 1.csv 2.csv > result-iometer-filter.csv
rm -rf 1.csv 2.csv
