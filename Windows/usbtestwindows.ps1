#test log directory
$current_path=Split-Path -Parent $MyInvocation.MyCommand.Definition
if (-not (Test-Path ${current_path}\log -PathType Container))
{
$null=New-Item -Path "${current_path}" -Name log -ItemType Directory 
}
$log_name="${current_path}\log\usbtest.log"
$input_length=$args.Length
Write-Host $input_length

if ($input_length -ne 1)
{
Write-Host "ERROR! Input parameter number is incorrect!" -ForegroundColor Red
Write-Host "Usage: .\usbtest.ps1 dest_dir!" -ForegroundColor Green
Write-Host "Example: .\usbtest.ps1 e:\123" -ForegroundColor Green
echo "ERROR! Input parameter number is incorrect!"|Out-File -Force -Append $log_name
echo "Usage: .\usbtest.ps1 dest_dir!"|Out-File -Force -Append $log_name
echo "Example: .\usbtest.ps1 e:\123"|Out-File -Force -Append $log_name
exit(255)
}
else
{
$dest_dir=$args[0]
if (-not (Test-Path ${dest_dir} -PathType Container))
{
$null=New-Item -Path ${dest_dir} -Name test -ItemType Directory -Force 
}
$source_file="${current_path}\tool\test.bin"
for ($i=0;$i -lt 1;$i++)
{
Write-Host "Below is the log for loop $i" -ForegroundColor Green
echo "Below is the log for loop $i"|Out-File -Force -Append $log_name
#get source hash
$hash_source=Get-FileHash -Path ${source_file} -Algorithm SHA256|Select-Object -ExpandProperty hash
Write-Host "The source hash is: ${hash_source}" -ForegroundColor Green
echo "The source hash is: ${hash_source}"|Out-File -Force -Append $log_name
#move file from usb to disk
Move-Item -Path  ${source_file} -Destination ${dest_dir} -Force
#get hash in disk
$hash_disk=Get-FileHash -Path "${dest_dir}\test.bin" -Algorithm SHA256|Select-Object -ExpandProperty hash
Write-Host "The disk hash is: ${hash_disk}" -ForegroundColor Green
echo "The disk hash is: ${hash_disk}"|Out-File -Force -Append $log_name
#test if hash changed
if (${hash_source} -ne ${hash_disk})
{
Write-Host "ERROR!Hash check from USB to DISK fail!" -ForegroundColor Red
echo "ERROR!Hash check from USB to DISK fail!"|Out-File -Force -Append $log_name
exit(255)
}
else
{
Write-Host "Hash check from USB to DISK PASS!" -ForegroundColor GREEN
echo "Hash check from USB to DISK PASS!"|Out-File -Force -Append $log_name
}
#move file from disk to usb
Move-Item -Path  ${dest_dir}\test.bin -Destination ${current_path}\tool\ -Force
#get hash in usb
$hash_usb=Get-FileHash -Path "${current_path}\tool\test.bin" -Algorithm SHA256|Select-Object -ExpandProperty hash
Write-Host "The USB hash is: ${hash_usb}" -ForegroundColor Green
echo "The USB hash is: ${hash_usb}"|Out-File -Force -Append $log_name
#test if hash changed
if (${hash_usb} -ne ${hash_disk})
{
Write-Host "ERROR!Hash check from DISK to USB fail!" -ForegroundColor Red
echo "ERROR!Hash check from DISK to USB fail!"|Out-File -Force -Append $log_name
exit(255)
}
else
{
Write-Host "Hash check from DISK to USB PASS!" -ForegroundColor GREEN
echo "Hash check from DISK to USB PASS!"|Out-File -Force -Append $log_name
}
}
}