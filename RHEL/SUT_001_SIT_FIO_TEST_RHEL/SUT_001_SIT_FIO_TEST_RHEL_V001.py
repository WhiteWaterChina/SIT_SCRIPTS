# Author:Ward Yan
# ##usage: /tmp/tools/env/tops/bin/python2 SUT_001_SIT_FIO_TEST_RHEL_V001.py test_time(seconds)
import matplotlib
matplotlib.use('Agg')
import os
import sys
import time
import re
import subprocess
import matplotlib.pyplot as plyt
import numpy


current_path = os.path.abspath(os.path.dirname(__file__))
sys.path.append(current_path)

time_start = time.strftime('%Y%m%d%H%M%S', time.localtime(time.time()))
log_dir_name = time_start + "_SIT_FIO_TEST_RHEL"
log_file_name = time_start + "_SIT_FIO_TEST_RHEL.log"
log_path_temp = current_path + "/log"
if not os.path.isdir(log_path_temp):
    os.mkdir(log_path_temp)

log_path_dir = log_path_temp + "/" + log_dir_name
log_path = log_path_dir + "/" + log_file_name
if not os.path.isdir(log_path_dir):
    os.mkdir(log_path_dir)
resultlog = open(log_path, mode="w")

# check input
input_length = len(sys.argv)
if input_length == 2:
    total_time = sys.argv[1]
elif input_length == 3:
    total_time = sys.argv[1]
    sys_part = sys.argv[2]
else:
    print("\033[31m Input Error! Usage:%s total_time(seconds) sys_partition(Optional) \033[0m" % sys.argv[0])
    resultlog.write("Input Error! Usage:%s total_time(seconds) sys_partition(Optional)" % sys.argv[0] + os.linesep)
    sys.exit(255)
if int(total_time) < 600:
    print("\033[31m Input total test time is too short! Please increase it to at least 600 seconds! \033[0m")
    resultlog.write("Input total test time is too short! Please increase it to at least 600 seconds! " + os.linesep)
    sys.exit(255)
# install fio
# check libaio-devel status
status_libaio_devel = subprocess.Popen("rpm -qa|grep libaio-devel", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
status_libaio_devel.wait()
returncode_status_libaio_devel = status_libaio_devel.returncode
if returncode_status_libaio_devel != 0:
    print("\033[31mPlease use yum -y install libaio-devel to finish the preperation \033[0m")
    resultlog.write("Please use yum -y install libaio-devel to finish the preperation" + os.linesep)
    sys.exit(255)

# check fio status & install fio
status_fio_first_time_process = subprocess.Popen("which fio", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
status_fio_first_time_process.wait()
status_fio_first_time = status_fio_first_time_process.returncode
if status_fio_first_time != 0:
    print("\033[31m fio is not installed!Please wait while installing fio! \033[0m")
    resultlog.write("fio is not installed!Please wait while installing fio!" + os.linesep)
    # install fio-2.15
    os.chdir("tool")
    subprocess.Popen("tar -zxf fio-fio-2.15.tar.gz", shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE).wait()
    os.chdir("fio-fio-2.15")
    install_fio = subprocess.Popen("./configure && make && make install", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    install_fio.wait()
    status_install_fio = install_fio.returncode
    if status_install_fio != 0:
        print("\033[31m fio is installed failed!Please check if make/gcc is installed! \033[0m")
        resultlog.write("fio is installed failed!Please check if make/gcc is installed!" + os.linesep)
        sys.exit(255)
    status_fio_second_time_process = subprocess.Popen("which fio", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    status_fio_second_time_process.wait()
    status_fio_second_time = status_fio_second_time_process.returncode
    if status_fio_second_time != 0:
        print("\033[31m fio installation failed! \033[0m")
        resultlog.write("fio installation failed!" + os.linesep)
        exit(255)
    else:
        print("\033[32m fio is installed successfully! \033[0m")
        resultlog.write("fio is installed successfully!" + os.linesep)
os.chdir(current_path)

# get disk info
# hdd
hdd_list = []
hdd_list_temp = subprocess.Popen("fdisk -l|grep 'Disk /dev/sd'", shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE).stdout.readlines()
for item_hdd in hdd_list_temp:
    hdd_name_temp = re.search(r'/dev/([a-zA-Z]+)', item_hdd)
    if hdd_name_temp is not None:
        hdd_list.append(hdd_name_temp.groups()[0])

# shannon disk
dfx_list = []
dfx_list_temp = subprocess.Popen("fdisk -l|grep 'Disk /dev/df'", shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE).stdout.readlines()
for item_dfx in dfx_list_temp:
    dfx_name_temp = re.search(r'/dev/([a-zA-Z]+)', item_dfx)
    if dfx_name_temp is not None:
        dfx_list.append(dfx_name_temp.groups()[0])

# nvme
nvme_list = []
nvme_list_temp = subprocess.Popen("fdisk -l|grep 'Disk /dev/nvme'", shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE).stdout.readlines()
for item_nvme in nvme_list_temp:
    nvme_name_temp = re.search(r'/dev/([a-zA-Z]+[0-9]+n[0-9]+)', item_nvme)
    if nvme_name_temp is not None:
        nvme_list.append(nvme_name_temp.groups()[0])

# system disk
df_list_temp = subprocess.Popen("df", shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE).stdout.readlines()
for item_df in df_list_temp:
    df_temp = re.search(r'/$', item_df)
    if df_temp is not None:
        sysdisk_temp = item_df
        break

sysdisk_name_temp = re.search(r'/dev/([a-zA-Z]+[[0-9]+n[0-9]+]*)', sysdisk_temp).groups()[0]
if sysdisk_name_temp is not None:
    sysdisk_flag = sysdisk_name_temp[:2]
else:
    print("\033[31m System disk name is not found! \033[0m")
    resultlog.write("System disk name is not found! " + os.linesep)
    exit(255)
# filter disk list to except system disk name
if sysdisk_flag == "nv":
    sysdisk_name = re.search(r'([a-zA-Z]+[[0-9]+n[0-9]+]*)', sysdisk_name_temp).groups()[0]
    nvme_list_final = [item for item in nvme_list if item != sysdisk_name]
    hdd_list_final = hdd_list
    dfx_list_final = dfx_list
elif sysdisk_flag == "sd":
    sysdisk_name = re.search(r'([a-zA-Z]+)', sysdisk_name_temp).groups()[0]
    nvme_list_final = nvme_list
    hdd_list_final = [item for item in hdd_list if item != sysdisk_name]
    dfx_list_final = dfx_list
elif sysdisk_flag == "df":
    sysdisk_name = re.search(r'([a-zA-Z]+)', sysdisk_name_temp).groups()[0]
    nvme_list_final = nvme_list
    hdd_list_final = hdd_list
    dfx_list_final = [item for item in dfx_list if item != sysdisk_name]
else:
    print("\033[31m No system disk find!Exit! \033[0m")
    resultlog.write("No system disk find!Exit!" + os.linesep)
    sys.exit(255)

diskname_list = []
# add nvme/hdd/dfx name to diskname list
diskname_list.extend(nvme_list_final)
diskname_list.extend(hdd_list_final)
diskname_list.extend(dfx_list_final)
disk_number = len(diskname_list)
# add system disk part to diskname list
if len(sys.argv) == 3:
    diskname_list.append(sys.argv[2])

# create conf dir
conf_dir = log_path_dir + "/fio_conf"
if not os.path.isdir(conf_dir):
    os.mkdir(conf_dir)
# create result dir
result_dir = log_path_dir + "/result"
if not os.path.isdir(result_dir):
    os.mkdir(result_dir)


time_every_policy = int(int(total_time) / 28)
# create conf file
policy_list = ["read", "write", "randread", "randwrite"]
block_list = ["4k", "16k", "64k", "128k", "256k", "512k", "1024k"]
for diskname in diskname_list:
    for policy in policy_list:
        for block in block_list:
            conf_file_name = conf_dir + "/" + policy + "-" + block + "-" + diskname
            file_handler = open(conf_file_name, mode="w")
            file_handler.write("[global]" + os.linesep)
            file_handler.write("bs=%s" % block + os.linesep)
            file_handler.write("ioengine=libaio" + os.linesep)
            file_handler.write("rw=%s" % policy + os.linesep)
            file_handler.write("time_based" + os.linesep)
            file_handler.write("direct=1" + os.linesep)
            file_handler.write("group_reporting" + os.linesep)
            file_handler.write("randrepeat=0" + os.linesep)
            file_handler.write("norandommap" + os.linesep)
            file_handler.write("iodepth=128" + os.linesep)
            file_handler.write("log_avg_msec=10000" + os.linesep)
            file_handler.write("write_bw_log=%s-%s-%s" % (policy, block, diskname) + os.linesep)
            file_handler.write("write_iops_log=%s-%s-%s" % (policy, block, diskname) + os.linesep)
            file_handler.write("write_lat_log=%s-%s-%s" % (policy, block, diskname) + os.linesep)
            file_handler.write("numjobs=1" + os.linesep)
            file_handler.write("timeout=8800" + os.linesep)
            file_handler.write("runtime=%s" % time_every_policy + os.linesep)
            file_handler.write("[%s]" % policy + os.linesep)
            file_handler.write("filename=/dev/%s" % diskname)
            file_handler.close()

all_conf_name = os.listdir(conf_dir)
# with open("%s/conf.txt" % log_path_dir, mode="bw") as conf_handler:
#     conf_handler.writelines(all_conf_name)

conf_temp = log_path_dir + "/conf"
if not os.path.isdir(conf_temp):
    os.mkdir(conf_temp)
policy_test = []
for item_policy in policy_list:
    for item_block in block_list:
        policy_test.append(item_policy + "-" + item_block)

for item_policy_test in policy_test:
    with open("%s/%s" % (conf_temp, item_policy_test), mode="wb") as handler:
        for item_conf in all_conf_name:
            data_temp = re.search(r'^%s' % item_policy_test, item_conf)
            if data_temp is not None:
                handler.write(item_conf + os.linesep)

run_dir = log_path_dir + "/run"
if not os.path.isdir(run_dir):
    os.mkdir(run_dir)
rawdata_dir = log_path_dir + "/rawdata"
if not os.path.isdir(rawdata_dir):
    os.mkdir(rawdata_dir)
image_dir = log_path_dir + "/image"
if not os.path.isdir(image_dir):
    os.mkdir(image_dir)

for item_policy_test in policy_test:
    with open("%s/%s" % (conf_temp, item_policy_test), mode="r") as conf_to_run:
        conf_to_run_list = conf_to_run.readlines()

    with open("%s/run-%s" % (run_dir, item_policy_test), mode="wb") as handler:
        for item_run in conf_to_run_list:
            handler.write("fio %s/%s >> %s/%s 2>&1 &" % (conf_dir.strip(), item_run.strip(), result_dir.strip(), item_run.strip()) + os.linesep)
# like:run-randread-4k
run_item_list = os.listdir(run_dir)
os.chdir(rawdata_dir)
# run fio and plot
resultlog.write("Begin FIO stress test!Start time %s" % time_start + os.linesep)
print("Begin FIO stress test!Start time %s" % time_start)
for item_to_run in run_item_list:
    # run fio in background
    filter_pattern_display = "-".join(item_to_run.split("-")[1:])
    print("\033[32m Begin to run %s \033[0m" % filter_pattern_display)
    resultlog.write("Begin to run %s" % filter_pattern_display + os.linesep)
    run_fio = subprocess.Popen("/bin/sh %s/%s" % (run_dir, item_to_run), shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    while 1 > 0:
        fio_run_status = subprocess.Popen("ps -aux|grep fio|grep -v grep", shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE)
        fio_run_status.wait()
        if fio_run_status.returncode == 0:
            time.sleep(10)
        else:
            break

    # get data to plot. raw data filename example: randread-4k-sdb_iops.1.log
    # find the rawdata filename running now, like randread-4k-sdb_iops.1.log;randread-4k-sdc_iops.1.log
    raw_data_all_filename_temp = os.listdir(rawdata_dir)
    # like:randread-4k
    for item_diskname in diskname_list:
        filter_pattern = "-".join(item_to_run.split("-")[1:]) + "-" + item_diskname
        raw_data_filename_now = [item for item in raw_data_all_filename_temp if re.search(r'%s' % filter_pattern, item) is not None]
        raw_data_filename_now_iops = [item for item in raw_data_filename_now if re.search(r'_iops', item) is not None][0]
        raw_data_filename_now_bw = [item for item in raw_data_filename_now if re.search(r'_bw', item) is not None][0]
        raw_data_filename_now_lat = [item for item in raw_data_filename_now if re.search(r'_lat', item) is not None][0]
        # plot image
        figure_name = filter_pattern
        # get data for iops
        with open(raw_data_filename_now_iops, mode='rb') as rawdata_file_iops:
            content_iops = rawdata_file_iops.readlines()
        # get data for bw
        with open(raw_data_filename_now_bw, mode='rb') as rawdata_file_bw:
            content_bw = rawdata_file_bw.readlines()
        # get data for lat
        with open(raw_data_filename_now_lat, mode='rb') as rawdata_file_lat:
            content_lat = rawdata_file_lat.readlines()
        # filter data for iops
        data_1_list_iops = [float(item.split(',')[1].strip()) for item in content_iops]
        data_2_list_iops = []
        x_data = 0
        for y_data in range(0, len(data_1_list_iops)):
            data_2_list_iops.append(x_data)
            x_data += 10
        max_y_iops = max(data_1_list_iops) * 1.1
        min_y_iops = min(data_1_list_iops) * 0.9
        jiange_iops = (max_y_iops - min_y_iops) / 10
        y_ticks_iops = numpy.arange(min_y_iops, max_y_iops, step=jiange_iops)
        data_second_iops = numpy.array(data_2_list_iops)
        data_data_iops = numpy.array(data_1_list_iops)

        # filter data for bw
        data_1_list_bw = [float(item.split(',')[1].strip()) for item in content_bw]
        data_2_list_bw = []
        x_data = 0
        for y_data in range(0, len(data_1_list_bw)):
            data_2_list_bw.append(x_data)
            x_data += 10
        max_y_bw = max(data_1_list_bw) * 1.1
        min_y_bw = min(data_1_list_bw) * 0.9
        jiange_bw = (max_y_bw - min_y_bw) / 10
        y_ticks_bw = numpy.arange(min_y_bw, max_y_bw, step=jiange_bw)
        data_second_bw = numpy.array(data_2_list_bw)
        data_data_bw = numpy.array(data_1_list_bw)
        # filter data for lat
        data_1_list_lat = [float(item.split(',')[1].strip()) for item in content_lat]
        data_2_list_lat = []
        x_data = 0
        for y_data in range(0, len(data_1_list_lat)):
            data_2_list_lat.append(x_data)
            x_data += 10
        max_y_lat = max(data_1_list_lat) * 1.1
        min_y_lat = min(data_1_list_lat) * 0.9
        jiange_lat = (max_y_lat - min_y_lat) / 10
        y_ticks_lat = numpy.arange(min_y_lat, max_y_lat, step=jiange_lat)
        data_second_lat = numpy.array(data_2_list_lat)
        data_data_lat = numpy.array(data_1_list_lat)

        # plot
        figure_1 = plyt.figure(figure_name, figsize=(20, 10))
        plyt.suptitle(figure_name)
        # set height space between two lines
        plyt.subplots_adjust(hspace=1)
        # plot iops
        fig_iops = plyt.subplot(311)
        fig_iops.grid(True)
        plyt.ylim((min_y_iops, max_y_iops))
        plyt.yticks(y_ticks_iops)
        plyt.xlabel("time(secs)")
        plyt.ylabel("IOPS")
        fig_iops.set_title("IOPS")
        fig_iops.plot(data_second_iops, data_data_iops)
        time.sleep(1)

        # plot bw
        fig_bw = plyt.subplot(312)
        fig_bw.grid(True)
        plyt.ylim((min_y_bw, max_y_bw))
        plyt.yticks(y_ticks_bw)
        plyt.xlabel("time(secs)")
        plyt.ylabel("BW(KB/s)")
        fig_bw.set_title("BandWidth")
        fig_bw.plot(data_second_bw, data_data_bw)
        time.sleep(1)

        # plot lat
        fig_lat = plyt.subplot(313)
        fig_lat.grid(True)
        plyt.ylim((min_y_lat, max_y_lat))
        plyt.yticks(y_ticks_lat)
        plyt.xlabel("time(secs)")
        plyt.ylabel("Lat(usecs)")
        fig_lat.set_title("Latency")
        fig_lat.plot(data_second_lat, data_data_lat)
        time.sleep(1)
        figure_name_temp = figure_name + '.jpg'
        figure_1.savefig(os.path.join(image_dir, figure_name_temp))
        plyt.close()

end_time = time.strftime('%Y%m%d%H%M%S', time.localtime(time.time()))
resultlog.write("End FIO stress test!End time %s" % end_time + os.linesep)
print("\033[32m End FIO stress test!End time %s \033[0m" % end_time)
resultlog.close()
sys.exit(0)
