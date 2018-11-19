<#
###############################
#Name:SUT_001_SIT_REBOOT_TEST_WIN
#Author:yanshuo
#Revision:
#Version:V001
#Date:2017-12-14
#Tracelist:V001-->First Version
#Function: reboot unber windows
#Parameter_1:system administrator username
#Parameter_2:system administrator password
#Parameter_3:reboot type(1=reboot;2=dc/ac)
#Parameter_4:total test time(seconds)
#Parameter_5:max loop
#Parameter_6:sleep time(seconds)
#Usage:.\SUT_001_SIT_REBOOT_TEST_WIN_V001.ps1 Parameter_1 Parameter_2 Parameter_3 Parameter_4 Parameter_5 Parameter_6
#Example:.\SUT_001_SIT_REBOOT_TEST_WIN_V001.ps1 administrator 1a? 1 43200 500 40
#>

<#[CmdletBinding()]
param
(
[int]$loop_count,
[int]$time_sleep,
$log_dir,
$log_name
)#>


function generate_base()
{
#Remove-Item "$log_dir\base*" -Force -Recurse
Write-Host " "
Write-Host "Below are the base informatin of this machine!" -ForegroundColor Green
echo "Below are the base informatin of this machine!"|Out-File -Force -Append -Encoding unicode "$log_name"
#cpu info
#show cpu info
Write-Host " "
Write-Host "Below are the information about Physical CPU!" -ForegroundColor Green
Write-Host "Below is the CPU Name of Each CPU!" -ForegroundColor Green
Get-WmiObject win32_processor|where {$_.status -eq "OK"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty Name

Write-Host "Below is the CPU Core Number of Each CPU!" -ForegroundColor Green
Get-WmiObject win32_processor|where {$_.status -eq "OK"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty numberofcores

Write-Host "Below is the CPU Threads Number of Each CPU!" -ForegroundColor Green
Get-WmiObject win32_processor|where {$_.status -eq "OK"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty NumberOfLogicalProcessors

echo "CPU infomation!"|Out-File -Force -Append -Encoding unicode "$log_name"
#write info to log file!
echo "Below is the CPU Info"|Out-File -Append -Force -Encoding unicode "$log_name"
echo "Below is the CPU Name!" |Out-File -Append -Force -Encoding unicode "$log_name"
(Get-WmiObject win32_processor|where {$_.status -eq "OK"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty Name)|Out-File -Append -Force -Encoding unicode "$log_name"
echo "Below is the CPU Core Number!"|Out-File -Append -Force -Encoding unicode "$log_name"
(Get-WmiObject win32_processor|where {$_.status -eq "OK"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty numberofcores)|Out-File -Append -Force -Encoding unicode "$log_name"
echo "Below is the CPU Threads Number!"|Out-File -Append -Force -Encoding unicode "$log_name"
(Get-WmiObject win32_processor|where {$_.status -eq "OK"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty NumberOfLogicalProcessors)|Out-File -Append -Force -Encoding unicode "$log_name"

#generate base file for CPU
Get-WmiObject win32_processor|where {$_.status -eq "OK"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty deviceid|
Out-File -Force -Append "$log_dir\base_cpu_deviceid.log"
Get-WmiObject win32_processor|where {$_.status -eq "OK"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty name|
Out-File -Force -Append "$log_dir\base_cpu_name.log"
Get-WmiObject win32_processor|where {$_.status -eq "OK"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty numberofcores|
Out-File -Force -Append "$log_dir\base_cpu_core.log"
Get-WmiObject win32_processor|where {$_.status -eq "OK"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty NumberOfLogicalProcessors|
Out-File -Force -Append "$log_dir\base_cpu_threads.log"


#memoryinfo
#show meminfo
Write-Host " "
Write-Host "Below are the information about Physical Memory!" -ForegroundColor Green
Get-WmiObject win32_physicalmemory|Format-Table -Property devicelocator, 
@{name='Size(GB)';expression=({$_.capacity / 1GB -as [int]})},
@{name='Manufacturer';expression=({$_.Manufacturer})},
@{name='PartNumber';expression=({$_.PartNumber})},
@{name='SerialNumber';expression=({$_.SerialNumber})} 

echo "Memory infomation!"|Out-File -Force -Append -Encoding unicode "$log_name"
(Get-WmiObject win32_physicalmemory|Format-Table -Property devicelocator, 
@{name='Size(GB)';expression=({$_.capacity / 1GB -as [int]})},
@{name='Manufacturer';expression=({$_.Manufacturer})},
@{name='PartNumber';expression=({$_.PartNumber})},
@{name='SerialNumber';expression=({$_.SerialNumber})} )|Out-File -Force -Append -Encoding unicode "$log_name"

#generate base file for mem
Get-WmiObject win32_physicalmemory|Sort-Object -Property devicelocator|Select-Object -ExpandProperty capacity|
Out-File -Force -Append "$log_dir\base_mem_size.log"
Get-WmiObject win32_physicalmemory|Sort-Object -Property devicelocator|Select-Object -ExpandProperty Manufacturer|
Out-File -Force -Append "$log_dir\base_mem_manufacturer.log"
Get-WmiObject win32_physicalmemory|Sort-Object -Property devicelocator|Select-Object -ExpandProperty PartNumber|
Out-File -Force -Append "$log_dir\base_mem_partnumber.log"
Get-WmiObject win32_physicalmemory|Sort-Object -Property devicelocator|Select-Object -ExpandProperty SerialNumber|
Out-File -Force -Append "$log_dir\base_mem_serialnumber.log"

#show physical drive info
Write-Host "Below are the information about Physical Drive!" -ForegroundColor Green
Write-Host "Below is the DISK Name!" -ForegroundColor Green
Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid |Select-Object -ExpandProperty Deviceid
Write-Host "Below is the DISK Size(GB)!" -ForegroundColor Green
(Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid |Select-Object -ExpandProperty Size)|ForEach-Object{$_ / 1GB -as [int]}
Write-Host "Below is the DISK Firmware!" -ForegroundColor Green
Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid |Select-Object -ExpandProperty firmwarerevision
Write-Host "Below is the DISK Model!" -ForegroundColor Green
Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid |Select-Object -ExpandProperty model
Write-Host "Below is the DISK SerialNumber!" -ForegroundColor Green
(Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid |Select-Object -ExpandProperty serialnumber).trim()

#write log file
echo "Disk drive information!"|Out-File -Force -Append -Encoding unicode "$log_name"
echo "Below is the DISK Name!"|Out-File -Append -Force -Encoding unicode "$log_name"
(Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid |Select-Object -ExpandProperty Deviceid)|Out-File -Append -Force -Encoding unicode "$log_name"
echo "Below is the DISK Size(GB)!"|Out-File -Append -Force -Encoding unicode "$log_name"
((Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid |Select-Object -ExpandProperty Size)|ForEach-Object{$_ / 1GB -as [int]})|Out-File -Append -Force -Encoding unicode "$log_name"
echo "Below is the DISK Firmware!" |Out-File -Append -Force -Encoding unicode "$log_name"
(Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid |Select-Object -ExpandProperty firmwarerevision)|Out-File -Append -Force -Encoding unicode "$log_name"
echo "Below is the DISK Model!" |Out-File -Append -Force -Encoding unicode "$log_name"
(Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid |Select-Object -ExpandProperty model)|Out-File -Append -Force -Encoding unicode "$log_name"
echo "Below is the DISK SerialNumber!"|Out-File -Append -Force -Encoding unicode "$log_name"
(Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid |Select-Object -ExpandProperty serialnumber).trim()|Out-File -Append -Force -Encoding unicode "$log_name"

#generate base file for disk drive
Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty interfacetype|
Out-File -Force -Append "$log_dir\base_disk_interface.log"
Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty size|
Out-File -Force -Append "$log_dir\base_disk_size.log"
Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty caption|
Out-File -Force -Append "$log_dir\base_disk_caption.log"
Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty firmwarerevision|
Out-File -Force -Append "$log_dir\base_disk_firmwarerevision.log"
Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty model|
Out-File -Force -Append "$log_dir\base_disk_model.log"
(Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty serialnumber).trim()|
Out-File -Force -Append "$log_dir\base_disk_serialnumber.log"

#show network info
Write-Host "Below are the information about Physical Network!" -ForegroundColor Green
Write-Host "Below is the Network Name!" -ForegroundColor Green
Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty Name
Write-Host "Below is the Network MAC Address!" -ForegroundColor Green
Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty macaddress
Write-Host "Below is the Network Manufacturer!" -ForegroundColor Green
Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty Manufacturer

echo "Netork Information"|Out-File -Force -Append -Encoding unicode "$log_name"
echo "Below is the Network Name!" |Out-File -Append -Force -Encoding unicode "$log_name"
(Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty Name)|Out-File -Append -Force -Encoding unicode "$log_name"
echo "Below is the Network MAC Address!" |Out-File -Append -Force -Encoding unicode "$log_name"
(Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty macaddress)|Out-File -Append -Force -Encoding unicode "$log_name"
echo "Below is the Network Manufacturer!" |Out-File -Append -Force -Encoding unicode "$log_name"
(Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty Manufacturer)|Out-File -Append -Force -Encoding unicode "$log_name"

#generate base file for network
Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty name|
Out-File -Force -Append "$log_dir\base_net_name.log"
Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty macaddress|
Out-File -Force -Append "$log_dir\base_net_macaddress.log"
Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty Manufacturer|
Out-File -Force -Append "$log_dir\base_net_manufacturer.log"
Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty ServiceName|
Out-File -Force -Append "$log_dir\base_net_servicename.log"
#Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|Sort-Object -Property deviceid|where {$_.netenabled}|
#Out-File -Force -Append "$log_dir\base_net_netenabled.log"
}

function generate_script ()
{
echo "@echo off"|Out-File -Encoding ascii -Append -Force reboot.cmd
{PowerShell -Command Set-ExecutionPolicy Unrestricted -scope currentuser}|Out-File -Encoding ascii -Append -Force  reboot.cmd
{Powershell -noprofile -NoExit -command "&{start-process powershell -ArgumentList '-noprofile -file C:\reboot.ps1' -verb RunAs}"}|Out-File -Encoding ascii -Append -Force  reboot.cmd
{
$host.UI.RawUI.BufferSize = new-object System.Management.Automation.Host.Size(175,20000)
#get log dir path
$log_dir=Get-Content "c:\logdir_path.log"
$log_name=Get-Content "c:\log_name.log"
#get current reboot times!
[int]$current_loop = Get-Content "$log_dir\current_loop.log"
#get total max loop count!
[int]$total_count=Get-Content "$log_dir\loop_count_expect.txt"
#get sleep time after OS start!
$time_sleep_sub=Get-Content "$log_dir\sleeptime.txt"
#get reboot type:warm reboot or DC/AC reboot!
$reboot_type=Get-Content "c:\reboot_type.log"

#get current time minus start time to detemine if longest time reached!
#get start time
$start_year=Get-Content "$log_dir\startyear.txt"
$start_month=Get-Content "$log_dir\startmonth.txt"
$start_day=Get-Content "$log_dir\startday.txt"
$start_hour=Get-Content "$log_dir\starthour.txt"
$start_minute=Get-Content "$log_dir\startminute.txt"
$start_second=Get-Content "$log_dir\startsecond.txt"
#get current time
$current_time=Get-Date 
#get longest time
[int]$longest_run_time_sub=Get-Content "$log_dir\longesttime.txt"
[int]$seconds_last=(New-TimeSpan -Start (Get-Date -Year $start_year -Month $start_month `
-Day $start_day -Hour $start_hour -Minute $start_minute -Second $start_second) -end $current_time).TotalSeconds

if (($current_loop -lt $total_count) -and ($seconds_last -lt $longest_run_time_sub))
{
Start-Sleep -Seconds $time_sleep_sub
echo "This is $current_loop loop!"|Out-File -Force -Append -Encoding unicode "$log_name"
Get-Date -Format yyyyMMdd_HHmmss|Out-File -Force -Append -Encoding unicode "$log_name"
#cpu
#generate temp file for CPU
Get-WmiObject win32_processor|where {$_.status -eq "OK"}|Sort-Object -Property deviceid|
Select-Object -ExpandProperty deviceid|
Out-File -Force -Append "$log_dir\temp_cpu_deviceid.log"
Get-WmiObject win32_processor|where {$_.status -eq "OK"}|Sort-Object -Property deviceid|
Select-Object -ExpandProperty name|
Out-File -Force -Append "$log_dir\temp_cpu_name.log"
Get-WmiObject win32_processor|where {$_.status -eq "OK"}|Sort-Object -Property deviceid|
Select-Object -ExpandProperty numberofcores|
Out-File -Force -Append "$log_dir\temp_cpu_core.log"
Get-WmiObject win32_processor|where {$_.status -eq "OK"}|Sort-Object -Property deviceid|
Select-Object -ExpandProperty NumberOfLogicalProcessors|
Out-File -Force -Append "$log_dir\temp_cpu_threads.log"

echo "CPU infomation!"|Out-File -Force -Append -Encoding unicode "$log_name"
echo "Below is the CPU Name!" |Out-File -Append -Force -Encoding unicode "$log_name"
(Get-WmiObject win32_processor|where {$_.status -eq "OK"}|Sort-Object -Property deviceid|
Select-Object -ExpandProperty Name)|
Out-File -Append -Force -Encoding unicode "$log_name"
echo "Below is the CPU Core Number!"|Out-File -Append -Force -Encoding unicode "$log_name"
(Get-WmiObject win32_processor|where {$_.status -eq "OK"}|Sort-Object -Property deviceid|
Select-Object -ExpandProperty numberofcores)|
Out-File -Append -Force -Encoding unicode "$log_name"
echo "Below is the CPU Threads Number!"|Out-File -Append -Force -Encoding unicode "$log_name"
(Get-WmiObject win32_processor|where {$_.status -eq "OK"}|Sort-Object -Property deviceid|
Select-Object -ExpandProperty NumberOfLogicalProcessors)|
Out-File -Append -Force -Encoding unicode "$log_name"

#mem
Get-WmiObject win32_physicalmemory|Sort-Object -Property devicelocator|
Select-Object -ExpandProperty capacity|
Out-File -Force -Append "$log_dir\temp_mem_size.log"
Get-WmiObject win32_physicalmemory|Sort-Object -Property devicelocator|
Select-Object -ExpandProperty Manufacturer|
Out-File -Force -Append "$log_dir\temp_mem_manufacturer.log"
Get-WmiObject win32_physicalmemory|Sort-Object -Property devicelocator|
Select-Object -ExpandProperty PartNumber|
Out-File -Force -Append "$log_dir\temp_mem_partnumber.log"
Get-WmiObject win32_physicalmemory|Sort-Object -Property devicelocator|
Select-Object -ExpandProperty SerialNumber|
Out-File -Force -Append "$log_dir\temp_mem_serialnumber.log"

echo "Memory infomation!"|Out-File -Force -Append -Encoding unicode "$log_name"
(Get-WmiObject win32_physicalmemory|Format-Table -Property devicelocator, 
@{name='Size(GB)';expression=({$_.capacity / 1GB -as [int]})},
@{name='Manufacturer';expression=({$_.Manufacturer})},
@{name='PartNumber';expression=({$_.PartNumber})},
@{name='SerialNumber';expression=({$_.SerialNumber})} )|Out-File -Force -Append -Encoding unicode "$log_name"


#disk
Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid|
Select-Object -ExpandProperty interfacetype|
Out-File -Force -Append "$log_dir\temp_disk_interface.log"
Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid|
Select-Object -ExpandProperty size|
Out-File -Force -Append "$log_dir\temp_disk_size.log"
Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid|
Select-Object -ExpandProperty caption|
Out-File -Force -Append "$log_dir\temp_disk_caption.log"
Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid|
Select-Object -ExpandProperty firmwarerevision|
Out-File -Force -Append "$log_dir\temp_disk_firmwarerevision.log"
Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid|
Select-Object -ExpandProperty model|
Out-File -Force -Append "$log_dir\temp_disk_model.log"
(Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid|
Select-Object -ExpandProperty serialnumber).trim()|
Out-File -Force -Append "$log_dir\temp_disk_serialnumber.log"

echo "Disk drive information!"|Out-File -Force -Append -Encoding unicode "$log_name"
echo "Below is the DISK Name!"|Out-File -Append -Force -Encoding unicode "$log_name"
(Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid |
Select-Object -ExpandProperty Deviceid)|
Out-File -Append -Force -Encoding unicode "$log_name"
echo "Below is the DISK Size(GB)!"|Out-File -Append -Force -Encoding unicode "$log_name"
((Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid |
Select-Object -ExpandProperty Size)|
ForEach-Object{$_ / 1GB -as [int]})|Out-File -Append -Force -Encoding unicode "$log_name"
echo "Below is the DISK Firmware!" |Out-File -Append -Force -Encoding unicode "$log_name"
(Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid |
Select-Object -ExpandProperty firmwarerevision)|Out-File -Append -Force -Encoding unicode "$log_name"
echo "Below is the DISK Model!" |Out-File -Append -Force -Encoding unicode "$log_name"
(Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid |
Select-Object -ExpandProperty model)|
Out-File -Append -Force -Encoding unicode "$log_name"
echo "Below is the DISK SerialNumber!"|Out-File -Append -Force -Encoding unicode "$log_name"
(Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid |
Select-Object -ExpandProperty serialnumber).trim()|
Out-File -Append -Force -Encoding unicode "$log_name"


#network
Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|
Sort-Object -Property deviceid|Select-Object -ExpandProperty name|
Out-File -Force -Append "$log_dir\temp_net_name.log"
Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|
Sort-Object -Property deviceid|Select-Object -ExpandProperty macaddress|
Out-File -Force -Append "$log_dir\temp_net_macaddress.log"
Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|
Sort-Object -Property deviceid|Select-Object -ExpandProperty Manufacturer|
Out-File -Force -Append "$log_dir\temp_net_manufacturer.log"
Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|
Sort-Object -Property deviceid|Select-Object -ExpandProperty ServiceName|
Out-File -Force -Append "$log_dir\temp_net_servicename.log"
#Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|Sort-Object -Property deviceid|where {$_.netenabled}|
#Out-File -Force -Append "$log_dir\temp_net_netenabled.log"
echo "Netork Information"|Out-File -Force -Append -Encoding unicode "$log_name"
echo "Below is the Network Name!" |Out-File -Append -Force -Encoding unicode "$log_name"
(Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|
Sort-Object -Property deviceid|Select-Object -ExpandProperty Name)|
Out-File -Append -Force -Encoding unicode "$log_name"
echo "Below is the Network MAC Address!" |Out-File -Append -Force -Encoding unicode "$log_name"
(Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|
Sort-Object -Property deviceid|Select-Object -ExpandProperty macaddress)|
Out-File -Append -Force -Encoding unicode "$log_name"
echo "Below is the Network Manufacturer!" |Out-File -Append -Force -Encoding unicode "$log_name"
(Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|
Sort-Object -Property deviceid|
Select-Object -ExpandProperty Manufacturer)|Out-File -Append -Force -Encoding unicode "$log_name"


#get hash for base and temp files
#base cpu
$hash_base_cpu_deviceid=Get-FileHash -Path $log_dir\base_cpu_deviceid.log -Algorithm SHA256|
Select-Object -ExpandProperty hash
$hash_base_cpu_name=Get-FileHash -Path $log_dir\base_cpu_name.log -Algorithm SHA256|
Select-Object -ExpandProperty hash
$hash_base_cpu_corenum=Get-FileHash -Path $log_dir\base_cpu_core.log -Algorithm SHA256|
Select-Object -ExpandProperty hash
$hash_base_cpu_threadsnum=Get-FileHash -Path $log_dir\base_cpu_threads.log -Algorithm SHA256|
Select-Object -ExpandProperty hash
#base mem
$hash_base_mem_size=Get-FileHash -Path $log_dir\base_mem_size.log -Algorithm SHA256|
Select-Object -ExpandProperty hash
$hash_base_mem_manufacturer=Get-FileHash -Path $log_dir\base_mem_manufacturer.log -Algorithm SHA256|
Select-Object -ExpandProperty hash
$hash_base_mem_partnumber=Get-FileHash -Path $log_dir\base_mem_partnumber.log -Algorithm SHA256|
Select-Object -ExpandProperty hash
$hash_base_mem_serialnumber=Get-FileHash -Path $log_dir\base_mem_serialnumber.log -Algorithm SHA256|
Select-Object -ExpandProperty hash
#base disk drive
$hash_base_disk_interface=Get-FileHash -Path $log_dir\base_disk_interface.log -Algorithm SHA256|
Select-Object -ExpandProperty hash
$hash_base_disk_size=Get-FileHash -Path $log_dir\base_disk_size.log -Algorithm SHA256|
Select-Object -ExpandProperty hash
$hash_base_disk_caption=Get-FileHash -Path $log_dir\base_disk_caption.log -Algorithm SHA256|
Select-Object -ExpandProperty hash
$hash_base_disk_firmwarerevision=Get-FileHash -Path $log_dir\base_disk_firmwarerevision.log -Algorithm SHA256|
Select-Object -ExpandProperty hash
$hash_base_disk_model=Get-FileHash -Path $log_dir\base_disk_model.log -Algorithm SHA256|
Select-Object -ExpandProperty hash
$hash_base_disk_serialnumber=Get-FileHash -Path $log_dir\base_disk_serialnumber.log -Algorithm SHA256|
Select-Object -ExpandProperty hash
#base network
$hash_base_net_name=Get-FileHash -Path $log_dir\base_net_name.log -Algorithm SHA256|
Select-Object -ExpandProperty hash
$hash_base_net_macaddress=Get-FileHash -Path $log_dir\base_net_macaddress.log -Algorithm SHA256|
Select-Object -ExpandProperty hash
$hash_base_net_manufacturer=Get-FileHash -Path $log_dir\base_net_manufacturer.log -Algorithm SHA256|
Select-Object -ExpandProperty hash
$hash_base_net_servicename=Get-FileHash -Path $log_dir\base_net_servicename.log -Algorithm SHA256|
Select-Object -ExpandProperty hash
#$hash_base_net_netenabled=Get-FileHash -Path $log_dir\base_net_enabled.log -Algorithm SHA256|Select-Object -ExpandProperty hash

#temp cpu
$hash_temp_cpu_deviceid=Get-FileHash -Path $log_dir\temp_cpu_deviceid.log -Algorithm SHA256|
Select-Object -ExpandProperty hash
$hash_temp_cpu_name=Get-FileHash -Path $log_dir\temp_cpu_name.log -Algorithm SHA256|
Select-Object -ExpandProperty hash
$hash_temp_cpu_corenum=Get-FileHash -Path $log_dir\temp_cpu_core.log -Algorithm SHA256|
Select-Object -ExpandProperty hash
$hash_temp_cpu_threadsnum=Get-FileHash -Path $log_dir\temp_cpu_threads.log -Algorithm SHA256|
Select-Object -ExpandProperty hash
#temp mem
$hash_temp_mem_size=Get-FileHash -Path $log_dir\temp_mem_size.log -Algorithm SHA256|
Select-Object -ExpandProperty hash
$hash_temp_mem_manufacturer=Get-FileHash -Path $log_dir\temp_mem_manufacturer.log -Algorithm SHA256|
Select-Object -ExpandProperty hash
$hash_temp_mem_partnumber=Get-FileHash -Path $log_dir\temp_mem_partnumber.log -Algorithm SHA256|
Select-Object -ExpandProperty hash
$hash_temp_mem_serialnumber=Get-FileHash -Path $log_dir\temp_mem_serialnumber.log -Algorithm SHA256|
Select-Object -ExpandProperty hash
#temp disk drive
$hash_temp_disk_interface=Get-FileHash -Path $log_dir\temp_disk_interface.log -Algorithm SHA256|
Select-Object -ExpandProperty hash
$hash_temp_disk_size=Get-FileHash -Path $log_dir\temp_disk_size.log -Algorithm SHA256|
Select-Object -ExpandProperty hash
$hash_temp_disk_caption=Get-FileHash -Path $log_dir\temp_disk_caption.log -Algorithm SHA256|
Select-Object -ExpandProperty hash
$hash_temp_disk_firmwarerevision=Get-FileHash -Path $log_dir\temp_disk_firmwarerevision.log -Algorithm SHA256|
Select-Object -ExpandProperty hash
$hash_temp_disk_model=Get-FileHash -Path $log_dir\temp_disk_model.log -Algorithm SHA256|
Select-Object -ExpandProperty hash
$hash_temp_disk_serialnumber=Get-FileHash -Path $log_dir\temp_disk_serialnumber.log -Algorithm SHA256|
Select-Object -ExpandProperty hash
#temp network
$hash_temp_net_name=Get-FileHash -Path $log_dir\temp_net_name.log -Algorithm SHA256|
Select-Object -ExpandProperty hash
$hash_temp_net_macaddress=Get-FileHash -Path $log_dir\temp_net_macaddress.log -Algorithm SHA256|
Select-Object -ExpandProperty hash
$hash_temp_net_manufacturer=Get-FileHash -Path $log_dir\temp_net_manufacturer.log -Algorithm SHA256|
Select-Object -ExpandProperty hash
$hash_temp_net_servicename=Get-FileHash -Path $log_dir\temp_net_servicename.log -Algorithm SHA256|
Select-Object -ExpandProperty hash
#$hash_base_net_netenabled=Get-FileHash -Path $log_dir\temp_net_enabled.log -Algorithm SHA256|Select-Object -ExpandProperty hash

#compare base and temp file!
#Remove-Item -Path $log_dir\status.log -Force -ErrorAction SilentlyContinue
#cpu number
if ($hash_base_cpu_deviceid -eq $hash_temp_cpu_deviceid)
{
echo "CPU DeviceID check OK!"|Out-File -Append -Force -Encoding unicode "$log_name"
echo "OK" |Out-File -Append -Force "$log_dir\status.log"
}
else
{
echo "CPU DeviceID check FAIL!"|Out-File -Append -Force -Encoding unicode "$log_name"
echo "FAIL" |Out-File -Append -Force "$log_dir\status.log"
}

#cpu name
if ($hash_base_cpu_name -eq $hash_temp_cpu_name)
{
echo "CPU Name check OK!"|Out-File -Append -Force -Encoding unicode "$log_name"
echo "OK" |Out-File -Append -Force "$log_dir\status.log"
}
else
{
echo "CPU Name check FAIL!"|Out-File -Append -Force -Encoding unicode "$log_name"
echo "FAIL" |Out-File -Append -Force "$log_dir\status.log"
}

#cpu core number
if ($hash_base_cpu_core -eq $hash_temp_cpu_core)
{
echo "CPU Core Number check OK!"|Out-File -Append -Force -Encoding unicode "$log_name"
echo "OK" |Out-File -Append -Force "$log_dir\status.log"
}
else
{
echo "CPU Core Number check FAIL!"|Out-File -Append -Force -Encoding unicode "$log_name"
echo "FAIL" |Out-File -Append -Force "$log_dir\status.log"
}

#cpu threads number
if ($hash_base_cpu_threads -eq $hash_temp_cpu_threads)
{
echo "CPU Threads Number check OK!"|Out-File -Append -Force -Encoding unicode "$log_name"
echo "OK" |Out-File -Append -Force "$log_dir\status.log"
}
else
{
echo "CPU Threads Number check FAIL!"|Out-File -Append -Force -Encoding unicode "$log_name"
echo "FAIL" |Out-File -Append -Force "$log_dir\status.log"
}

#mem size
if ($hash_base_mem_size -eq $hash_temp_mem_size)
{
echo "Memory Size check OK!"|Out-File -Append -Force -Encoding unicode "$log_name"
echo "OK" |Out-File -Append -Force "$log_dir\status.log"
}
else
{
echo "Memory Size check FAIL!"|Out-File -Append -Force -Encoding unicode "$log_name"
echo "FAIL" |Out-File -Append -Force "$log_dir\status.log"
}

#mem manufacturer
if ($hash_base_mem_manufacturer -eq $hash_temp_mem_manufacturer)
{
echo "Memory Manufacturer check OK!"|Out-File -Append -Force -Encoding unicode "$log_name"
echo "OK" |Out-File -Append -Force "$log_dir\status.log"
}
else
{
echo "Memory Manufacturer check FAIL!"|Out-File -Append -Force -Encoding unicode "$log_name"
echo "FAIL" |Out-File -Append -Force "$log_dir\status.log"
}

#mem partnumber
if ($hash_base_mem_partnumber -eq $hash_temp_mem_partnumber)
{
echo "Memory Partnumber check OK!"|Out-File -Append -Force -Encoding unicode "$log_name"
echo "OK" |Out-File -Append -Force "$log_dir\status.log"
}
else
{
echo "Memory Partnumber check FAIL!"|Out-File -Append -Force -Encoding unicode "$log_name"
echo "FAIL" |Out-File -Append -Force "$log_dir\status.log"
}

#mem serialnumber
if ($hash_base_mem_serialnumber -eq $hash_temp_mem_serialnumber)
{
echo "Memory SerialNumber check OK!"|Out-File -Append -Force -Encoding unicode "$log_name"
echo "OK" |Out-File -Append -Force "$log_dir\status.log"
}
else
{
echo "Memory SerialNumber check FAIL!"|Out-File -Append -Force -Encoding unicode "$log_name"
echo "FAIL" |Out-File -Append -Force "$log_dir\status.log"
}

#disk interface
if ($hash_base_disk_interface -eq $hash_temp_disk_interface)
{
echo "Disk Interface check OK!"|Out-File -Append -Force -Encoding unicode "$log_name"
echo "OK" |Out-File -Append -Force "$log_dir\status.log"
}
else
{
echo "Disk Interface check FAIL!"|Out-File -Append -Force -Encoding unicode "$log_name"
echo "FAIL" |Out-File -Append -Force "$log_dir\status.log"
}

#disk size
if ($hash_base_disk_size -eq $hash_temp_disk_size)
{
echo "Disk Size check OK!"|Out-File -Append -Force -Encoding unicode "$log_name"
echo "OK" |Out-File -Append -Force "$log_dir\status.log"
}
else
{
echo "Disk Size check FAIL!"|Out-File -Append -Force -Encoding unicode "$log_name"
echo "FAIL" |Out-File -Append -Force "$log_dir\status.log"
}

#disk caption
if ($hash_base_disk_caption -eq $hash_temp_disk_caption)
{
echo "Disk Caption check OK!"|Out-File -Append -Force -Encoding unicode "$log_name"
echo "OK" |Out-File -Append -Force "$log_dir\status.log"
}
else
{
echo "Disk Caption check FAIL!"|Out-File -Append -Force -Encoding unicode "$log_name"
echo "FAIL" |Out-File -Append -Force "$log_dir\status.log"
}

#disk firmwarerevision
if ($hash_base_disk_firmwarerevision -eq $hash_temp_disk_firmwarerevision)
{
echo "Disk firmwarerevision check OK!"|Out-File -Append -Force -Encoding unicode "$log_name"
echo "OK" |Out-File -Append -Force "$log_dir\status.log"
}
else
{
echo "Disk firmwarerevision check FAIL!"|Out-File -Append -Force -Encoding unicode "$log_name"
echo "FAIL" |Out-File -Append -Force "$log_dir\status.log"
}

#disk model
if ($hash_base_disk_model -eq $hash_temp_disk_model)
{
echo "Disk Model check OK!"|Out-File -Append -Force -Encoding unicode "$log_name"
echo "OK" |Out-File -Append -Force "$log_dir\status.log"
}
else
{
echo "Disk Model check FAIL!"|Out-File -Append -Force -Encoding unicode "$log_name"
echo "FAIL" |Out-File -Append -Force "$log_dir\status.log"
}

#disk serialnumber
if ($hash_base_disk_serialnumber -eq $hash_temp_disk_serialnumber)
{
echo "Disk Serialnumber check OK!"|Out-File -Append -Force -Encoding unicode "$log_name"
echo "OK" |Out-File -Append -Force "$log_dir\status.log"
}
else
{
echo "Disk Serialnumber check FAIL!"|Out-File -Append -Force -Encoding unicode "$log_name"
echo "FAIL" |Out-File -Append -Force "$log_dir\status.log"
}

#network name
if ($hash_base_net_name -eq $hash_temp_net_name)
{
echo "Network Name check OK!"|Out-File -Append -Force -Encoding unicode "$log_name"
echo "OK" |Out-File -Append -Force "$log_dir\status.log"
}
else
{
echo "Network Name check FAIL!"|Out-File -Append -Force -Encoding unicode "$log_name"
echo "FAIL" |Out-File -Append -Force "$log_dir\status.log"
}

#network macaddress
if ($hash_base_net_macaddress -eq $hash_temp_net_macaddress)
{
echo "Network Macaddress check OK!"|Out-File -Append -Force -Encoding unicode "$log_name"
echo "OK" |Out-File -Append -Force "$log_dir\status.log"
}
else
{
echo "Network Macaddress check FAIL!"|Out-File -Append -Force -Encoding unicode "$log_name"
echo "FAIL" |Out-File -Append -Force "$log_dir\status.log"
}

#network manufacturer
if ($hash_base_net_manufacturer -eq $hash_temp_net_manufacturer)
{
echo "Network Manufacturer check OK!"|Out-File -Append -Force -Encoding unicode "$log_name"
echo "OK" |Out-File -Append -Force "$log_dir\status.log"
}
else
{
echo "Network Manufacturer check FAIL!"|Out-File -Append -Force -Encoding unicode "$log_name"
echo "FAIL" |Out-File -Append -Force "$log_dir\status.log"
}

#network service name
if ($hash_base_net_servicename -eq $hash_temp_net_servicename)
{
echo "Network Service name check OK!"|Out-File -Append -Force -Encoding unicode "$log_name"
echo "OK" |Out-File -Append -Force "$log_dir\status.log"
}
else
{
echo "Network Service name check FAIL!"|Out-File -Append -Force -Encoding unicode "$log_name"
echo "FAIL" |Out-File -Append -Force "$log_dir\status.log"
}
$faillog=Get-Content "$log_dir\status.log"|Select-String -Pattern "FAIL"
if ($faillog.length -eq 0)
{
#Write-Host "PASS!"  -ForegroundColor Green
echo "This time is OK!"|Out-File -Append -Force -Encoding unicode "$log_name"
}
else
{
#Write-Host "FAIL!"  -ForegroundColor Red
echo "This time is FAIL!"|Out-File -Append -Force -Encoding unicode "$log_name"
}
Remove-Item "$log_dir\temp*" -Force -Recurse
Remove-Item "$log_dir\status.log" -Force -Recurse
[int]$count_next=$current_loop + 1
echo "$count_next"|Out-File -Force "$log_dir\current_loop.log"
Start-Sleep -Seconds 1
if ($reboot_type -eq "dcac")
{
Stop-Computer -Force
}
else
{
Restart-Computer -Force
}
}
else
{
Remove-Item "$log_dir\base*" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item "$log_dir\start*" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item "$log_dir\current_loop.log" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item "$log_dir\longesttime.txt" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item "$log_dir\loop_count_expect.txt" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item "$log_dir\sleeptime.txt" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item "c:\logdir_path.log" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item "c:\log_name.log" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item "c:\reboot_type.log" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item "c:\reboot.ps1" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Users\Administrator\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\reboot.cmd" -Force -ErrorAction SilentlyContinue
}
}|Out-File -Force -Encoding ascii reboot.ps1
}


#main
$host.UI.RawUI.BufferSize = new-object System.Management.Automation.Host.Size(1750,20000)
#create log 
$current_path=Split-Path -Parent $MyInvocation.MyCommand.Definition
if (-not (Test-Path ${current_path}\log -PathType Container))
{
$null=New-Item -Path "${current_path}" -Name log -ItemType Directory 
}
#generate directory for log using current date
$current_date=Get-Date -Format yyyyMMddHHmmss
$log_dir="${current_path}\log\${current_date}_SIT_REBOOT_TEST_WIN"
if (-not (Test-Path $log_dir -PathType Container))
{
$null=New-Item -Path "${current_path}\log" -Name ${current_date}_SIT_REBOOT_TEST_WIN -ItemType Directory 
}
$log_name="${log_dir}\${current_date}_SIT_REBOOT_TEST_WIN.log"
Write-Host "Start test time:$current_date" -ForegroundColor Green
echo "Start test time:"|Out-File -Force $log_name
echo $current_date|Out-File -Force -Append $log_name
#test input
$input_length = $args.Length
if ($input_length -ne 6)
{
Write-Host "ERROR! Input parameter number is incorrect!" -ForegroundColor Red
Write-Host "Usage: .\SUT_001_SIT_REBOOT_TEST_WIN_V001.ps1 username password reboot_type total_test_time max_loop sleep_time!" -ForegroundColor Green
Write-Host "Example: .\SUT_001_SIT_REBOOT_TEST_WIN_V001.ps1 administrator 1a? 1 43200 500 40!" -ForegroundColor Green
echo "ERROR! Input parameter number is incorrect!"|Out-File -Force -Append $log_name
echo "Usage: .\SUT_001_SIT_REBOOT_TEST_WIN_V001.ps1 username password reboot_type total_test_time max_loop sleep_time!"|Out-File -Force -Append $log_name
echo "Example: .\SUT_001_SIT_REBOOT_TEST_WIN_V001.ps1 administrator 1a? 1 43200 500 40!"|Out-File -Force -Append $log_name
exit(255)
}
$DefaultUsername=$args[0]
$DefaultPassword=$args[1]
$type_reboot=$args[2]
$longest_run_time=$args[3]
$loop_count=$args[4]
$time_sleep=$args[5]
echo "Reboot Type(1=reboot;2=dc/ac): ${type_reboot}" |Out-File -Force -Append  $log_name
echo "Longest time(Seconds):${longest_run_time}"|Out-File -Force -Append  $log_name
echo "Max loop:${loop_count}" |Out-File -Force -Append  $log_name
echo "Sleep Time(Seconds):${time_sleep}"|Out-File -Force -Append  $log_name
#disable useraccountcontrolsettings
$null=New-ItemProperty -Path HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -PropertyType DWord -Value 0 -Force
#set autologin
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"  
#setting registry values
Set-ItemProperty $RegPath "AutoAdminLogon" -Value "1"
Set-ItemProperty $RegPath "DefaultUsername" -Value $DefaultUsername
Set-ItemProperty $RegPath "DefaultPassword" -Value $DefaultPassword
$domainname=Get-WMIObject Win32_ComputerSystem | Select-Object -ExpandProperty name
Set-ItemProperty $RegPath "DefaultDomainName" -Value $domainname

#generate baseline
generate_base
#check baseline and decide to start reboot or not!
$go_or_not=Read-Host "Please check the base information! If OK, please input y/Y; if not OK, please input n/N!"

if (($go_or_not -eq "y") -or ($go_or_not -eq "Y"))
{
echo "$log_dir"|Out-File -Force -Encoding unicode "c:\logdir_path.log"
echo "$log_name"|Out-File -Force -Encoding unicode "c:\log_name.log"
Write-Host "your choise is " -NoNewline
Write-Host $go_or_not -ForegroundColor Green
echo $longest_run_time|Out-File -Force "$log_dir\longesttime.txt"
echo $time_sleep|Out-File -Force "$log_dir\sleeptime.txt"
echo $loop_count|Out-File -Force "$log_dir\loop_count_expect.txt"
echo "1"|Out-File -Force "$log_dir\current_loop.log"

#generate start time(yyyyMMddhhmmss) for time compare!
Get-Date -Format yyyy|Out-File -Force "$log_dir\startyear.txt"
Get-Date -Format MM|Out-File -Force "$log_dir\startmonth.txt"
Get-Date -Format dd|Out-File -Force "$log_dir\startday.txt"
Get-Date -Format HH|Out-File -Force "$log_dir\starthour.txt"
Get-Date -Format mm|Out-File -Force "$log_dir\startminute.txt"
Get-Date -Format ss|Out-File -Force "$log_dir\startsecond.txt"

if ($type_reboot -eq "1")
{
echo "reboot"|Out-File -Encoding ascii -Force "c:\reboot_type.log"
Write-Host "System will reboot after ${time_sleep} Seconds!" -ForegroundColor Green
}
elseif ($type_reboot -eq "2")
{
echo "dcac"|Out-File -Encoding ascii -Force "c:\reboot_type.log"
Write-Host "System will stop after ${time_sleep} Seconds!" -ForegroundColor Green
}
else
{
Write-Host "Invalid input!" -ForegroundColor Red
Start-Sleep -Seconds 1
exit(255)
}
Remove-Item -Path "C:\reboot.ps1" -Force -ErrorAction SilentlyContinue
generate_script($time_sleep)
Move-Item -Path reboot.ps1 -Destination "C:\" -Force
Move-Item -Path reboot.cmd -Destination "C:\Users\${DefaultUsername}\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup" -Force


Start-Sleep -Seconds $time_sleep
if ($type_reboot -eq "1")
{
Restart-Computer -Force
}
elseif ($type_reboot -eq "2")
{
Stop-Computer -Force
}
}
elseif (($go_or_not -eq "n") -or ($go_or_not -eq "N"))
{
Write-Host "your choise is ${go_or_not}.Stop Test" 

exit(255)
}
else
{
Write-Host "Invalid input!End the test!" -ForegroundColor Red
exit(255)
}
