
if [ $# -ne 1 ]; then 
    echo "Usage: $0 <alitype>"
    exit 1
      
fi
type=$1
rand=$2
sn=`ipmitool fru |grep "Product Serial"|awk '{print $4}'`
wget http://192.168.12.223/ks/ali/2.3.2/aliwork.v2.2.3.tar.bz2
sleep 1
wget http://192.168.12.223/ks/ali/2.3.14/inspur.v2.3.14.tar.bz2
wget http://192.168.12.223/ks/ali/2.3.14/inspur.baseline.v1.31.tar.bz2
wget http://192.168.12.223/ks/ali/2.3.14/fio_perf.data
wget http://192.168.12.223/ks/ali/2.3.14/mkfs.py
wget http://192.168.12.223/ks/ali/2.3.14/stress_check.py
wget http://192.168.12.223/ks/ali/2.3.14/memcpu_perf.data

tar -jxvf aliwork.v2.2.3.tar.bz2
tar -jxvf inspur.v2.3.14.tar.bz2
tar -jxvf inspur.baseline.v1.31.tar.bz2

cd aliwork
cp -rf ../hwqc usr/alisys/dragoon/libexec/
cp -rf ../baseline usr/alisys/dragoon/libexec/hwqc/cfg/
cp -rf ../fio_perf.data usr/alisys/dragoon/libexec/hwqc/cfg/perf/
cp -rf ../mkfs.py usr/alisys/dragoon/libexec/hwqc/lib/comm/scheduler/fio/
cp -rf ../stress_check.py usr/alisys/dragoon/libexec/hwqc/task/stresscheck/
cp -rf ../memcpu_perf.data usr/alisys/dragoon/libexec/hwqc/cfg/perf/
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
mkdir /root/$type-$sn
cd /root/$type-$sn
cp /root/hwqc/aliwork/tmp/hwqc.* .
#cp -r /root/hwqc/aliwork/usr/alisys/dragoon/libexec/hwqc/cfg/ .
echo "Done successfully!"
