
if [ $# -ne 2 ]; then 
    echo "Usage: $0 <alitype> <randnumber>"
    exit 1
      
fi
type=$1
rand=$2
wget http://192.168.12.223/ks/ali/aliwork.v2.0.1.tar.bz2
wget http://192.168.12.223/ks/ali/hwqc.v2.1.8.tar.bz2
wget http://192.168.12.223/ks/ali/jixian.tar.gz
wget http://192.168.12.223/ks/ali/base_desc.yaml.factory
tar -jxvf aliwork.v2.0.1.tar.bz2
tar -jxvf hwqc.v2.1.8.tar.bz2
tar -zxvf jixian.tar.gz
cd aliwork
rm -rf usr/alisys/dragoon/libexec/hwqc/
cp -r ../hwqc usr/alisys/dragoon/libexec/
cp -f ../base_desc.yaml.factory usr/alisys/dragoon/libexec/hwqc/cfg/basedesc/
mkdir usr/alisys/dragoon/libexec/hwqc/cfg/baseline/inspur
#cp -r ../jixian/S10-3S usr/alisys/dragoon/libexec/hwqc/cfg/baseline/inspur
#cp -r ../jixian/S10-4T usr/alisys/dragoon/libexec/hwqc/cfg/baseline/inspur
#cp -r ../jixian/S10-6T usr/alisys/dragoon/libexec/hwqc/cfg/baseline/inspur
#rm -rf usr/alisys/dragoon/libexec/hwqc/cfg/baseline/inspur/S10-3S/S10-3S.15
#cp ../jixian/S10-3S/S10-3S.18 usr/alisys/dragoon/libexec/hwqc/cfg/baseline/inspur/

mount /sys sys -o rw,bind
mount /proc proc -o rw,bind
mount /dev dev -o rw,bind
chroot . >/dev/null <<EOF
e2label /dev/sda1 /boot
sleep 1
./home/tops/bin/python /usr/alisys/dragoon/libexec/hwqc/lib/extend/hwinfo.py -t all > $type.$rand
cp $type.$rand /usr/alisys/dragoon/libexec/hwqc/cfg/baseline/inspur/
/home/tops/bin/python /usr/alisys/dragoon/libexec/hwqc/hwqc.py -a $type -m inspur -t 150 --io rw all
EOF
cd /root/hwqc/aliwork
umount sys
umount dev
umount proc
mkdir /root/$type
cd /root/$type
cp /root/hwqc/aliwork/tmp/hwqc.* .
cp /root/hwqc/aliwork/$type.$rand .
#cp -r /root/hwqc/aliwork/usr/alisys/dragoon/libexec/hwqc/cfg/baseline/inspur .
echo "Done successfully!"
