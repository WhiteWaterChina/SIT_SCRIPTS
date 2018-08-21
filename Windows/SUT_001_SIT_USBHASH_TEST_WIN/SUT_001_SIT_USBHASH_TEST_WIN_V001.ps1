<#
Name:SUT_001_SIT_USBHASH_TEST_WIN
Author:yanshuo
Revision:
Version:V001
Date:2018-01-10
Tracelist:V001-->First Version
Function:在windows下测试源文件、从硬盘拷贝到USB、然后再拷贝回到硬盘的三次测试文件HASH值是否相同。
Parameter_1:usb path
Parameter_2:disk path
Parameter_3:loop count
Usage:SUT_001_SIT_USBHASH_TEST_WIN usb_path disk_path loop_count
Example: SUT_001_SIT_USBHASH_TEST_WIN h:\ c:\test 3
#>

#test log directory
$current_path=Split-Path -Parent $MyInvocation.MyCommand.Definition
if (-not (Test-Path ${current_path}\log -PathType Container))
{
$null=New-Item -Path "${current_path}" -Name log -ItemType Directory 
}
#create log file
$current_date=Get-Date -Format yyyyMMddHHmmss
$log_dir_name="${current_date}_SIT_USBHASH_TEST_WIN"
$log_file_name="${current_date}_SIT_USBHASH_TEST_WIN.log"
$log_path_dir="${current_path}\log\$log_dir_name"
$log_path="${log_path_dir}\$log_file_name"
$null=New-Item -Path ".\log\" -Name "$log_dir_name" -ItemType Directory
$null=New-Item -Path "$log_path_dir" -Name "$log_file_name" -ItemType File
echo "Start PTU Time!Start time:"|Out-File -Append -Force -Encoding unicode $log_path
echo $current_date|Out-File -Append -Force -Encoding unicode $log_path

$input_length=$args.Length

if ($input_length -ne 3)
{
Write-Host "ERROR! Input parameter number is incorrect!" -ForegroundColor Red
Write-Host "Usage: .\usbtest.ps1 usb_path disk_path loop_count!" -ForegroundColor Green
Write-Host "Example: .\usbtest.ps1 h:\ c:\123 3" -ForegroundColor Green
echo "ERROR! Input parameter number is incorrect!"|Out-File -Force -Append $log_path
echo "Usage: .\usbtest.ps1 usb_path disk_path loop_count!"|Out-File -Force -Append $log_path
echo "Example: .\usbtest.ps1 h:\ e:\123 3"|Out-File -Force -Append $log_path
exit(255)
}
else
{
$usb_path_temp=$args[0]
$disk_path_temp=$args[1]
$loop_count=$args[2]

if (-not (Test-Path ${usb_path_temp}\test -PathType Container))
{
$null=New-Item -Path ${usb_path_temp} -Name test -ItemType Directory -Force 
}

if (-not (Test-Path ${disk_path_temp}\test -PathType Container))
{
$null=New-Item -Path ${disk_path_temp} -Name test -ItemType Directory -Force 
}

$usb_path="${usb_path_temp}\test"
$disk_path="${disk_path_temp}\test"

$source_file="${current_path}\tool\test.bin"

for ($i=0;$i -lt $loop_count;$i++)
{
Write-Host "Below is the log for loop $i" -ForegroundColor Green
echo "Below is the log for loop $i"|Out-File -Force -Append $log_path

#get source hash
$hash_source=Get-FileHash -Path ${source_file} -Algorithm SHA256|Select-Object -ExpandProperty hash
Write-Host "The source hash is: ${hash_source}" -ForegroundColor Green
echo "The source hash is: ${hash_source}"|Out-File -Force -Append $log_path

#move file from disk to usb
Write-Host "Begin to move test file from source directory to  usb path!" -ForegroundColor Green
echo "Begin to move test file from source directory to  usb path!"|Out-File -Force -Append $log_path
Move-Item -Path  ${source_file} -Destination ${usb_path} -Force

#get hash in usb
$hash_usb=Get-FileHash -Path "${usb_path}\test.bin" -Algorithm SHA256|Select-Object -ExpandProperty hash
Write-Host "The usb hash is: ${hash_usb}" -ForegroundColor Green
echo "The usb hash is: ${hash_usb}"|Out-File -Force -Append $log_path

#test if hash changed
if (${hash_source} -ne ${hash_usb})
{
Write-Host "ERROR!Hash check from disk to usb fail!Need Hash: ${hash_source},but now: ${hash_usb}" -ForegroundColor Red
echo "ERROR!Hash check from disk to usb fail!Need Hash: ${hash_source},but now: ${hash_usb}"|Out-File -Force -Append $log_path
exit(255)
}
else
{
Write-Host "Hash check from disk to usb PASS!" -ForegroundColor GREEN
echo "Hash check from  disk to usb PASS!"|Out-File -Force -Append $log_path
}

Write-Host "Begin to move test file from usb path to disk path!" -ForegroundColor GREEN
echo "Begin to move test file from usb path to disk path!"|Out-File -Force -Append $log_path
#move file from usb to disk
Move-Item -Path  ${usb_path}\test.bin -Destination ${disk_path} -Force
#get hash in disk
$hash_disk=Get-FileHash -Path "${disk_path}\test.bin" -Algorithm SHA256|Select-Object -ExpandProperty hash
Write-Host "The USB hash is: ${hash_disk}" -ForegroundColor Green
echo "The USB hash is: ${hash_disk}"|Out-File -Force -Append $log_path
#test if hash changed
if (${hash_usb} -ne ${hash_disk})
{
Write-Host "ERROR!Hash check from usb to disk fail!Need Hash: ${hash_usb},but now: ${hash_disk}" -ForegroundColor Red
echo "ERROR!Hash check from usb to disk fail!Need Hash: ${hash_usb},but now: ${hash_disk}"|Out-File -Force -Append $log_path
exit(255)
}
else
{
Write-Host "Hash check from usb to disk PASS!" -ForegroundColor GREEN
echo "Hash check from usb to disk PASS!"|Out-File -Force -Append $log_path
}
}

$end_date = Get-Date -Format yyyyMMddHHmmss
echo "END USB &DISK HAST TEST!!End time:"|Out-File -Append -Force $log_path
echo $end_date|Out-File -Append -Force $log_path
exit(0)
}
