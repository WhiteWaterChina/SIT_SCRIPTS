#!/bin/bash
a=$PWD

wget http://100.2.36.194/ks/ali/speccpu/cpu2006-1.2.iso
sleep 1
wget http://100.2.36.194/ks/ali/speccpu/FOR.OEMs.cpu2006.1.2.ic15.29aug2014.linux64.binaries.tar.xz
sleep 1
wget http://100.2.36.194/ks/ali/speccpu/lib.zip
sleep 1
mkdir tmp
cp FOR.OEMs.cpu2006.1.2.ic15.29aug2014.linux64.binaries.tar.xz tmp
cd tmp
xz -d FOR.OEMs.cpu2006.1.2.ic15.29aug2014.linux64.binaries.tar.xz
tar -xvf FOR.OEMs.cpu2006.1.2.ic15.29aug2014.linux64.binaries.tar
cd ..

#install_speccpu-1.2
mount -o loop cpu2006-1.2.iso /mnt

expect<<- END 
spawn sh /mnt/install.sh
expect "Enter the directory you wish to install to"
send "/opt/cpu2006\n"
expect "Is this correct?"
send "yes\n"
expect "Installation successful"
sleep 90
send "\n"

expect eof
exit
END
umount /mnt
#ic14
cd tmp
cp -Rpf benchspec/CPU2006/* /opt/cpu2006/benchspec/CPU2006/
cp config/* /opt/cpu2006/config/
cp -Rpf libs /opt/cpu2006/
cp Intel* nhmtopology.pl numa-detection.sh reportable-* /opt/cpu2006
cp -Rpf sh /opt/cpu2006
cp Default-Platform-Flags.xml /opt/cpu2006/
#lib
cd ..
unzip lib.zip
cp -Rpf lib/32/* /opt/cpu2006/libs/32/
cp -Rpf lib/64/* /opt/cpu2006/libs/64/
cd /opt/cpu2006/libs/64/
ln -sf /usr/lib64/libstdc++.so.6.0.19 libstdc++.so.6
cd /opt/cpu2006/libs/32/
ln -sf /usr/lib/libstdc++.so.6.0.19 libstdc++.so.6
#run
#cd /opt/cpu2006
#./reportable-ws-avx-smt-on-rate.sh
