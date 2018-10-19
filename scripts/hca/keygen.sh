#!/usr/bin/expect
#ssh-keygen_auto
set timeout -1 
spawn ssh-keygen -t dsa
expect "(/root/.ssh/id_dsa):" 
send "\r" 
expect {
"Overwrite (y/n)?" 
{
send "y\r";
expect "(empty for no passphrase):"
send "\r"
expect "again:"
send "\r\n"
exp_continue
} 
"(empty for no passphrase):"
{send "\r"             
expect "again:"
send "\r\n"
exp_continue
}
eof
{
send_user "eof"
}
}
