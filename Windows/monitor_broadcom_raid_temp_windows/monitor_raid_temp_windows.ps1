<#
Monitor Broadcom RAID card chip & bbu temperature while doing stress!
only need one parameter,the total times(seconds)!
output is an image named "Image_temperature.png"
Author:yanshuo@inspur.com
#>


#create log directory
$current_path=Split-Path -Parent $MyInvocation.MyCommand.Definition
if (-not (Test-Path ${current_path}\log -PathType Container))
{
$null=New-Item -Path "${current_path}" -Name log -ItemType Directory 
}

#$total_time=Read-Host "Please input total last times(seconds)"
$current_date=Get-Date -Format yyyyMMddHHmmss
$log_dir_name="${current_date}_SIT_MONITORBROADCOM_TEST_WIN"
$log_file_name="${current_date}_SIT__MONITORBROADCOM_TEST_WIN.log"
$log_path_dir="${current_path}\log\$log_dir_name"
$log_path="${log_path_dir}\$log_file_name"
$null=New-Item -Path ".\log\" -Name "$log_dir_name" -ItemType Directory
$null=New-Item -Path "$log_path_dir" -Name "$log_file_name" -ItemType File
echo "Start monitor broadcom chip/bbu temperature:"|Out-File -Append -Force -Encoding unicode $log_path
echo $current_date|Out-File -Append -Force -Encoding unicode $log_path

$input_length = $args.Length
if ($input_length -ne 1)
{
Write-Host "ERROR! Input parameter number is incorrect!" -ForegroundColor Red
Write-Host "Usage: .\SUT_001_SIT_MONITORBROADCOM_TEST_WIN_V001.ps1 run_time(seconds)!" -ForegroundColor Red
echo "ERROR! Input parameter number is incorrect!" |Out-File -Append -Force $log_path
echo "Usage: .\SUT_001_SIT_MONITORBROADCOM_TEST_WIN_V001.ps1 run_time(seconds)!" |Out-File -Append -Force $log_path
exit(255)
}
$total_time=$args[0]
Write-Host "Start monitor broadcom chip/bbu temperature: $current_date" -ForegroundColor Green
#start monitor
$start_time=Get-Date
#get number of controllers
$number_of_ctrl_temp=(.\tool\MegaCli64.exe -adpcount|Out-String) -match "Controller Count:.*(\d+)"
$number_of_ctrl=$Matches[1].trim()
#get sas controller number
$null=(.\tool\scrtnycli_x64.exe --list)
$return_code_sas=$LASTEXITCODE
#test if sas controller exist
if ($return_code_sas -eq "0")
{
Write-Host "Find SAS Controller!"
echo "Find SAS Controller!"|Out-File -Append -Force $log_path

echo "Below is the SAS Controller info!"|Out-File -Append -Force $log_path
.\tool\scrtnycli_x64.exe --list|Out-File -Append -Force $log_path
$number_of_sas_ctrl_temp=(.\tool\scrtnycli_x64.exe --list)|Measure-Object|Select-Object -ExpandProperty count
$number_of_sas_ctrl=$number_of_sas_ctrl_temp - 7
$number_of_sas_ctrl_count=$number_of_sas_ctrl + 1
#create log directory
for ($count=1; $count -lt $number_of_sas_ctrl_count; $count++)
{
$null=New-Item -Path "$log_path_dir" -Name "ctrl_sas_$count" -ItemType Directory
}
#start to log temperature data
while (0 -ne 1)
{
$current_time=Get-Date
[int]$lasttime_temp=(New-TimeSpan -Start $start_time -end $current_time).TotalSeconds
if ($lasttime_temp -gt $total_time)
{
break
}
else
{
for ($count=1; $count -lt $number_of_sas_ctrl_count; $count++)
{
$chip_temp_sas_temp=(.\tool\scrtnycli_x64.exe -i ${count} show -temp|Out-String) -match "IOC Temperature\s*:\s*(\d+)"
$chip_temp_sas=$Matches[1].trim()
echo "$lasttime_temp,$chip_temp_sas"|Out-File -Append -Force -Encoding ascii "$log_path_dir\ctrl_sas_$count\chip_temp"
}
sleep 5
}

}
#filter data 
for ($count=1; $count -lt $number_of_sas_ctrl_count; $count++)
{
$data_chip_sas_temp=Get-Content "$log_path_dir\ctrl_sas_$count\chip_temp"
$length_chip_sas=$data_chip_sas_temp.Length
for ($item=0;$item -lt $length_chip_sas;$item++)
{
$data_chip_sas_temp[$item].split(",")[1]|Out-File -Force -Append "$log_path_dir\ctrl_sas_$count\chip_temp_temp"
}
$data_chip_sas=Get-Content "$log_path_dir\ctrl_sas_$count\chip_temp_temp"
$result_data_chip_sas=$data_chip_sas|Measure-Object -Minimum -Maximum
$max_chip_sas_temp=$result_data_chip_sas.Maximum
$min_chip_sas_temp=$result_data_chip_sas.Minimum
$max_temperature=$max_chip_sas_temp * 1.1
$min_temperature=$min_chip_sas_temp * 0.9
$scripts=@"
set terminal svg
set title 'Temperature'
set datafile separator ','
set xrange [0:${lasttime_temp}]
set yrange [${min_temperature}:${max_temperature}]
set ylabel 'Temperature(Celsius)'
set xlabel 'Time(s)'
set output "Image_Temperature_SAS_Controller_$count.svg"
set border
set key box
plot '${log_path_dir}\ctrl_sas_$count\chip_temp'  title 'Chip Temp' w lines lt 1
set output
"@
[System.IO.File]::WriteAllLines("${log_path_dir}\ctrl_sas_$count\gnuplot.txt",$scripts, (New-Object System.Text.UTF8Encoding $False))
.\tool\gnuplot\gnuplot.exe $log_path_dir\ctrl_sas_$count\gnuplot.txt
Move-Item Image_Temperature_SAS_Controller_$count.svg -Destination $log_path_dir
}
}
else
{

#test if raid controllers exist
if ($number_of_ctrl -ne "0")
{
Write-Host "Find RAID Controller!"
echo "Find RAID Controller!"|Out-File -Append -Force $log_path
echo "Below is the RAID Controller info!"|Out-File -Append -Force $log_path
.\tool\storcli64.exe show all|Out-File -Append -Force $log_path
#get bbu status for every controller
$status_bbu_list=New-Object -TypeName System.Collections.ArrayList
for ($i=0; $i -lt $number_of_ctrl; $i++)
{
$status_bbu_temp=(.\tool\storcli64.exe /c$i/cv show all|Out-String) -match "Status = (.*)"
$status_bbu=$Matches[1].trim()
$null=$status_bbu_list.Add($status_bbu)
$null=New-Item -Path "$log_path_dir" -Name "ctrl_$i" -ItemType Directory
}

while (0 -ne 1)
{
$current_time=Get-Date
[int]$lasttime_temp=(New-TimeSpan -Start $start_time -end $current_time).TotalSeconds

if ($lasttime_temp -gt $total_time)
{
break
}
else
{
for ($count=0; $count -lt $number_of_ctrl; $count++)
{
$chip_temp_temp=((.\tool\storcli64.exe /c$count show all)|Out-String) -match "ROC\s+.*?(\d+)"
$chip_temp=$Matches[1]
echo "$lasttime_temp,$chip_temp"|Out-File -Append -Force -Encoding ascii "$log_path_dir\ctrl_$count\chip_temp"
if ($status_bbu_list[$count] -eq "Success")
{
$bbu_temp_temp=((.\tool\storcli64.exe /c0/cv show all)|Out-String) -match "Temperature\s+(\d+\d*)\s*C"
$bbu_temp=$Matches[1]
echo "$lasttime_temp,$bbu_temp"|Out-File -Append -Force -Encoding ascii "$log_path_dir\ctrl_$count\bbu_temp"
}
}
sleep 5
}
}

for ($count=0; $count -lt $number_of_ctrl; $count++)
{
#filter data of chip
$data_chip_temp=Get-Content "$log_path_dir\ctrl_$count\chip_temp"
$length_chip=$data_chip_temp.Length
for ($item=0;$item -lt $length_chip;$item++)
{
$data_chip_temp[$item].split(",")[1]|Out-File -Force -Append "$log_path_dir\ctrl_$count\chip_temp_temp"
}
$data_chip=Get-Content "$log_path_dir\ctrl_$count\chip_temp_temp"
$result_data_chip=$data_chip|Measure-Object -Minimum -Maximum
$max_chip_temp=$result_data_chip.Maximum
$min_chip_temp=$result_data_chip.Minimum

#filter data for bbu
if ($status_bbu_list[$count] -eq "Success")
{
$data_bbu_temp=Get-Content "$log_path_dir\ctrl_$count\bbu_temp"
$length_bbu=$data_bbu_temp.Length
for ($item=0;$item -lt $length_bbu;$item++)
{
$data_bbu_temp[$item].split(",")[1]|Out-File -Force -Append "$log_path_dir\ctrl_$count\bbu_temp_temp"
}
$data_bbu=Get-Content "$log_path_dir\ctrl_$count\bbu_temp_temp"
$result_data_bbu=$data_bbu|Measure-Object -Minimum -Maximum
$max_bbu_temp=$result_data_bbu.Maximum
$min_bbu_temp=$result_data_bbu.Minimum
}

#filter data to plot in one picture
if ($status_bbu_list[$count] -eq "Success")
{
if ($max_chip_temp -gt $max_bbu_temp)
{
$max_temp=$max_chip_temp
}
else
{
$max_temp=$max_bbu_temp
}
}
else
{
$max_temp=$max_chip_temp
}

if ($status_bbu_list[$count] -eq "Success")
{
if ($min_chip_temp -lt $min_bbu_temp)
{
$min_temp=$min_chip_temp
}
else
{
$min_temp=$min_bbu_temp
}
}
else
{
$min_temp=$min_chip_temp
}

$max_temperature=$max_temp * 1.1
$min_temperature=$min_temp * 0.9

#plot image
if ($status_bbu_list[$count] -eq "Success")
{
$scripts=@"
set terminal svg
set title 'Temperature'
set datafile separator ','
set xrange [0:${lasttime_temp}]
set yrange [${min_temperature}:${max_temperature}]
set ylabel 'Temperature(Celsius)'
set xlabel 'Time(s)'
set output "Image_Temperature_RAID_Controller_$count.svg"
set border
set key box
plot '${log_path_dir}\ctrl_$count\bbu_temp' title 'BBU Temp' w lines lt 1, '${log_path_dir}\ctrl_$count\chip_temp'  title 'Chip Temp' w lines lt 3
set output
"@
}
else
{
$scripts=@"
set terminal svg
set title 'Temperature'
set datafile separator ','
set xrange [0:${lasttime_temp}]
set yrange [${min_temperature}:${max_temperature}]
set ylabel 'Temperature(Celsius)'
set xlabel 'Time(s)'
set output "Image_Temperature_RAID_Controller_$count.svg"
set border
set key box
plot '${log_path_dir}\ctrl_$count\chip_temp'  title 'Chip Temp' w lines lt 3 
set output
"@
}
[System.IO.File]::WriteAllLines("${log_path_dir}\ctrl_$count\gnuplot.txt",$scripts, (New-Object System.Text.UTF8Encoding $False))
.\tool\gnuplot\gnuplot.exe $log_path_dir\ctrl_$count\gnuplot.txt
Move-Item Image_Temperature_RAID_Controller_$count.svg -Destination $log_path_dir
}
}
else
{
Write-Host "No broadcom RAID/SAS controller found!Exit test! " -ForegroundColor Red
echo "No broadcom RAID/SAS controller found!Exit test!"|Out-File -Append -Force -Encoding unicode $log_path
exit(255)
}
}
#write end time
$end_date = Get-Date -Format yyyyMMddHHmmss
echo "End monitor broadcom chip/bbu temperature:"|Out-File -Append -Force $log_path
echo $end_date|Out-File -Append -Force $log_path
Write-Host "End monitor broadcom chip/bbu temperature:: $end_date" -ForegroundColor Green
exit(0)