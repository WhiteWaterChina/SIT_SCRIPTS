<#
###############################
#Name:SUT_001_SIT_NETPLUG_TEST_WIN
#Author:yanshuo
#Revision:
#Version:V001
#Date:2018-01-12
#Tracelist:V001-->First Version
#Function: reboot unber windows
#Parameter_1:target ip
#Parameter_2:total loop
#Usage:.\SUT_001_SIT_NETPLUG_TEST_WIN_V001.ps1 Parameter_1 Parameter_2
#Example:.\SUT_001_SIT_NETPLUG_TEST_WIN_V001.ps1 100.2.36.2 20
#>


function plug_out()
{
#get device name that being pluged out
$temp_name_for_out=Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|where{$_.netenabled -eq "True"}|Select-Object -ExpandProperty name
foreach ($name_for_out in $base_name_for_out)
{
if ($temp_name_for_out -notcontains $name_for_out)
{
$DEV_name_out=$name_for_out
}
}
Start-Sleep -Seconds 1
#show out
Write-Host $DEV_name_out -NoNewline -ForegroundColor Green
Write-Host " is plugged out! "
Write-Host "Please plug it in!"
#$flag_plug=0
Set-Variable -Name flag_plug -Value 0 -Scope 1
}

function plug_in()
{
$loop_count=Get-Content "$log_path_dir\count.log"
$temp_name_for_in=Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|where{$_.netenabled -ne "True"}|Select-Object -ExpandProperty name
foreach ($name_for_in in $base_name_for_in)
{
if ($temp_name_for_in -notcontains $name_for_in)
{
$DEV_name_in=$name_for_in
}
}
Start-Sleep -Seconds 1
#$flag_plug=1
Set-Variable -Name flag_plug -Value 1 -Scope 1
#get ipaddress for the device that pluged in
#first find out the interfaceindex according to the device name
$interfaceindex=Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|where {$_.name -eq "$DEV_name_in"}|
Select-Object -ExpandProperty interfaceindex
#second find the ipaddress
$ipaddress_in=Get-NetIPAddress|where {$_.interfaceindex -eq "$interfaceindex"}|where {$_.AddressFamily -eq "IPv4"}| Select-Object -ExpandProperty ipaddress
#find the deviceid index
$deviceid_index=Get-WmiObject win32_networkadapter|where {$_.name -eq "$DEV_name_in"}|
Select-Object -ExpandProperty deviceid
#find the speed for this port!
$speed_this_port=Get-WmiObject win32_networkadapter|where {$_.name -eq "$DEV_name_in"}|
Select-Object -ExpandProperty speed
Write-Host $DEV_name_in -NoNewline -ForegroundColor Green
Write-Host " is plugged in! Current IPAddress is " -NoNewline
Write-Host $ipaddress_in  -ForegroundColor Green
#Write-Host "Index of this port is " -NoNewline
#Write-Host $deviceid_index -NoNewline -ForegroundColor Green
Write-Host " ! Current Speed is " -NoNewline
Write-Host $speed_this_port -NoNewline -ForegroundColor Green
Write-Host " bit/s!"
#get device status for current time!
$device_numbers=Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|
Select-Object -ExpandProperty deviceid|Sort-Object
foreach ($count in $device_numbers)
{
Get-WmiObject win32_networkadapter|where {$_.deviceid -eq "$count"}|
Select-Object -ExpandProperty name |Out-File -Append -Force "$log_path_dir\temp-devicename.txt"
Get-WmiObject win32_networkadapter|where {$_.deviceid -eq "$count"}|
Select-Object -ExpandProperty macaddress |Out-File -Append -Force "$log_path_dir\temp-macaddress.txt"
Get-WmiObject win32_networkadapter|where {$_.deviceid -eq "$count"}|
Select-Object -ExpandProperty speed |Out-File -Append -Force "$log_path_dir\temp-speed.txt"
Get-WmiObject win32_networkadapter|where {$_.deviceid -eq "$count"}|
Select-Object -ExpandProperty netenabled |Out-File -Append -Force "$log_path_dir\temp-deviceenabled.txt"
Get-WmiObject win32_networkadapter|where {$_.deviceid -eq "$count"}|
Select-Object -ExpandProperty guid |Out-File -Append -Force "$log_path_dir\temp-guid.txt"
Get-WmiObject win32_networkadapter|where {$_.deviceid -eq "$count"}|
Select-Object -ExpandProperty Manufacturer |Out-File -Append -Force "$log_path_dir\temp-manufacturer.txt"
Get-WmiObject win32_networkadapter|where {$_.deviceid -eq "$count"}|
Select-Object -ExpandProperty ServiceName |Out-File -Append -Force "$log_path_dir\temp-drivername.txt"
#Get-WmiObject win32_networkadapter|where {$_.deviceid -eq "$count"}|
#Select-Object -ExpandProperty interfaceindex |Out-File "$log_dir_name\temp-interfaceindex.txt"
}

#export information for one cycle to log file "plug.log"
echo "Below are the infomation for the networks on this machine for $loop_count cycle!"|Out-File -Append -Force "$log_path"
echo "Below are the device name for the networks on this machine for $loop_count cycle!"|Out-File -Append -Force "$log_path"
Get-Content ".\$log_path_dir\base-devicename.txt"|Out-File -Append -Force "$log_path"
echo "Below are the macadderss for the networks on this machine for $loop_count cycle!"|Out-File -Append -Force "$log_path"
Get-Content ".\$log_path_dir\base-macaddress.txt"|Out-File -Append -Force "$log_path"
echo "Below are the speed for the networks on this machine for $loop_count cycle!"|Out-File -Append -Force "$log_path"
Get-Content ".\$log_path_dir\base-speed.txt"|Out-File -Append -Force "$log_path"
echo "Below are the device enabled for the networks on this machine for $loop_count cycle!"|Out-File -Append -Force "$log_path"
Get-Content ".\$log_path_dir\base-deviceenabled.txt"|Out-File -Append -Force "$log_path"
echo "Below are the guid for the networks on this machine for $loop_count cycle!"|Out-File -Append -Force "$log_path"
Get-Content ".\$log_path_dir\base-guid.txt"|Out-File -Append -Force "$log_path"
echo "Below are the manufacturer for the networks on this machine for $loop_count cycle!"|Out-File -Append -Force "$log_path"
Get-Content ".\$log_path_dir\base-manufacturer.txt"|Out-File -Append -Force "$log_path"
echo "Below are the drivername for the networks on this machine for $loop_count cycle!"|Out-File -Append -Force "$log_path"
Get-Content ".\$log_path_dir\base-drivername.txt"|Out-File -Append -Force "$log_path"

#get the filehash for files of base!
$hash_base_devicename=Get-FileHash -Path .\$log_path_dir\base-devicename.txt -Algorithm SHA256|Select-Object -ExpandProperty hash
$hash_base_macaddress=Get-FileHash -Path .\$log_path_dir\base-macaddress.txt -Algorithm SHA256|Select-Object -ExpandProperty hash
$hash_base_speed=Get-FileHash -Path .\$log_path_dir\base-speed.txt -Algorithm SHA256|Select-Object -ExpandProperty hash
$hash_base_deviceenabled=Get-FileHash -Path .\$log_path_dir\base-deviceenabled.txt -Algorithm SHA256|Select-Object -ExpandProperty hash
$hash_base_guid=Get-FileHash -Path .\$log_path_dir\base-guid.txt -Algorithm SHA256|Select-Object -ExpandProperty hash
$hash_base_manufacturer=Get-FileHash -Path .\$log_path_dir\base-manufacturer.txt -Algorithm SHA256|Select-Object -ExpandProperty hash
$hash_base_drivername=Get-FileHash -Path .\$log_path_dir\base-drivername.txt -Algorithm SHA256|Select-Object -ExpandProperty hash
#$hash_base_interfaceindex=Get-FileHash .\$log_dir_name\base-interfaceindex.txt|Select-Object -ExpandProperty hash
#get the filehash for files of temp!
$hash_temp_devicename=Get-FileHash -Path .\$log_path_dir\temp-devicename.txt -Algorithm SHA256|Select-Object -ExpandProperty hash
$hash_temp_macaddress=Get-FileHash -Path .\$log_path_dir\temp-macaddress.txt -Algorithm SHA256|Select-Object -ExpandProperty hash
$hash_temp_speed=Get-FileHash -Path .\$log_path_dir\temp-speed.txt -Algorithm SHA256|Select-Object -ExpandProperty hash
$hash_temp_deviceenabled=Get-FileHash -Path .\$log_path_dir\temp-deviceenabled.txt -Algorithm SHA256|Select-Object -ExpandProperty hash
$hash_temp_guid=Get-FileHash -Path .\$log_path_dir\temp-guid.txt -Algorithm SHA256|Select-Object -ExpandProperty hash
$hash_temp_manufacturer=Get-FileHash -Path .\$log_path_dir\temp-manufacturer.txt -Algorithm SHA256|Select-Object -ExpandProperty hash
$hash_temp_drivername=Get-FileHash -Path .\$log_path_dir\temp-drivername.txt -Algorithm SHA256|Select-Object -ExpandProperty hash
#$hash_temp_interfaceindex=Get-FileHash .\$log_dir_name\temp-interfaceindex.txt|Select-Object -ExpandProperty hash
#compare baseline and current status!
#compare devicename
if ($hash_base_devicename -eq $hash_temp_devicename)
{
echo "devicename check OK!"|Out-File -Append -Force "$log_path"
echo "OK" |Out-File -Append -Force "$log_path_dir\status.log"
}
else
{
echo "devicename check FAIL!"|Out-File -Append -Force "$log_path"
echo "FAIL" |Out-File -Append -Force "$log_path_dir\status.log"
}

#compare macaddress
if ($hash_base_macaddress -eq $hash_temp_macaddress)
{
echo "macaddress check OK!"|Out-File -Append -Force "$log_path"
echo "OK" |Out-File -Append -Force "$log_path_dir\status.log"
}
else
{
echo "macaddress check FAIL!"|Out-File -Append -Force "$log_path"
echo "FAIL" |Out-File -Append -Force "$log_path_dir\status.log"
}

#compare speed
if ($hash_base_speed -eq $hash_temp_speed)
{
echo "speed check OK!"|Out-File -Append -Force "$log_path"
echo "OK" |Out-File -Append -Force "$log_path_dir\status.log"
}
else
{
echo "speed check FAIL!"|Out-File -Append -Force "$log_path"
echo "FAIL" |Out-File -Append -Force "$log_path_dir\status.log"
}

#compare deviceenabled
if ($hash_base_deviceenabled -eq $hash_temp_deviceenabled)
{
echo "deviceenabled check OK!"|Out-File -Append -Force "$log_path"
echo "OK" |Out-File -Append -Force "$log_path_dir\status.log"
}
else
{
echo "deviceenabled check FAIL!"|Out-File -Append -Force "$log_path"
echo "FAIL" |Out-File -Append -Force "$log_path_dir\status.log"
}

#compare guid
if ($hash_base_guid -eq $hash_temp_guid)
{
echo "guid check OK!"|Out-File -Append -Force "$log_path"
echo "OK" |Out-File -Append -Force "$log_path_dir\status.log"
}
else
{
echo "guid check FAIL!"|Out-File -Append -Force "$log_path"
echo "FAIL" |Out-File -Append -Force "$log_path_dir\status.log"
}

#compare manufacturer
if ($hash_base_manufacturer -eq $hash_temp_manufacturer)
{
echo "manufacturer check OK!"|Out-File -Append -Force "$log_path"
echo "OK" |Out-File -Append -Force "$log_path_dir\status.log"
}
else
{
echo "manufacturer check FAIL!"|Out-File -Append -Force "$log_path"
echo "FAIL" |Out-File -Append -Force "$log_path_dir\status.log"
}

#compare drivername
if ($hash_base_drivername -eq $hash_temp_drivername)
{
echo "drivername check OK!"|Out-File -Append -Force "$log_path"
echo "OK" |Out-File -Append -Force "$log_path_dir\status.log"
}
else
{
echo "drivername check FAIL!"|Out-File -Append -Force "$log_path"
echo "FAIL" |Out-File -Append -Force "$log_path_dir\status.log"
}

$faillog=Get-Content ".\$log_path_dir\status.log"|Select-String -Pattern "FAIL"
if ($faillog.length -eq 0)
{
Write-Host "Baseline Check PASS!"  -ForegroundColor Green
echo "OK!"|Out-File -Append -Force "$log_path"
}
else
{
Write-Host "Baseline Check FAIL!"  -ForegroundColor Red
echo "FAIL!"|Out-File -Append -Force "$log_path"
}

#use ping to check link!
$result_ping_temp=(ping -S $ipaddress_in $ip_to_check).trim()|Select-String -Pattern "TTL="
$result_ping=$result_ping_temp.length
if ($result_ping -ne 0)
{
echo "ping check OK!"|Out-File -Append -Force "$log_path"
Write-Host "Link Status(ping) check PASS!" -ForegroundColor Green
}
else
{
echo "ping check FAIL!"|Out-File -Append -Force "$log_path"
Write-Host "Link Status(ping) check FAIL!" -ForegroundColor Red
}
Remove-Item ".\$log_path_dir\temp*" -Force -Recurse
Remove-Item ".\$log_path_dir\status.log" -Force -Recurse
}

function generate_base()
{
#show base infomation
Write-Host "Please check base network information of this machine!" -ForegroundColor Green
Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|Sort-Object -Property deviceid|Format-Table -Property name,
@{name='MacAddress';expression={$_.macaddress}},
@{name='Speed(bit/s)';expression={if($_.netenabled -eq "True"){$_.speed}else{"None"}}},
@{name='GUID';expression={$_.guid}},
@{name='Manufacturer';expression={$_.manufacturer}},
#@{name='Driver Name';expression={$_.servicename}},
@{name='Enabled';expression={$_.netenabled}}

$flag_base=Read-Host "If all OK,please input y/Y to continue; if not OK,please input n/N to end this test"

if (($flag_base -eq "y") -or ($flag_base -eq "Y"))
{
Write-Host "you chose to continue!" -ForegroundColor Green
}
elseif (($flag_base -eq "n") -or ($flag_base -eq "N"))
{
Write-Host "you chose to end this test!" -ForegroundColor Red
exit(255)
}
else
{
Write-Host "Invalid input! End the test!" -ForegroundColor Red
exit(255)
}

#get phycical network devices infomation to write!
$device_numbers=Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|
Select-Object -ExpandProperty deviceid|Sort-Object

foreach ($count in $device_numbers)
{
Get-WmiObject win32_networkadapter|where {$_.deviceid -eq "$count"}|
Select-Object -ExpandProperty name |Out-File -Append -Force "$log_path_dir\base-devicename.txt"
Get-WmiObject win32_networkadapter|where {$_.deviceid -eq "$count"}|
Select-Object -ExpandProperty macaddress |Out-File -Append -Force "$log_path_dir\base-macaddress.txt"
Get-WmiObject win32_networkadapter|where {$_.deviceid -eq "$count"}|
Select-Object -ExpandProperty speed |Out-File -Append -Force "$log_path_dir\base-speed.txt"
Get-WmiObject win32_networkadapter|where {$_.deviceid -eq "$count"}|
Select-Object -ExpandProperty netenabled |Out-File -Append -Force "$log_path_dir\base-deviceenabled.txt"
Get-WmiObject win32_networkadapter|where {$_.deviceid -eq "$count"}|
Select-Object -ExpandProperty guid |Out-File -Append -Force "$log_path_dir\base-guid.txt"
Get-WmiObject win32_networkadapter|where {$_.deviceid -eq "$count"}|
Select-Object -ExpandProperty Manufacturer |Out-File -Append -Force "$log_path_dir\base-manufacturer.txt"
Get-WmiObject win32_networkadapter|where {$_.deviceid -eq "$count"}|
Select-Object -ExpandProperty ServiceName |Out-File -Append -Force "$log_path_dir\base-drivername.txt"
#Get-WmiObject win32_networkadapter|where {$_.deviceid -eq "$count"}|
#Select-Object -ExpandProperty interfaceindex |Out-File -Append -Force "$log_dir_name\base-interfaceindex.txt"
}
#export baseline info to log file "plug.log"
echo "Below are the baseline infomation for the networks on this machine!"|Out-File -Append -Force "$log_path"
echo "Below are the baseline device name for the networks on this machine!"|Out-File -Append -Force "$log_path"
Get-Content ".\$log_path_dir\base-devicename.txt"|Out-File -Append -Force "$log_path"
echo "Below are the baseline macaddress for the networks on this machine!"|Out-File -Append -Force "$log_path"
Get-Content ".\$log_path_dir\base-macaddress.txt"|Out-File -Append -Force "$log_path"
echo "Below are the baseline speed for the networks on this machine!"|Out-File -Append -Force "$log_path"
Get-Content ".\$log_path_dir\base-speed.txt"|Out-File -Append -Force "$log_path"
echo "Below are the baseline device enabled for the networks on this machine!"|Out-File -Append -Force "$log_path"
Get-Content ".\$log_path_dir\base-deviceenabled.txt"|Out-File -Append -Force "$log_path"
echo "Below are the baseline guid for the networks on this machine!"|Out-File -Append -Force "$log_path"
Get-Content ".\$log_path_dir\base-guid.txt"|Out-File -Append -Force "$log_path"
echo "Below are the baselinemanufacturer for the networks on this machine!"|Out-File -Append -Force "$log_path"
Get-Content ".\$log_path_dir\base-manufacturer.txt"|Out-File -Append -Force "$log_path"
echo "Below are the baseline driver name for the networks on this machine!"|Out-File -Append -Force "$log_path"
Get-Content ".\$log_path_dir\base-drivername.txt"|Out-File -Append -Force "$log_path"
}

#test log directory
$current_path=Split-Path -Parent $MyInvocation.MyCommand.Definition
if (-not (Test-Path ${current_path}\log -PathType Container))
{
$null=New-Item -Path "${current_path}" -Name log -ItemType Directory 
}
#create log file
$current_date=Get-Date -Format yyyyMMddHHmmss
$log_dir_name="${current_date}_SIT_NETPLUG_TEST_WIN"
$log_file_name="${current_date}_SIT_NETPLUG_TEST_WIN.log"
$log_path_dir=".\log\$log_dir_name"
$log_path="${log_path_dir}\$log_file_name"
$null=New-Item -Path ".\log\" -Name "$log_dir_name" -ItemType Directory
$null=New-Item -Path "$log_path_dir" -Name "$log_file_name" -ItemType File
echo "Start Test Time!"|Out-File -Append -Force -Encoding unicode $log_path
echo $current_date|Out-File -Append -Force -Encoding unicode $log_path
Write-Host "Start Test time $current_date"
$input_length = $args.Length
if ($input_length -ne 2)
{
Write-Host "ERROR! Input parameter number is incorrect!" -ForegroundColor Red
Write-Host "Usage: .\SUT_001_SIT_NETPLUG_TEST_WIN_V001.ps1 target_ip total_loop!" -ForegroundColor Green
echo "ERROR! Input parameter number is incorrect!" |Out-File -Force -Append -Encoding unicode $log_path
echo "Usage: .\SUT_001_SIT_NETPLUG_TEST_WIN_V001.ps1 target_ip total_loop!"|Out-File -Force -Append -Encoding unicode $log_path
exit(255)
}
else
{
$ip_to_check=$args[0]
$total_loop=$args[1]
$flag_plug=1
$DEV_name_out_temp_1=1
$DEV_name_out_temp_2=1
$DEV_name_in_temp_1=1
$DEV_name_in_temp_2=1

$DEV_name_out,
$DEV_name_in,
[int]$number_true,
[int]$i=0

echo "1"|Out-File -Force "$log_path_dir\count.log"
#clear eventlog
Clear-EventLog -LogName System 
#generate baseline
generate_base
Write-Host "Baseline generated succefully! Please plug out the network cable!"

$base_name_for_out=Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|
where{$_.netenabled -eq "True"}|Select-Object -ExpandProperty name

#get device number for enabled & disabled.
$base_info=Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|Select-Object -ExpandProperty netenabled
$number_true=($base_info|Select-String -Pattern "True").length
$total_loop = $total_loop - 1
while (0 -ne 1)
{
if ($i -gt $total_loop)
{
break
}
else
{
#plug out test
Start-Sleep -Seconds 1
$temp_info=Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|Select-Object -ExpandProperty netenabled
Start-Sleep -Seconds 1
$temp_number_true = ($temp_info| Select-String -Pattern "True").length
if ($temp_number_true -lt $number_true)
{
if ($flag_plug -eq 1)
{
#genegate base_name_for_out to check which one is pluged_out.use netenabled=True
Start-Sleep -Seconds 1
plug_out
$DEV_name_out_temp_2=$DEV_name_out_temp_1;
$DEV_name_out_temp_1=$DEV_name_out;
Clear-EventLog -LogName System
Start-Sleep -Seconds 1
$base_name_for_in=Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|
where{$_.netenabled -ne "True"}|Select-Object -ExpandProperty name
}
}

#plug in test!
Start-Sleep -Seconds 1
if ($temp_number_true -eq $number_true)
{
if ($flag_plug -eq 0)
{
plug_in;
$DEV_name_in_temp_2=$DEV_name_in_temp_1;
$DEV_name_in_temp_1=$DEV_name_in;
Clear-EventLog -LogName System
Start-Sleep -Seconds 1
$base_name_for_out=Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|
where{$_.netenabled -eq "True"}|Select-Object -ExpandProperty name

if ($DEV_name_in -eq $DEV_name_in_temp_2)
{
$i=$i+1
Write-Host "This is "-NoNewline
Write-Host "$i" -NoNewline -ForegroundColor Green
Write-Host " times!" 
Write-Host "Please plug it out!"
}
else
{
[int]$i=1
Write-Host "This is " -NoNewline
Write-Host "$i" -NoNewline -ForegroundColor Green
Write-Host " times!" 
Write-Host "Please plug it out!"
echo $i |Out-File -Force "$log_path_dir\count.log"
}
}
}
continue
}
}
$end_date=Get-Date -Format yyyyMMddHHmmss
echo "End Test Time!"|Out-File -Append -Force -Encoding unicode $log_path
echo $end_date|Out-File -Append -Force -Encoding unicode $log_path
Write-Host "End Test time $end_date"
exit(0)
}