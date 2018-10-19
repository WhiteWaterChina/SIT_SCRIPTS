<#
network plug out and in, and collect information at the same time !
Author:yanshuo@inspur.com
#>
[CmdletBinding()]
#$ErrorActionPreference="SilentlyContinue"
param (
#[parameter(Mandatory=$true)]
#[string]$Global:driver_name,
[parameter(Mandatory=$true)]
[string]$Global:ip_to_check,
$DEV_name_out,
$DEV_name_in,
$DEV_name_out_temp_1,
$DEV_name_out_temp_2,
$DEV_name_in_temp_1,
$DEV_name_in_temp_2,
$flag_plug=1,
[int]$i=0
)

function plug_out()
{
while (0 -ne 1)
{
#get device name that being pluged out
$DEV_name_out_temp=Get-EventLog -LogName System -InstanceId 2684616731 -ErrorAction SilentlyContinue
if ($DEV_name_out_temp)
{
$DEV_name_out=((($DEV_name_out_temp|Select-Object -ExpandProperty message).tostring()).trim()).split("`r")[0]
}
Start-Sleep -Seconds 1
if ($DEV_name_out.length -ne 0)
{
break
}
}
#show out
Write-Host $DEV_name_out -NoNewline -ForegroundColor Green
Write-Host " is plug out! "
Write-Host "Please plug it in!"
#$flag_plug=0
Set-Variable -Name flag_plug -Value 0 -Scope 1

}

function plug_in()
{
while (0 -ne 1)
{
#get device name that being pluged in

$DEV_name_in_temp=Get-EventLog -LogName System -InstanceId 1610874912 -ErrorAction SilentlyContinue
if ($DEV_name_in_temp)
{
$DEV_name_in=((($DEV_name_in_temp|Select-Object -ExpandProperty message).tostring()).trim()).split("`r")[0]
}
Start-Sleep -Seconds 1
if ($DEV_name_in.length -ne 0)
{
break
}
}
#$flag_plug=1
Set-Variable -Name flag_plug -Value 1 -Scope 1
#get ipaddress for the device that pluged in
#first find out the interfaceindex according to the device name
$interfaceindex=Get-WmiObject win32_networkadapter|where {$_.name -eq "$DEV_name_in"}|
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
Write-Host " is plug in! Current IPAddress is " -NoNewline
Write-Host $ipaddress_in  -ForegroundColor Green
Write-Host "Index of this port is " -NoNewline
Write-Host $deviceid_index -NoNewline -ForegroundColor Green
Write-Host " ! Current Speed is " -NoNewline
Write-Host $speed_this_port -NoNewline -ForegroundColor Green
Write-Host " bit/s!"
#get device status for current time!
$device_numbers=Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|
Select-Object -ExpandProperty deviceid|Sort-Object
foreach ($count in $device_numbers)
{
Get-WmiObject win32_networkadapter|where {$_.deviceid -eq "$count"}|
Select-Object -ExpandProperty name |Out-File -Append -Force "temp-devicename.txt"
Get-WmiObject win32_networkadapter|where {$_.deviceid -eq "$count"}|
Select-Object -ExpandProperty macaddress |Out-File -Append -Force "temp-macaddress.txt"
Get-WmiObject win32_networkadapter|where {$_.deviceid -eq "$count"}|
Select-Object -ExpandProperty speed |Out-File -Append -Force "temp-speed.txt"
Get-WmiObject win32_networkadapter|where {$_.deviceid -eq "$count"}|
Select-Object -ExpandProperty netenabled |Out-File -Append -Force "temp-deviceenabled.txt"
Get-WmiObject win32_networkadapter|where {$_.deviceid -eq "$count"}|
Select-Object -ExpandProperty guid |Out-File -Append -Force "temp-guid.txt"
Get-WmiObject win32_networkadapter|where {$_.deviceid -eq "$count"}|
Select-Object -ExpandProperty Manufacturer |Out-File -Append -Force "temp-manufacturer.txt"
Get-WmiObject win32_networkadapter|where {$_.deviceid -eq "$count"}|
Select-Object -ExpandProperty ServiceName |Out-File -Append -Force "temp-drivername.txt"
#Get-WmiObject win32_networkadapter|where {$_.deviceid -eq "$count"}|
#Select-Object -ExpandProperty interfaceindex |Out-File "temp-interfaceindex.txt"
}

#export information for one cycle to log file "plug.log"
echo "Below are the infomation for the networks on this machinefor one cycle!"|Out-File -Append -Force "plug.log"
echo "Below are the device name for the networks on this machine for one cycle!"|Out-File -Append -Force "plug.log"
Get-Content ".\base-devicename.txt"|Out-File -Append -Force "plug.log"
echo "Below are the macadderss for the networks on this machine for one cycle!"|Out-File -Append -Force "plug.log"
Get-Content ".\base-macaddress.txt"|Out-File -Append -Force "plug.log"
echo "Below are the speed for the networks on this machine for one cycle!"|Out-File -Append -Force "plug.log"
Get-Content ".\base-speed.txt"|Out-File -Append -Force "plug.log"
echo "Below are the device enabled for the networks on this machine for one cycle!"|Out-File -Append -Force "plug.log"
Get-Content ".\base-deviceenabled.txt"|Out-File -Append -Force "plug.log"
echo "Below are the guid for the networks on this machine for one cycle!"|Out-File -Append -Force "plug.log"
Get-Content ".\base-guid.txt"|Out-File -Append -Force "plug.log"
echo "Below are the manufacturer for the networks on this machine for one cycle!"|Out-File -Append -Force "plug.log"
Get-Content ".\base-manufacturer.txt"|Out-File -Append -Force "plug.log"
echo "Below are the drivername for the networks on this machine for one cycle!"|Out-File -Append -Force "plug.log"
Get-Content ".\base-drivername.txt"|Out-File -Append -Force "plug.log"
#echo "Below are the interfaceindex for the networks on this machine for one cycle!"|Out-File -Append -Force "plug.log"
#Get-Content ".\base-interfaceindex.txt"|Out-File -Append -Force "plug.log"

#get the filehash for files of base!
$hash_base_devicename=Get-FileHash -Path .\base-devicename.txt -Algorithm SHA256|Select-Object -ExpandProperty hash
$hash_base_macaddress=Get-FileHash -Path .\base-macaddress.txt -Algorithm SHA256|Select-Object -ExpandProperty hash
$hash_base_speed=Get-FileHash -Path .\base-speed.txt -Algorithm SHA256|Select-Object -ExpandProperty hash
$hash_base_deviceenabled=Get-FileHash -Path .\base-deviceenabled.txt -Algorithm SHA256|Select-Object -ExpandProperty hash
$hash_base_guid=Get-FileHash -Path .\base-guid.txt -Algorithm SHA256|Select-Object -ExpandProperty hash
$hash_base_manufacturer=Get-FileHash -Path .\base-manufacturer.txt -Algorithm SHA256|Select-Object -ExpandProperty hash
$hash_base_drivername=Get-FileHash -Path .\base-drivername.txt -Algorithm SHA256|Select-Object -ExpandProperty hash
#$hash_base_interfaceindex=Get-FileHash .\base-interfaceindex.txt|Select-Object -ExpandProperty hash
#get the filehash for files of temp!
$hash_temp_devicename=Get-FileHash -Path .\temp-devicename.txt -Algorithm SHA256|Select-Object -ExpandProperty hash
$hash_temp_macaddress=Get-FileHash -Path .\temp-macaddress.txt -Algorithm SHA256|Select-Object -ExpandProperty hash
$hash_temp_speed=Get-FileHash -Path .\temp-speed.txt -Algorithm SHA256|Select-Object -ExpandProperty hash
$hash_temp_deviceenabled=Get-FileHash -Path .\temp-deviceenabled.txt -Algorithm SHA256|Select-Object -ExpandProperty hash
$hash_temp_guid=Get-FileHash -Path .\temp-guid.txt -Algorithm SHA256|Select-Object -ExpandProperty hash
$hash_temp_manufacturer=Get-FileHash -Path .\temp-manufacturer.txt -Algorithm SHA256|Select-Object -ExpandProperty hash
$hash_temp_drivername=Get-FileHash -Path .\temp-drivername.txt -Algorithm SHA256|Select-Object -ExpandProperty hash
#$hash_temp_interfaceindex=Get-FileHash .\temp-interfaceindex.txt|Select-Object -ExpandProperty hash
#compare baseline and current status!
#compare devicename
if ($hash_base_devicename -eq $hash_temp_devicename)
{
echo "devicename check OK!"|Out-File -Append -Force "plug.log"
echo "OK" |Out-File -Append -Force "status.log"
}
else
{
echo "devicename check FAIL!"|Out-File -Append -Force "plug.log"
echo "FAIL" |Out-File -Append -Force "status.log"
}

#compare macaddress
if ($hash_base_macaddress -eq $hash_temp_macaddress)
{
echo "macaddress check OK!"|Out-File -Append -Force "plug.log"
echo "OK" |Out-File -Append -Force "status.log"
}
else
{
echo "macaddress check FAIL!"|Out-File -Append -Force "plug.log"
echo "FAIL" |Out-File -Append -Force "status.log"
}

#compare speed
if ($hash_base_speed -eq $hash_temp_speed)
{
echo "speed check OK!"|Out-File -Append -Force "plug.log"
echo "OK" |Out-File -Append -Force "status.log"
}
else
{
echo "speed check FAIL!"|Out-File -Append -Force "plug.log"
echo "FAIL" |Out-File -Append -Force "status.log"
}

#compare deviceenabled
if ($hash_base_deviceenabled -eq $hash_temp_deviceenabled)
{
echo "deviceenabled check OK!"|Out-File -Append -Force "plug.log"
echo "OK" |Out-File -Append -Force "status.log"
}
else
{
echo "deviceenabled check FAIL!"|Out-File -Append -Force "plug.log"
echo "FAIL" |Out-File -Append -Force "status.log"
}

#compare guid
if ($hash_base_guid -eq $hash_temp_guid)
{
echo "guid check OK!"|Out-File -Append -Force "plug.log"
echo "OK" |Out-File -Append -Force "status.log"
}
else
{
echo "guid check FAIL!"|Out-File -Append -Force "plug.log"
echo "FAIL" |Out-File -Append -Force "status.log"
}

#compare manufacturer
if ($hash_base_manufacturer -eq $hash_temp_manufacturer)
{
echo "manufacturer check OK!"|Out-File -Append -Force "plug.log"
echo "OK" |Out-File -Append -Force "status.log"
}
else
{
echo "manufacturer check FAIL!"|Out-File -Append -Force "plug.log"
echo "FAIL" |Out-File -Append -Force "status.log"
}

#compare drivername
if ($hash_base_drivername -eq $hash_temp_drivername)
{
echo "drivername check OK!"|Out-File -Append -Force "plug.log"
echo "OK" |Out-File -Append -Force "status.log"
}
else
{
echo "drivername check FAIL!"|Out-File -Append -Force "plug.log"
echo "FAIL" |Out-File -Append -Force "status.log"
}

#compare interfaceindex
#if ($hash_base_interfaceindex -eq $hash_temp_interfaceindex)
#{
#echo "interfaceindex check OK!"|Out-File -Append -Force "plug.log"
#echo "OK" |Out-File -Append -Force "status.log"
#}
#else
#{
#echo "interfaceindex check FAIL!"|Out-File "plug.log"
#echo "FAIL" |Out-File -Append -Force "status.log"
#}

#use ping to check link!
$result_ping_temp=(ping -S $ipaddress_in $ip_to_check).trim()|Select-String -Pattern "TTL="
$result_ping=$result_ping_temp.length
if ($result_ping -ne 0)
{
echo "ping check OK!"|Out-File -Append -Force "plug.log"
echo "OK" |Out-File -Append -Force "status.log"
}
else
{
echo "ping check FAIL!"|Out-File -Append -Force "plug.log"
echo "FAIL" |Out-File -Append -Force "status.log"
}

$faillog=Get-Content ".\status.log"|Select-String -Pattern "FAIL"
if ($faillog.length -eq 0)
{
Write-Host "PASS!"  -ForegroundColor Green
echo "OK!"|Out-File -Append -Force "plug.log"
}
else
{
Write-Host "FAIL!"  -ForegroundColor Red
echo "FAIL!"|Out-File -Append -Force "plug.log"
}
Remove-Item ".\temp*" -Force -Recurse
Remove-Item ".\status.log" -Force -Recurse

}

function generate_base()
{
#get phycical network devices numbers
$device_numbers=Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|
Select-Object -ExpandProperty deviceid|Sort-Object
foreach ($count in $device_numbers)
{
Get-WmiObject win32_networkadapter|where {$_.deviceid -eq "$count"}|
Select-Object -ExpandProperty name |Out-File -Append -Force "base-devicename.txt"
Get-WmiObject win32_networkadapter|where {$_.deviceid -eq "$count"}|
Select-Object -ExpandProperty macaddress |Out-File -Append -Force "base-macaddress.txt"
Get-WmiObject win32_networkadapter|where {$_.deviceid -eq "$count"}|
Select-Object -ExpandProperty speed |Out-File -Append -Force "base-speed.txt"
Get-WmiObject win32_networkadapter|where {$_.deviceid -eq "$count"}|
Select-Object -ExpandProperty netenabled |Out-File -Append -Force "base-deviceenabled.txt"
Get-WmiObject win32_networkadapter|where {$_.deviceid -eq "$count"}|
Select-Object -ExpandProperty guid |Out-File -Append -Force "base-guid.txt"
Get-WmiObject win32_networkadapter|where {$_.deviceid -eq "$count"}|
Select-Object -ExpandProperty Manufacturer |Out-File -Append -Force "base-manufacturer.txt"
Get-WmiObject win32_networkadapter|where {$_.deviceid -eq "$count"}|
Select-Object -ExpandProperty ServiceName |Out-File -Append -Force "base-drivername.txt"
#Get-WmiObject win32_networkadapter|where {$_.deviceid -eq "$count"}|
#Select-Object -ExpandProperty interfaceindex |Out-File -Append -Force "base-interfaceindex.txt"
}
#export baseline info to log file "plug.log"
echo "Below are the baseline infomation for the networks on this machine!"|Out-File -Append -Force "plug.log"
echo "Below are the baseline device name for the networks on this machine!"|Out-File -Append -Force "plug.log"
Get-Content ".\base-devicename.txt"|Out-File -Append -Force "plug.log"
echo "Below are the baseline macaddress for the networks on this machine!"|Out-File -Append -Force "plug.log"
Get-Content ".\base-macaddress.txt"|Out-File -Append -Force "plug.log"
echo "Below are the baseline speed for the networks on this machine!"|Out-File -Append -Force "plug.log"
Get-Content ".\base-speed.txt"|Out-File -Append -Force "plug.log"
echo "Below are the baseline device enabled for the networks on this machine!"|Out-File -Append -Force "plug.log"
Get-Content ".\base-deviceenabled.txt"|Out-File -Append -Force "plug.log"
echo "Below are the baseline guid for the networks on this machine!"|Out-File -Append -Force "plug.log"
Get-Content ".\base-guid.txt"|Out-File -Append -Force "plug.log"
echo "Below are the baselinemanufacturer for the networks on this machine!"|Out-File -Append -Force "plug.log"
Get-Content ".\base-manufacturer.txt"|Out-File -Append -Force "plug.log"
echo "Below are the baseline driver name for the networks on this machine!"|Out-File -Append -Force "plug.log"
Get-Content ".\base-drivername.txt"|Out-File -Append -Force "plug.log"
#echo "Below are the baseline interfaceindex for the networks on this machine!"|Out-File -Append -Force "plug.log"
#Get-Content ".\base-interfaceindex.txt"|Out-File -Append -Force "plug.log"
}

#main
$flag_plug=1
$DEV_name_out_temp_1=1
$DEV_name_out_temp_2=1
$DEV_name_in_temp_1=1
$DEV_name_in_temp_2=1
#clear eventlog
Clear-EventLog -LogName System 
#generate baseline
generate_base
Write-Host "Baseline generated succefully! Please plug out the network cable!"


while (0 -ne 1)
{
#plug out test
Start-Sleep -Seconds 1
$temp_out_temp=(Get-EventLog -LogName System -InstanceId 2684616731 -ErrorAction SilentlyContinue)
if ($temp_out_temp)
{
$temp_out=(((($temp_out_temp|Select-Object -ExpandProperty message).tostring()).trim()).split("`r")[2])|
Select-String -Pattern "disconnect"
}

if ($temp_out.length -ne 0)
{
if ($flag_plug -eq 1)
{
plug_out
$DEV_name_out_temp_2=$DEV_name_out_temp_1;
$DEV_name_out_temp_1=$DEV_name_out;
Clear-EventLog -LogName System
Start-Sleep -Seconds 1
}
}
#del Variable:temp_out -Force
Remove-Variable -Name temp_out -Force -ErrorAction SilentlyContinue

#plug in test!
Start-Sleep -Seconds 1
$temp_in_temp=Get-EventLog -LogName System -InstanceId 1610874912 -ErrorAction SilentlyContinue
if ($temp_in_temp)
{
$temp_in=((($temp_in_temp|Select-Object -ExpandProperty message).tostring()).trim()).split("`r")[2]|
Select-String -Pattern "establish"
}

if ($temp_in.length -ne 0)
{
if ($flag_plug -eq 0)
{
plug_in;
$DEV_name_in_temp_2=$DEV_name_in_temp_1;
$DEV_name_in_temp_1=$DEV_name_in;
Clear-EventLog -LogName System
Start-Sleep -Seconds 1

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
}
}
}
#del Variable:temp_out -Force
Remove-Variable -Name temp_in -Force -ErrorAction SilentlyContinue
continue
}
