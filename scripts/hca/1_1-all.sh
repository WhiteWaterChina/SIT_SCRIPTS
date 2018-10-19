#!/bin/bash

SYSName=`lsb_release -a | awk '/Descrip/{print}'`
SYS=`lsb_release -a | awk '/Distributor/{print $3}'`
if [ $SYS == "SUSE" ]
 then
{
 echo "c1" > /etc/HOSTNAME
(cat <<EOF
BOOTPROTO='static'
STARTMODE='onboot'
IPADDR=10.10.10.2
NETMASK=255.255.255.0
EOF
)>/etc/sysconfig/network/ifcfg-ib0
#/root/.mpd.conf
if [ -f /root/.mpd.conf ]; then
{
rm -rf /root/.mpd.conf
}
fi
touch /root/.mpd.conf
chmod 600 /root/.mpd.conf
echo "MPD_SECRETWORD=mr45_j9z" > /root/.mpd.conf
#/etc/mpd.conf
if [ -f /etc/mpd.conf ]; then
{
rm -rf /etc/mpd.conf
}
fi
touch /etc/mpd.conf
chmod 600 /etc/mpd.conf
echo "MPD_SECRETWORD=111111" > /etc/mpd.conf

#/etc/hosts
cat /etc/hosts |grep c1 > etc-hosts.test
if [ -s etc-hosts.test ]; then
{
sed -i '/c1/d' /etc/hosts
sed -i '/c2/d' /etc/hosts
}
fi
rm -rf etc-hosts.test
echo "10.10.10.2 c1" >> /etc/hosts
echo "10.10.10.3 c2" >> /etc/hosts

#/root/mpd.hosts
if [ -f /root/.mpd.hosts ]; then
{
rm -rf /root/.mpd.hosts
}
fi
echo "c1">>/root/.mpd.hosts
echo "c2">>/root/.mpd.hosts
#path
cat /root/.bashrc |grep PATH > bashtest.txt
if [ -s bashtest.txt ]; then
sed -i 'PATH/d' /root/.bashrc
fi
rm -rf bashtest.txt
cat path >>/root/.bashrc
source /root/.bashrc
#cat config_1 >>/etc/init.d/boot.local
(cat <<EOF
service iptables stop
service NetworkManager stop
/sbin/SuSEfirewall2 stop
/etc/init.d/sshd start
EOF
)>>/etc/init.d/boot.local 
sleep 2
 sed -i "s/FW_SERVICES_EXT_TCP=''/FW_SERVICES_EXT_TCP='ssh'/g" /etc/sysconfig/SuSEfirewall2
 sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
 #/etc/init.d/sshd restart
 echo "Suse"
 sleep 5
 reboot
}
else
{
#rm -rf /etc/sysconfig/network-scripts/ifcfg-ib0
#cat ib0_1_rhel >>/etc/sysconfig/network-scripts/ifcfg-ib0
(cat <<EOF
DEVICE=ib0
ONBOOT=yes
BOOTPROTO=static
IPADDR=10.10.10.2
NETMASK=255.255.255.0
EOF
)>/etc/sysconfig/network-scripts/ifcfg-ib0

#hostname_c1
sed -i 's/HOSTNAME.*/HOSTNAME=c1/' /etc/sysconfig/network
#/root/.mpd.conf
if [ -f /root/.mpd.conf ]; then
{
rm -rf /root/.mpd.conf
}
fi
touch /root/.mpd.conf
chmod 600 /root/.mpd.conf
echo "MPD_SECRETWORD=mr45_j9z" > /root/.mpd.conf
#/etc/mpd.conf
if [ -f /etc/mpd.conf ]; then
{
rm -rf /etc/mpd.conf
}
fi
touch /etc/mpd.conf
chmod 600 /etc/mpd.conf
echo "MPD_SECRETWORD=111111" > /etc/mpd.conf

#/etc/hosts
cat /etc/hosts |grep c1 > etc-hosts.test
if [ -s etc-hosts.test ]; then
{
sed -i '/c1/d' /etc/hosts
sed -i '/c2/d' /etc/hosts
}
fi
rm -rf etc-hosts.test
echo "10.10.10.2 c1" >> /etc/hosts
echo "10.10.10.3 c2" >> /etc/hosts
#/root/mpd.hosts
if [ -f /root/.mpd.hosts ]; then
{
rm -rf /root/.mpd.hosts
}
fi
echo "c1">>/root/.mpd.hosts
echo "c2">>/root/.mpd.hosts
#path
cat /root/.bashrc |grep PATH > bashtest.txt
if [ -s bashtest.txt ]; then
sed -i 'PATH/d' /root/.bashrc
fi
rm -rf bashtest.txt
cat path >>/root/.bashrc
source /root/.bashrc
#cat config_1 >>/etc/rc.local
(cat <<EOF
service iptables stop
service iptables save
service NetworkManager stop
chkconfig NetworkManager off
/etc/init.d/sshd restart
EOF
)>>/etc/rc.local

echo "Redhat"
sleep 5
reboot
}
fi
