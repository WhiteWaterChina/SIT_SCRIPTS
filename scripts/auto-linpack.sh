#!/bin/bash
a=$PWD
#download
wget http://100.2.36.194/ks/ali/linpack/l_ccompxe_2013_sp1.1.106.tgz
sleep 1
wget http://100.2.36.194/ks/ali/linpack/l_mpi_p_4.1.3.045.tgz
sleep 1
wget http://100.2.36.194/ks/ali/linpack/l_mpi.txt
sleep 1
wget http://100.2.36.194/ks/ali/linpack/l_ccompxe.txt
sleep 1
wget http://192.168.12.223/ks/ali/linpack/hpldatset.sh
sleep 1
tar -zxvf l_ccompxe_2013_sp1.1.106.tgz
tar -zxvf l_mpi_p_4.1.3.045.tgz

sh l_ccompxe_2013_sp1.1.106/install.sh -s l_ccompxe.txt
sleep 1
sh l_mpi_p_4.1.3.045/install.sh -s l_mpi.txt
unalias cp
#make
cd /opt/intel/mkl/benchmarks/mp_linpack
echo "export PATH=/opt/intel/impi/4.1.3.045/intel64/bian/:/opt/intel/composer_xe_2013_sp1.1.106/bin/intel64:$PATH" >> /root/.bashrc
source /root/.bashrc
make arch=intel64
cp -r bin/intel64 /opt/em64t
#run
cd /opt/em64t/intel64
cp $a/hpldatset.sh .
mpdboot
dos2unix hpldatset.sh
chmod 777 hpldatset.sh
./hpldatset.sh
