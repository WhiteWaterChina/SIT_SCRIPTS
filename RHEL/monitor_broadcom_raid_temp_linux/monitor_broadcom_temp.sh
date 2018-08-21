#!/bin/bash
#check and create log dir
[ ! -d log ] && mkdir log
#create log file
time_start=`date +%Y%m%d%H%M%S`
log_dir_name="${time_start}_SIT_MONITORBROADCOM_TEST_RHEL"
log_file_name="${time_start}_SIT_MONITORBROADCOM_TEST_RHEL.log"
current_path=`pwd`
log_path_dir="${current_path}/log/${log_dir_name}"
log_path="${log_path_dir}/${log_file_name}"
mkdir -p ${log_path_dir}
touch ${log_path}

# write  start time
echo "Start Testing Time!" >> ${log_path}
echo ${time_start} >> ${log_path}
echo "Start Testing Time!"
echo ${time_start}

if [ $# != 1 ]; then
    echo -e "\033[31mInput error! Usage:$0 test_time(seconds)!\033[0m"
    echo "Input error! Usage:$0 test_time(seconds)!" >>${log_path}
    exit 1
fi
#install gnuplot
which gnuplot > /dev/null 2>&1
if [ $? != 0 ];then
echo -e "\033[31mgnuplot is not installed!Please wait while  install it!\033[0m"
echo "gnuplot is not installed!Please wait while install it!" >> ${log_path}
cd tool/gnuplot/
tar -zxf gnuplot-5.0.7.tar.gz
cd gnuplot-5.0.7/
./configure > /dev/null 2>&1
if [ $? != 0 ];then
echo -e "\033[31mgnuplot is installed failed!Please check if make/gcc/g++ is installed! \033[0m"
echo "gnuplot is installed failed!Please check if make/gcc/g++ is installed!" >> ${log_path}
exit 255
fi
make > /dev/null 2>&1
if [ $? != 0 ];then
echo -e "\033[31mgnuplot is installed failed!Please check if make/gcc/g++ is installed! \033[0m"
echo "gnuplot is installed failed!Please check if make/gcc/g++ is installed!" >> ${log_path}
exit 255
fi
make install > /dev/null 2>&1
if [ $? != 0 ];then
echo -e "\033[31mgnuplot is installed failed!Please check if make/gcc/g++ is installed! \033[0m"
echo "gnuplot is installed failed!Please check if make/gcc/g++ is installed!" >> ${log_path}
exit 255
fi
cd $current_path
which gnuplot > /dev/null 2>&1
if [ $? != 0 ];then
echo -e "\033[31mgnuplot is installed failed! \033[0m"
echo "gnuplot is installed failed!" >> ${log_path}
exit 255
fi
fi

lasttime=$1
starttime=`date +%s`
#test storcli64 if exists
if [ ! -f /opt/MegaRAID/storcli/storcli64 ];then
    echo -e "\033[31mstorcli is not installed!Please wait while install it!\033[0m"
    echo "storcli is not installed!Please wait while install it!" >> ${log_path}
    rpm -ivh tool/storcli-1.23.02-1.noarch.rpm >/dev/null 2>&1
    if [ -f /opt/MegaRAID/storcli/storcli64 ];then
        echo -e "\033[32mstorcli is installed sucessfully!\033[0m"
        echo "storcli is installed sucessfully!" >>${log_path}
    else
        echo -e "\033[31mstorcli is installed failed!Please check!\033[0m"
        echo "storcli is installed failed!Please check!" >>${log_path}
        exit 255
    fi
fi
status_bbu=`/opt/MegaRAID/storcli/storcli64 /c0 show all |grep "BBU Status ="|awk -F "=" '{print $2}'|sed 's/ //g'`
while :;
do
    endtime=`date +%s`
    #echo $endtime
    lasttime_temp=$(($endtime-$starttime))
    if [ $lasttime_temp -gt $lasttime ]; then
        break
    fi
    #log bbu temperature data
    if [[ $status_bbu == "0" ]];then
        bbu_temp=`/opt/MegaRAID/storcli/storcli64 /c0/cv show all|grep "Temperature"|awk '{match($0,/([0-9]+)/,a);print a[1]}'`
        echo "$lasttime_temp,$bbu_temp" >> ${log_path_dir}/bbu_temp.log
    fi
    #log chip temperature data
    chip_temp=`/opt/MegaRAID/storcli/storcli64 /c0 show all|grep "ROC tem"|awk '{match($0,/([0-9]+)/,a);print a[1]}'`
    echo "$lasttime_temp,$chip_temp" >> ${log_path_dir}/chip_temp.log
    sleep 5
done
#filter data of bbu
if [[ $status_bbu == "0" ]];then
    total_lines_bbu=`cat ${log_path_dir}/bbu_temp.log|wc -l`
    max_bbu_temp=`cat ${log_path_dir}/bbu_temp.log|awk -F "," '{print $2}'|sort -n -r|head -n 1`
    min_bbu_temp=`cat ${log_path_dir}/bbu_temp.log|awk -F "," '{print $2}'|sort -n|head -n 1`
fi
#filter data of chip
total_lines_chip=`cat ${log_path_dir}/chip_temp.log|wc -l`
max_chip_temp=`cat ${log_path_dir}/chip_temp.log|awk -F "," '{print $2}'|sort -n -r|head -n 1`
min_chip_temp=`cat ${log_path_dir}/chip_temp.log|awk -F "," '{print $2}'|sort -n|head -n 1`


#find max temperature
if [[ $status_bbu == "0" ]];then
    if [ $max_bbu_temp -gt $max_chip_temp ];then
        max_temp=$max_bbu_temp
    else
        max_temp=$max_chip_temp
    fi
else
    max_temp=$max_chip_temp
fi
#find min temperature
if [[ $status_bbu == "0" ]];then
    if [ $min_bbu_temp -lt $min_chip_temp ];then
        min_temp=$min_bbu_temp
    else
        min_temp=$min_chip_temp
    fi
else
    min_temp=$min_chip_temp
fi
max_temperature=$(echo "${max_temp}*1.1"|bc)
min_temperature=$(echo "${min_temp}*0.9"|bc)


#plot bbu temperature
if [[ $status_bbu == "0" ]];then
    gnuplot<<- END
    set terminal svg
    set title 'Temperature'
    set datafile separator ','
    set xrange [0:$lasttime]
    set yrange [$min_temperature:$max_temperature]
    set ylabel 'Temperature(Celsius)'
    set xlabel 'Time(s)'
    set output "Image_temperature.svg"
    set border
    set key box
    plot '${log_path_dir}/bbu_temp.log' title 'BBU_Temp' w lines lt 1, '${log_path_dir}/chip_temp.log' title 'Chip Temp' w lines lt 3 
    set output
END
else
    gnuplot<<- END
    set terminal svg
    set title 'Temperature'
    set datafile separator ','
    set xrange [0:$lasttime]
    set yrange [$min_temperature:$max_temperature]
    set ylabel 'Temperature(Celsius)'
    set xlabel 'Time(s)'
    set output "Image_temperature.svg"
    set border
    set key box
    plot '${RES}/chip_temp.log'  title 'Chip Temp' w lines lt 3
    set output
END
fi
mv Image_temperature.svg ${log_path_dir}/
#write end time
time_end=`date +%Y%m%d%H%M%S`
echo "End Testing Time!" >> ${log_path}
echo ${time_end} >> ${log_path}
echo -e "\033[32mTest Finished!\033[0m"
echo -e "End Time:\033[32m$time_end\033[0m"
exit 0
