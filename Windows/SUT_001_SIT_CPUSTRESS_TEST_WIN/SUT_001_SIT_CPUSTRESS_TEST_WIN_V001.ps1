<#
Name:SUT_001_SIT_PTU_TEST_WIN
Author:yanshuo
Revision:
Version:A01
Date:2017-12-13
Tracelist:A01-->First Version
Function:windows ptu test
Parameter_1:run time(seconds)
Parameter_2:platform type(purley/grantley)
Usage:.\SUT_001_SIT_PTU_TEST_WIN_V001.ps1 run_time(seconds) platform_type(purley/grantley)
Example:.\SUT_001_SIT_PTU_TEST_WIN_V001.ps1 3600 purley
#>

#test log directory
$current_path=Split-Path -Parent $MyInvocation.MyCommand.Definition
if (-not (Test-Path ${current_path}\log -PathType Container))
{
$null=New-Item -Path "${current_path}" -Name log -ItemType Directory 
}
#create log file
$current_date=Get-Date -Format yyyyMMddHHmmss
$log_dir_name="${current_date}_SIT_PTU_TEST_WIN"
$log_file_name="${current_date}_SIT_PTU_TEST_WIN.log"
$log_path_dir="${current_path}\log\$log_dir_name"
$log_path="${log_path_dir}\$log_file_name"
$null=New-Item -Path ".\log\" -Name "$log_dir_name" -ItemType Directory
$null=New-Item -Path "$log_path_dir" -Name "$log_file_name" -ItemType File
echo "Start PTU Time!Start time:"|Out-File -Append -Force -Encoding unicode $log_path
echo $current_date|Out-File -Append -Force -Encoding unicode $log_path

$input_length = $args.Length
if ($input_length -ne 2)
{
Write-Host "ERROR! Input parameter number is incorrect!" -ForegroundColor Red
Write-Host "Usage: .\SUT_001_SIT_PTU_TEST_WIN_V001.ps1 run_time(seconds)  platform_type(purley/grantley)!" -ForegroundColor Green
echo "ERROR! Input parameter number is incorrect!" |Out-File -Force -Append -Encoding unicode $log_path
echo "Usage: .\SUT_001_SIT_ptu_TEST_WIN_V001.ps1 sleep_time(seconds)  platform_type(purley/grantley)!"|Out-File -Force -Append -Encoding unicode $log_path
exit(255)
}
else
{
#
$run_time=$args[0]
$input_type = $run_time.GetType().Name
$platform=$args[1]

# echo $input_type
if (($input_type -ne "Int32") -and ($input_type -ne "Int64"))
{
Write-Host "ERROR! Input parameter 1 type is incorrect!" -ForegroundColor Red
Write-Host "Your need to input a number!" -ForegroundColor Red
echo "ERROR! Input parameter 1 type is incorrect!"|Out-File -Force -Append -Encoding unicode $log_path
echo "Your need to input a number!"|Out-File -Append -Force -Encoding unicode $log_path
exit(255)
}
else
{
Write-Host "Begin PTU test! Please wait $run_time seconds to complete test!" -ForegroundColor Green
Write-Host "Start time: ${current_date}" -ForegroundColor Green
#run ptu
if ($platform -eq "purley")
{
.\tool\purley\PwrThermUtil.exe -c -b 1 -ct 1 -n -t ${run_time} -log ${log_path_dir}\ -loglvl 1|Out-Null
}
elseif ($platform -eq "grantley")
{
.\tool\grantley\PwrThermUtil.exe -c -ct 1 -en -t ${run_time} -log ${log_path_dir}\ -loglvl 1|Out-Null
}
Start-Sleep -Seconds 30
#filter data
Get-Content "${log_path_dir}\*-CPU.csv"|Select-Object -Skip 20 | Set-Content $log_path_dir\CPU-temp.csv
$file_length=(Get-Content "$log_path_dir\CPU-temp.csv").Length - 20
Get-Content "$log_path_dir\CPU-temp.csv" -TotalCount $file_length|Set-Content $log_path_dir\CPU.csv
$log_content=Get-Content $log_path_dir\CPU.csv
$cpu_number=[int](($log_content|%{$_.split(",")[1]}|Select-Object -Unique).length)
#get cfreq/temperature/power data from log file
for ($count=0;$count -lt $cpu_number;$count++)
{
$null=New-Item -Path "${log_path_dir}" -Name "cpuinfo-$count" -ItemType Directory 
#cfreq
$log_content|%{if($_.split(",")[1] -eq $count){$_.split(",")[4]|ForEach-Object {$_ / 1000}}}|Out-File -Append -Force -FilePath ${log_path_dir}\cpuinfo-$count\cpu-cfreq-tmp.csv
#temperature
$log_content|%{if($_.split(",")[1] -eq $count){$_.split(",")[7]}}|Out-File -Append -Force -FilePath ${log_path_dir}\cpuinfo-$count\cpu-temp-tmp.csv
#power
$log_content|%{if($_.split(",")[1] -eq $count){$_.split(",")[10]}}|Out-File -Append -Force -FilePath ${log_path_dir}\cpuinfo-$count\cpu-power-tmp.csv
}
#generate timestamp for xtick
$total_line=$log_content.Length
$length=[int]$total_line / $cpu_number
for ($i=0;$i -lt ${length};$i++)
{
echo $i |Out-File -Force -Append -Encoding unicode -FilePath ${log_path_dir}\timestamp.txt
}
#generate file to gnuplot
$time_stamp=Get-Content ${log_path_dir}\timestamp.txt
for ($count=0;$count -lt $cpu_number;$count++)
{
$cpu_cfreq=Get-Content ${log_path_dir}\cpuinfo-$count\cpu-cfreq-tmp.csv
$cpu_temp=Get-Content ${log_path_dir}\cpuinfo-$count\cpu-temp-tmp.csv
$cpu_power=Get-Content ${log_path_dir}\cpuinfo-$count\cpu-power-tmp.csv
for ($i=0;$i -lt $cpu_cfreq.Length;$i++)
{
$data_creq=$time_stamp[$i] + "," + $cpu_cfreq[$i]
$data_temp=$time_stamp[$i] + "," + $cpu_temp[$i]
$data_power=$time_stamp[$i] + "," + $cpu_power[$i]
echo $data_creq|Out-File -Append -Force -Encoding ascii $log_path_dir\cpuinfo-$count\cpu-cfreq.csv
echo $data_temp|Out-File -Append -Force -Encoding ascii $log_path_dir\cpuinfo-$count\cpu-temp.csv
echo $data_power|Out-File -Append -Force -Encoding ascii $log_path_dir\cpuinfo-$count\cpu-power.csv
}
}

#gnuplot
for ($count=0;$count -lt $cpu_number;$count++)
{

#$max_y_left=((Get-Content ${log_path_dir}\cpuinfo-$count\cpu-cfreq-tmp.csv)|Sort-Object|Select-Object -Last 1) +2
$cfreq_temp=(Get-Content ${log_path_dir}\cpuinfo-$count\cpu-cfreq-tmp.csv)|Measure-Object -Maximum -Minimum
$temp_temp=(Get-Content ${log_path_dir}\cpuinfo-$count\cpu-temp-tmp.csv)|Measure-Object -Maximum -Minimum
$power_temp=(Get-Content ${log_path_dir}\cpuinfo-$count\cpu-power-tmp.csv)|Measure-Object -Maximum -Minimum
#find max ytick
$max_y_left=($cfreq_temp.Maximum) * 1.1
$max_temp=$temp_temp.Maximum
$max_power=$power_temp.Maximum
if ($max_temp -gt $max_power)
{
$max_y_right_temp= $max_temp
}
else
{
$max_y_right_temp = $max_power
}
$max_y_right=$max_y_right_temp * 1.1

#find min ytick
$min_y_left=($cfreq_temp.Minimum) * 0.9
$min_temp=$temp_temp.Minimum
$min_power=$power_temp.Minimum
if ($min_temp -lt $min_power)
{
$min_y_right_temp= $min_temp
}
else
{
$min_y_right_temp = $min_power
}
$min_y_right=$min_y_right_temp * 0.9

$scripts=@"
set terminal svg
set title 'MONITOR-INFO-CPU$count'
set datafile separator ','
set y2tics
set ytics nomirror
set xrange [0:$length]
set yrange [${min_y_left}:${max_y_left}]
set y2range [${min_y_right}:${max_y_right}]
set ylabel 'CFreq(GHz)'
set y2label 'POWER(W)/Temperature(Celsius)'
set xlabel 'Time(s)'
set border
set output "Image_MONITOR_INFO_CPU${count}.svg"
set key box
plot '${log_path_dir}\cpuinfo-$count\cpu-cfreq.csv' title 'CPU CFreq' w lines lt 1 axis x1y1, '${log_path_dir}\cpuinfo-$count\cpu-power.csv' title 'CPU POWER' w lines lt 5 axis x1y2, '${log_path_dir}\cpuinfo-$count\cpu-temp.csv' title 'CPU Temperature' w lines lt 3 axis x1y2
set output
"@
[System.IO.File]::WriteAllLines("${log_path_dir}\cpuinfo-$count\gnuplot.txt",$scripts, (New-Object System.Text.UTF8Encoding $False))

.\tool\gnuplot\gnuplot.exe ${log_path_dir}\cpuinfo-$count\gnuplot.txt

Move-Item -Path Image_MONITOR_INFO_CPU${count}.svg -Destination ${log_path_dir} -Force
Remove-Item ${log_path_dir}\cpuinfo-$count -Recurse -Force -ErrorAction SilentlyContinue
}
Remove-Item ${log_path_dir}\CPU*.csv -Force -ErrorAction SilentlyContinue
Remove-Item ${log_path_dir}\timestamp.txt -Force -ErrorAction SilentlyContinue
Remove-Item ${log_path_dir}\*-MEM.csv -Force -ErrorAction SilentlyContinue
#echo $log_content|Out-File -Append -Force -Encoding unicode $log_path
#Remove-Item -Force -Recurse ".\log\*.csv" -ErrorAction SilentlyContinue
$end_date = Get-Date -Format yyyyMMddHHmmss
echo "End PTU TEST!End time:"|Out-File -Append -Force $log_path
echo $end_date|Out-File -Append -Force $log_path
exit(0)
}
}