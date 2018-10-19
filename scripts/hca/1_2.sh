#!/usr/bin/expect
set pasword 111111
set host1 c1
set host2 c2
set timeout -1

#ssh-keygen-1
spawn ssh-keygen -t dsa
expect "(/root/.ssh/id_dsa)"
send "\r"
expect {
"Overwrite (y/n)?"
{
send "y\r"
expect "(empty for no passphrase):"
send "\r"
expect "again:"
send "\r\n"
exp_continue
}
"(empty for no passphrase):"
{
send "\r"
expect "again:"
send "\r\n"
exp_continue
}
eof
{
send_user "eof"
}
}
#copy_keygen_to_2
spawn scp keygen.sh root@c2:/root
expect {
"continue connecting (yes/no)?"
{
send "yes\r"
expect "password:"
send "$pasword\r"
exp_continue
}
"password:"
{
send "$pasword\r"
exp_continue
}
eof
{
send_user "eof"
}
}
#yunxing_keygen_2
spawn ssh -f root@c2 ./keygen.sh
expect {
"password:"
{
send "$pasword\r"
exp_continue
}
eof
{
send_user "eof"
}
}
#scp_1_to_2
spawn scp /root/.ssh/id_dsa.pub $host2:/root/.ssh/authorized_keys2;
expect {
"continue connecting (yes/no)?"
{
send "yes\r"
expect "password:"   
send "$pasword\r"
exp_continue
}
"password:"
{
send "$pasword\r"
exp_continue
}
eof
{
send_user "eof"
}
}
exec sleep 1

#cat_2
spawn ssh -f -o StrictHostkeyChecking=no root@$host2 cat /root/.ssh/id_dsa.pub >>/root/.ssh/authorized_keys2;
expect {
"password:"
{
send "$pasword\r"
exp_continue
}
eof
{
send_user "eof"
}
}
#scp_2_to_1
spawn scp root@c2:/root/.ssh/authorized_keys2 /root/.ssh/
expect {
"password:"
{
send "$pasword\r"
exp_continue
}
eof
}
exec sleep 1

#ssh_c2_to_c1
spawn ssh -f $host2 ssh -o StrictHostkeyChecking=no root@c1 

#report
spawn ssh $host2
expect {
"root@c2"
{
send_user "successfully"
}
"password"
{
send_user "faild"}
}

send "exit\r"
expect eof

