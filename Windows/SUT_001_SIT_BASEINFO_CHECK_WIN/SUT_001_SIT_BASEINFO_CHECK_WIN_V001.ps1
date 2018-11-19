<#
Name:SUT_001_SIT_BASEINFO_CHECK_WIN
Author:yanshuo
Revision:
Version:A01
Date:2017-11-9
Tracelist:A01-->First Version
Function:获取windows系统下的base信息，如CPU、内存、网络等。
Parameter:None
Usage:powershell SUT_001_SIT_BASEINFO_CHECK_WIN
#>
#set windows buffer
$host.UI.RawUI.BufferSize = new-object System.Management.Automation.Host.Size(175,20000)
#$null=New-ItemProperty -Path HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -PropertyType DWord -Value 0 -Force
#create log file
$current_path=Split-Path -Parent $MyInvocation.MyCommand.Definition
if (-not (Test-Path ${current_path}\log -PathType Container))
{
$null=New-Item -Path "${current_path}" -Name log -ItemType Directory 
}
#get time to create log file
$current_date=Get-Date -Format yyyyMMddHHmmss
$log_file_name = "${current_date}_SIT_BASEINFO_CHECK_WIN.log"
$log_path = ".\log\$log_file_name"
$null=New-Item -Path ".\log\" -Name "$log_file_name" -ItemType File
echo "This is the log file for WINDOWS BASEINFO!"|Out-File -Force -Append "$log_path"

#OS Name
Write-Host "Below is the OS Name!" -ForegroundColor Green
$os_name=Get-WmiObject -Class Win32_OperatingSystem | Select-Object -ExpandProperty Caption
$os_name
echo "Below is the OS Name"|Out-File -Append -Force "$log_path"
$os_name|Out-File -Append -Force "$log_path"

#OS  Version
Write-Host "Below is the OS Main Version!" -ForegroundColor Green
$null=(Get-WmiObject -Class Win32_OperatingSystem|Select-Object -ExpandProperty Version) -match "\d+.\d+"
$Matches[0]
echo "Below is the OS Main Version"|Out-File -Append -Force "$log_path"
$Matches[0]|Out-File -Append -Force "$log_path"

#CPUinfo
#show info to the screen!
Write-Host "Below is the CPU Info!" -ForegroundColor Green
#Write-Host "Below is the CPU Name of Each CPU!" -ForegroundColor Green
#Get-WmiObject win32_processor|where {$_.status -eq "OK"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty Name
#Write-Host "Below is the CPU Core Number of Each CPU!" -ForegroundColor Green
#Get-WmiObject win32_processor|where {$_.status -eq "OK"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty numberofcores
#Write-Host "Below is the CPU Threads Number of Each CPU!" -ForegroundColor Green
#Get-WmiObject win32_processor|where {$_.status -eq "OK"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty NumberOfLogicalProcessors
Get-WmiObject win32_processor|where {$_.status -eq "OK"}|Format-Table @{name="Position";expression={$_.deviceid}}, @{name="Model";expression={$_.name}},@{name="HardwareCores";expression={$_.numberofcores}},@{name="LogicalCores";expression={$_.NumberOfLogicalProcessors}},@{name="MaxSpeed(MHz)";expression={$_.MaxClockSpeed}},@{name="L2CacheSize";expression={$_.L2CacheSize}},@{name="L3CacheSize";expression={$_.L3CacheSize}}

#write info to the log file!
echo "Below is the CPU Info"|Out-File -Append -Force "$log_path"
#echo "Below is the CPU Name!" |Out-File -Append -Force "$log_path"
#(Get-WmiObject win32_processor|where {$_.status -eq "OK"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty Name)|Out-File -Append -Force "$log_path"
#echo "Below is the CPU Core Number!"|Out-File -Append -Force "$log_path"
#(Get-WmiObject win32_processor|where {$_.status -eq "OK"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty numberofcores)|Out-File -Append -Force "$log_path"
#echo "Below is the CPU Threads Number!"|Out-File -Append -Force "$log_path"
#(Get-WmiObject win32_processor|where {$_.status -eq "OK"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty NumberOfLogicalProcessors)|Out-File -Append -Force "$log_path"
Get-WmiObject win32_processor|where {$_.status -eq "OK"}|Format-Table @{name="Position";expression={$_.deviceid}}, @{name="Model";expression={$_.name}},@{name="HardwareCores";expression={$_.numberofcores}},@{name="LogicalCores";expression={$_.NumberOfLogicalProcessors}},@{name="MaxSpeed(MHz)";expression={$_.MaxClockSpeed}},@{name="L2CacheSize";expression={$_.L2CacheSize}},@{name="L3CacheSize";expression={$_.L3CacheSize}}|Out-File -Append -Force "$log_path"
#mem info
Write-Host "Below is the MEM Info!" -ForegroundColor Green
msinfo32 /report c:\sysinfo.txt
Start-Sleep -Seconds 60
$sysinfo=Get-Content c:\sysinfo.txt
$lan_version=Get-WmiObject -Class Win32_OperatingSystem|Select-Object -ExpandProperty muilanguages
if ($lan_version -eq "zh-CN")
{
$mem_info=$sysinfo -match "已安装的物理内存"
}
elseif ($lan_version -eq "en-US")
{
$mem_info=$sysinfo -match "Installed Physical Memory"
}
$mem_info
echo "Below is the MEM Info"|Out-File -Append -Force "$log_path"
$mem_info|Out-File -Append -Force "$log_path"

#disk info
#show info to the screen!
Write-Host "Below is the DISK Info!" -ForegroundColor Green
#Write-Host "Below is the DISK Name!" -ForegroundColor Green
#Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid |Select-Object -ExpandProperty Deviceid
#Write-Host "Below is the DISK Size(KB)!" -ForegroundColor Green
#(Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid |Select-Object -ExpandProperty Size)|ForEach-Object{$_ / 1GB -as [int]}
#Write-Host "Below is the DISK Firmware!" -ForegroundColor Green
#Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid |Select-Object -ExpandProperty firmwarerevision
#Write-Host "Below is the DISK Model!" -ForegroundColor Green
#Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid |Select-Object -ExpandProperty model
#Write-Host "Below is the DISK SerialNumber!" -ForegroundColor Green
#(Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid |Select-Object -ExpandProperty serialnumber)|ForEach-Object{$_.Trim()}
Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid |Format-Table DeviceId, @{name="Size";expression={$_.size / 1GB -as [int]}}, FirmwareRevision, Model, SerialNumber
#write info to the log file!
echo "Below is the DISK Info"|Out-File -Append -Force "$log_path"
#echo "Below is the DISK Name!"|Out-File -Append -Force "$log_path"
#(Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid |Select-Object -ExpandProperty Deviceid)|Out-File -Append -Force "$log_path"
#echo "Below is the DISK Size(KB)!"|Out-File -Append -Force "$log_path"
#((Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid |Select-Object -ExpandProperty Size)|ForEach-Object{$_ / 1GB -as [int]})|Out-File -Append -Force "$log_path"
#echo "Below is the DISK Firmware!" |Out-File -Append -Force "$log_path"
#(Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid |Select-Object -ExpandProperty firmwarerevision)|Out-File -Append -Force "$log_path"
#echo "Below is the DISK Model!" |Out-File -Append -Force "$log_path"
#(Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid |Select-Object -ExpandProperty model)|Out-File -Append -Force "$log_path"
#echo "Below is the DISK SerialNumber!"|Out-File -Append -Force "$log_path"
#(Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid |Select-Object -ExpandProperty serialnumber)|ForEach-Object{$_.Trim()})|Out-File -Append -Force "$log_path"
(Get-WmiObject win32_diskdrive|where {$_.status -eq "OK"}|Sort-Object -Property deviceid |Format-Table DeviceId,  @{name="Size";expression={$_.size / 1GB -as [int]}}, FirmwareRevision, Model, SerialNumber)|Out-File -Append -Force "$log_path"

#net info
#show info to the screen!
Write-Host "Below is the Network Info!" -ForegroundColor Green
#Write-Host "Below is the Network Name!" -ForegroundColor Green
#Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty Name
#Write-Host "Below is the Network MAC Address!" -ForegroundColor Green
#Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty macaddress
#Write-Host "Below is the Network Speed(bitS)!" -ForegroundColor Green
#Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|Sort-Object -Property deviceid|where {if($_.netenabled -eq "True"){Write-Host ($_.speed)}else{Write-Host "None(Not Enabled!)"}}
#Write-Host "Below is the Network Manufacturer!" -ForegroundColor Green
#Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty Manufacturer
Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|Sort-Object -Property deviceid|Format-Table Name, MacAddress,@{name="Speed";expression={if($_.netenabled -eq "True"){$_.speed}else{"None(Not Enabled!)"}}}, Manufacturer
#write info to the log file!
echo "Below is the Network Info"|Out-File -Append -Force "$log_path"
#echo "Below is the Network Name!" |Out-File -Append -Force "$log_path"
#(Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty Name)|Out-File -Append -Force "$log_path"
#echo "Below is the Network MAC Address!" |Out-File -Append -Force "$log_path"
#(Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty macaddress)|Out-File -Append -Force "$log_path"
#echo "Below is the Network Speed(bitS)!"|Out-File -Append -Force "$log_path"
#(Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|Sort-Object -Property deviceid|where {if($_.netenabled -eq "True"){echo ($_.speed)|Out-File -Append -Force "$log_path"}else{echo "None(Not Enabled!)"|Out-File -Append -Force "$log_path"}})
#echo "Below is the Network Manufacturer!" |Out-File -Append -Force "$log_path"
#(Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|Sort-Object -Property deviceid|Select-Object -ExpandProperty Manufacturer)|Out-File -Append -Force "$log_path"
(Get-WmiObject win32_networkadapter|where {$_.physicaladapter -eq "True"}|Sort-Object -Property deviceid|Format-Table Name, MacAddress,@{name="Speed";expression={if($_.netenabled -eq "True"){$_.speed}else{"None(Not Enabled!)"}}}, Manufacturer)|Out-File -Append -Force "$log_path"
exit(0)