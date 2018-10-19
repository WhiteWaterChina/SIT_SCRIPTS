
if [ $# -ne 4 ]; then 
    echo "Usage: $0 <alitype>"
    exit 1
      
fi
type=$1
hdd=$2
ssd=$3
mem=$4
sn=`ipmitool fru |grep "Product Serial"|awk '{print $4}'`
wget http://192.168.12.223/ks/ali/2.3.2/aliwork.v2.2.3.tar.bz2
sleep 1
wget http://192.168.12.223/ks/ali/2.3.15/hwqc.inspur.v2.3.15.tar.bz2
wget http://192.168.12.223/ks/ali/2.3.15/stress_check.py
wget http://192.168.12.223/ks/ali/2.3.15/inspur.baseline.v1.46.tar.bz2
tar -jxvf aliwork.v2.2.3.tar.bz2
tar -jxvf hwqc.inspur.v2.3.15.tar.bz2
tar -jxvf inspur.baseline.v1.46.tar.bz2

cd aliwork
cp -rf ../hwqc usr/alisys/dragoon/libexec/
cp -rf ../baseline usr/alisys/dragoon/libexec/hwqc/cfg/
cp -rf ../stress_check.py usr/alisys/dragoon/libexec/hwqc/task/stresscheck/
mount /sys sys -o rw,bind
mount /proc proc -o rw,bind
mount /dev dev -o rw,bind
chroot . >/dev/null <<EOF
e2label /dev/sda1 /boot
sleep 1
/home/tops/bin/python /usr/alisys/dragoon/libexec/hwqc/hwqc.py -a $type -m inspur -t 150 --io rw all
EOF
cd /root/hwqc/aliwork
umount sys
umount dev
umount proc
mkdir /root/$type+$hdd+$ssd+$mem
cd /root/$type+$hdd+$ssd+$mem
cp /root/hwqc/aliwork/tmp/hwqc.* .
#cp -r /root/hwqc/aliwork/usr/alisys/dragoon/libexec/hwqc/cfg/ .
echo "Done successfully!"
