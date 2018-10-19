#!/bin/bash
if [ $# != 1 ]; then
echo "Usage:$0 test_time(seconds)!"
exit 1
fi
chmod +x MegaCli64
rm -rf bbu_temp.log
rm -rf chip_temp.log
lasttime=$1
log_dir=`date +"%Y%m%d_%H%M%S"`
RES=$PWD/$log_dir
mkdir $log_dir
starttime=`date +%s`
#echo $starttime
while :;
do
endtime=`date +%s`
#echo $endtime
lasttime_temp=$(($endtime-$starttime))
if [ $lasttime_temp -gt $lasttime ]; then
break
fi
bbu_temp=`./MegaCli64 -adpbbucmd -a0|grep Temperature:|awk '{match($0,/[0-9]+/,a);print a[0]}'`
chip_temp=`./MegaCli64 -adpallinfo -a0|grep "ROC temperature"|awk '{match($0,/[0-9]+/,a);print a[0]}'`
echo "$lasttime_temp,$bbu_temp" >> ${RES}/bbu_temp.log
echo "$lasttime_temp,$chip_temp" >> ${RES}/chip_temp.log
sleep 5
done
#filter data of bbu
total_lines_bbu=`cat ${RES}/bbu_temp.log|wc -l`
max_bbu_temp=`cat ${RES}/bbu_temp.log|awk -F "," '{print $2}'|sort -r|head -n 1`
min_bbu_temp=`cat ${RES}/bbu_temp.log|awk -F "," '{print $2}'|sort |head -n 1`
#max_bbu=$(($max_bbu_temp + 2))
#min_bbu=$((min_bbu_temp - 2))

#ilter data of chip
total_lines_chip=`cat ${RES}/chip_temp.log|wc -l`
max_chip_temp=`cat ${RES}/chip_temp.log|awk -F "," '{print $2}'|sort -r|head -n 1`
min_chip_temp=`cat ${RES}/chip_temp.log|awk -F "," '{print $2}'|sort |head -n 1`
#max_chip=$(($max_chip_temp + 2))
#min_chip=$((min_chip_temp - 2))

#filter data to plot in one picture
if [ $total_lines_bbu -gt $total_lines_chip ];then
total_lines=$total_lines_bbu
else
total_lines=$total_lines_chip
fi

if [ $max_bbu_temp -gt $max_chip_temp ];then
max_temp=$max_bbu_temp
else
max_temp=$max_chip_temp
fi

if [ $min_bbu_temp -lt $min_chip_temp ];then
min_temp=$min_bbu_temp
else
min_temo=$min_chip_temp
fi
max_temperature=$(($max_temp + 2))
min_temperature=$((min_temp - 2))


#plot bbu temperature
gnuplot<<- END
set terminal png
set title 'Temperature'
set datafile separator ','
set xrange [0:$total_lines]
set yrange [$min_temperature:$max_temperature]
set ylabel 'Temperature(Celsius)'
set xlabel 'Time(s)'
set output "Image_temperature.png"
set border 3 lt 3 lw 2
set key box
plot '${RES}/bbu_temp.log' title 'BBU_Temp' w lp pt 5, '${RES}/chip_temp.log'  title 'Chip Temp' w lp pt 7 
set output
END

mv Image_temperature.png $RES/
