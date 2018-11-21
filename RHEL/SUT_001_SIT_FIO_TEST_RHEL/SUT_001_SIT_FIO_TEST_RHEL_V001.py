# Author:Ward Yan
import matplotlib
matplotlib.use('Agg')
import os
import sys
import time
import re
import subprocess
import matplotlib.pyplot as plyt
import numpy
import argparse


def root_args():
    parser = argparse.ArgumentParser(description="Script to run fio test!")
    # parser.add_argument("--time", dest="run_time", required=True, type=int, help="Total time to run fio test!")
    parser.add_argument("--sysdisk", dest="sysdisk", type=str, help="Sysdisk partition name! For example: sda4")
    parser.add_argument("--target", dest="target", type=str, default="multi",
                        help="Which disk to run fio test! 'multi' means run all disks; if you want to run fio on specific disks, please write their names, \
                        should be separated by space, for example sdb or sdb sdc, but can't contain sysdisk. Default is multi.")
    parser.add_argument("--write", dest="write_policy", type=str, default="4k 8k 16k 32k 64k 128k 256k 512k 1024k",
                        help="Write policy to run. For example: 4k. Default is 4k 8k 16k 32k 64k 128k 256k 512k 1024k. If want to disable this test, use 'none'.")
    parser.add_argument("--read", dest="read_policy", type=str, default="4k 8k 16k 32k 64k 128k 256k 512k 1024k",
                        help="Read policy to run. For example: 4k. Default is 4k 8k 16k 32k 64k 128k 256k 512k 1024k. If want to disable this test, use 'none'.")
    parser.add_argument("--randread", dest="randread_policy", type=str, default="4k 8k 16k 32k 64k 128k 256k 512k 1024k",
                        help="Randread policy to run. For example: 4k. Default is 4k 8k 16k 32k 64k 128k 256k 512k 1024k. If want to disable this test, use 'none'.")
    parser.add_argument("--randwrite", dest="randwrite_policy", type=str, default="4k 8k 16k 32k 64k 128k 256k 512k 1024k",
                        help="Randwrite policy to run. For example: 4k. Default is 4k 8k 16k 32k 64k 128k 256k 512k 1024k. If want to disable this test, use 'none'.")
    args = parser.parse_args()
    return args


def gen_conf(diskname, policy, block, time_per_block, iodepth_per_block, numjobs_per_block, log_flag):
    conf_detail_list = []
    conf_detail_list.append("[global]" + os.linesep)
    conf_detail_list.append("bs={0}".format(block) + os.linesep)
    conf_detail_list.append("ioengine=libaio" + os.linesep)
    conf_detail_list.append("rw={0}".format(policy) + os.linesep)
    conf_detail_list.append("time_based" + os.linesep)
    conf_detail_list.append("direct=1" + os.linesep)
    conf_detail_list.append("ramp_time=60" + os.linesep)
    conf_detail_list.append("group_reporting" + os.linesep)
    conf_detail_list.append("randrepeat=0" + os.linesep)
    conf_detail_list.append("norandommap" + os.linesep)
    conf_detail_list.append("iodepth={0}".format(iodepth_per_block) + os.linesep)
    if log_flag == "1":
        conf_detail_list.append("log_avg_msec=1000" + os.linesep)
        conf_detail_list.append("log_max_value=1" + os.linesep)
        conf_detail_list.append("write_bw_log={0}-{1}-{2}".format(policy, block, diskname) + os.linesep)
        conf_detail_list.append("write_iops_log={0}-{1}-{2}".format(policy, block, diskname) + os.linesep)
        conf_detail_list.append("write_lat_log={0}-{1}-{2}".format(policy, block, diskname) + os.linesep)
    conf_detail_list.append("numjobs={}".format(numjobs_per_block) + os.linesep)
    conf_detail_list.append("timeout=88888" + os.linesep)
    conf_detail_list.append("runtime={0}".format(time_per_block) + os.linesep)
    conf_detail_list.append("[{0}]".format(policy) + os.linesep)
    conf_detail_list.append("filename=/dev/{0}".format(diskname))
    return  conf_detail_list


def plot_image_1job(figure_name, raw_data_filename_iops, raw_data_filename_bw, raw_data_filename_lat, image_dir_sub):
    # get data for iops
    with open(raw_data_filename_iops, mode='rb') as rawdata_file_iops:
        content_iops = rawdata_file_iops.readlines()
    # get data for bw
    with open(raw_data_filename_bw, mode='rb') as rawdata_file_bw:
        content_bw = rawdata_file_bw.readlines()
    # get data for lat
    with open(raw_data_filename_lat, mode='rb') as rawdata_file_lat:
        content_lat = rawdata_file_lat.readlines()
    # filter data for iops
    data_1_list_iops = [float(item.split(',')[1].strip()) for item in content_iops]
    data_2_list_iops = []
    x_data = 0
    for y_data in range(0, len(data_1_list_iops)):
        data_2_list_iops.append(x_data)
        x_data += 1
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
    figure_1.savefig(os.path.join(image_dir_sub, figure_name_temp))
    plyt.close()


def plot_image_4job(figure_name, raw_data_filename_iops_list, raw_data_filename_bw_list, raw_data_filename_lat_list, image_dir_sub):
    data_iops = {}
    data_bw = {}
    data_lat = {}
    # get data for iops from result file
    for index_iops, item_iops in enumerate(raw_data_filename_iops_list):
        data_iops["{}".format(index_iops)] = []
        with open(item_iops, mode='rb') as rawdata_file_iops:
            data_iops["{}".format(index_iops)].extend([float(item.split(",")[1].strip()) for item in rawdata_file_iops.readlines()])
    # get data for bw from result file
    for index_bw, item_bw in enumerate(raw_data_filename_bw_list):
        data_bw["{}".format(index_bw)] = []
        with open(item_bw, mode='rb') as rawdata_file_bw:
            data_bw["{}".format(index_bw)].extend([float(item.split(",")[1].strip()) for item in rawdata_file_bw.readlines()])
    # get data for lat from result file
    for index_lat, item_lat in enumerate(raw_data_filename_lat_list):
        data_lat["{}".format(index_lat)] = []
        with open(item_lat, mode='rb') as rawdata_file_lat:
            data_lat["{}".format(index_lat)].extend([float(item.split(",")[1].strip()) for item in rawdata_file_lat.readlines()])

    # filter data for iops
    data_1_list_iops = []
    data_2_list_iops = []
    try:
        for index_iops_sub, item_iops_sub in enumerate(data_iops['0']):
            data_1_list_iops.append(item_iops_sub + data_iops['1'][index_iops_sub] + data_iops['2'][index_iops_sub] + data_iops['3'][index_iops_sub])
    except IndexError:
        pass
    x_data = 0
    for y_data in range(0, len(data_1_list_iops)):
        data_2_list_iops.append(x_data)
        x_data += 1
    max_y_iops = max(data_1_list_iops) * 1.1
    min_y_iops = min(data_1_list_iops) * 0.9
    jiange_iops = (max_y_iops - min_y_iops) / 10
    y_ticks_iops = numpy.arange(min_y_iops, max_y_iops, step=jiange_iops)
    data_second_iops = numpy.array(data_2_list_iops)
    data_data_iops = numpy.array(data_1_list_iops)

    # filter data for bw
    data_1_list_bw = []
    data_2_list_bw = []
    try:
        for index_bw_sub, item_bw_sub in enumerate(data_bw['0']):
            data_1_list_bw.append(item_bw_sub + data_bw['1'][index_bw_sub] + data_bw['2'][index_bw_sub] + data_bw['3'][index_bw_sub])
    except IndexError:
        pass
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
    data_1_list_lat = []
    data_2_list_lat = []
    try:
        for index_lat_sub, item_lat_sub in enumerate(data_lat['0']):
            data_1_list_lat.append(item_lat_sub + data_lat['1'][index_lat_sub] + data_lat['2'][index_lat_sub] + data_lat['3'][index_lat_sub])
    except IndexError:
        pass
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
    figure_1.savefig(os.path.join(image_dir_sub, figure_name_temp))
    plyt.close()


def run_fio(policy, block, diskname_list_sub, runtime, image_flag):
    for item_sub in diskname_list_sub:
        subprocess.Popen("fio {confdir}/{policy}/{time}-{policy}-{block}-{diskname} > {resultdir}/{policy}/{policy}-{block}-{diskname} 2>&1 &".format(confdir=conf_dir, policy=policy, time=runtime, block=block, diskname=item_sub, resultdir=result_dir), shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    while 1 > 0:
        fio_run_status = subprocess.Popen("ps -aux|grep fio|grep -v grep|grep -v man", shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE)
        fio_run_status.wait()
        if fio_run_status.returncode == 0:
            time.sleep(10)
        else:
            break

    if image_flag == "1":
        raw_data_all_filename_temp = os.listdir(rawdata_dir)
        for item_job1 in diskname_list_sub:
            filter_pattern = "{policy}-{block}-{diskname}".format(policy=policy, block=block, diskname=item_job1)
            raw_data_filename_now = [item for item in raw_data_all_filename_temp if re.search(r'%s' % filter_pattern, item) is not None]
            raw_data_filename_now_iops = [item for item in raw_data_filename_now if re.search(r'_iops', item) is not None][0]
            raw_data_filename_now_bw = [item for item in raw_data_filename_now if re.search(r'_bw', item) is not None][0]
            raw_data_filename_now_lat = [item for item in raw_data_filename_now if re.search(r'_lat', item) is not None][0]
            plot_image_1job(filter_pattern, raw_data_filename_now_iops, raw_data_filename_now_bw, raw_data_filename_now_lat, image_dir)
    elif image_flag == "4":
        raw_data_all_filename_temp = os.listdir(rawdata_dir)
        for item_job4 in diskname_list_sub:
            filter_pattern = "{policy}-{block}-{diskname}".format(policy=policy, block=block, diskname=item_job4)
            raw_data_filename_now = [item for item in raw_data_all_filename_temp if re.search(r'%s' % filter_pattern, item) is not None]
            raw_data_filename_now_iops = [item for item in raw_data_filename_now if re.search(r'_iops', item) is not None]
            raw_data_filename_now_bw = [item for item in raw_data_filename_now if re.search(r'_bw', item) is not None]
            raw_data_filename_now_lat = [item for item in raw_data_filename_now if re.search(r'_lat', item) is not None]
            plot_image_4job(filter_pattern, raw_data_filename_now_iops, raw_data_filename_now_bw, raw_data_filename_now_lat, image_dir)


current_path = os.path.abspath(os.path.dirname(__file__))
sys.path.append(current_path)

time_start_temp = time.localtime(time.time())
time_start = time.strftime('%Y%m%d%H%M%S', time_start_temp)
time_start_write = time.strftime('%Y-%m-%d %H:%M:%S', time_start_temp)
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
input_arg = root_args()
# total_time = input_arg.run_time
sys_part = input_arg.sysdisk
target = input_arg.target
target_list = target.split(" ")
read_policy_list = input_arg.read_policy.split(" ")
write_policy_list = input_arg.write_policy.split(" ")
randread_policy_list = input_arg.randread_policy.split(" ")
randwrite_policy_list = input_arg.randwrite_policy.split(" ")

# install fio
# check libaio-devel status
status_libaio_devel = subprocess.Popen("rpm -qa|grep libaio-devel", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
status_libaio_devel.wait()
returncode_status_libaio_devel = status_libaio_devel.returncode
if returncode_status_libaio_devel != 0:
    print("Please use yum -y install libaio-devel to finish the preperation!")
    resultlog.write("Please use yum -y install libaio-devel to finish the preperation!" + os.linesep)
    resultlog.close()
    sys.exit(255)

# check fio status & install fio
status_fio_first_time_process = subprocess.Popen("which fio", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
status_fio_first_time_process.wait()
status_fio_first_time = status_fio_first_time_process.returncode
if status_fio_first_time != 0:
    print("fio is not installed!Please wait while installing fio!")
    resultlog.write("fio is not installed!Please wait while installing fio!" + os.linesep)
    # install fio-2.15
    os.chdir("tool")
    subprocess.Popen("tar -zxf fio-fio-2.15.tar.gz", shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE).wait()
    os.chdir("fio-fio-2.15")
    install_fio = subprocess.Popen("./configure && make && make install", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    install_fio.wait()
    status_install_fio = install_fio.returncode
    if status_install_fio != 0:
        print("fio is installed failed!Please check if make/gcc is installed!")
        resultlog.write("fio is installed failed!Please check if make/gcc is installed!" + os.linesep)
        resultlog.close()
        sys.exit(255)
    status_fio_second_time_process = subprocess.Popen("which fio", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    status_fio_second_time_process.wait()
    status_fio_second_time = status_fio_second_time_process.returncode
    if status_fio_second_time != 0:
        print("fio installation failed!")
        resultlog.write("fio installation failed!" + os.linesep)
        resultlog.close()
        exit(255)
    else:
        print("fio is installed successfully!")
        resultlog.write("fio is installed successfully!" + os.linesep)

os.chdir(current_path)
# get system disk name
df_list_temp = subprocess.Popen("df", shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE).stdout.readlines()
for item_df in df_list_temp:
    df_temp = re.search(r'/$', item_df)
    if df_temp is not None:
        sysdisk_temp = item_df
        break
sysdisk_name_temp = re.search(r'/dev/([a-zA-Z]+[[0-9]+n*[0-9]*]*)', sysdisk_temp)
if sysdisk_name_temp is not None:
    sysdisk_name_target = sysdisk_name_temp.groups()[0]
    sysdisk_flag = sysdisk_name_target[:2]
else:
    print("System disk name is not found!")
    resultlog.write("System disk name is not found! " + os.linesep)
    resultlog.close()
    exit(255)
# check if target is system disk
for item_target in target_list:
    if item_target == sysdisk_name_target:
        print("Targets contain system disk! Please change it!")
        resultlog.write("Targets contain system disk! Please change it!" + os.linesep)
        resultlog.close()
        exit(255)

# get disk info
diskname_list = []
if target == "multi":
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
        nvme_name_temp = re.search(r'/dev/([a-zA-Z]+[0-9]+n*[0-9]*)', item_nvme)
        if nvme_name_temp is not None:
            nvme_list.append(nvme_name_temp.groups()[0])
    # filter disk list to except system disk name
    if sysdisk_flag == "nv":
        sysdisk_name = re.search(r'([a-zA-Z]+[[0-9]+n*[0-9]*]*)', sysdisk_name_target).groups()[0]
        nvme_list_final = [item for item in nvme_list if item != sysdisk_name]
        hdd_list_final = hdd_list
        dfx_list_final = dfx_list
    elif sysdisk_flag == "sd":
        sysdisk_name = re.search(r'([a-zA-Z]+)', sysdisk_name_target).groups()[0]
        nvme_list_final = nvme_list
        hdd_list_final = [item for item in hdd_list if item != sysdisk_name]
        dfx_list_final = dfx_list
    elif sysdisk_flag == "df":
        sysdisk_name = re.search(r'([a-zA-Z]+)', sysdisk_name_target).groups()[0]
        nvme_list_final = nvme_list
        hdd_list_final = hdd_list
        dfx_list_final = [item for item in dfx_list if item != sysdisk_name]
    else:
        print("No system disk find!Exit!")
        resultlog.write("No system disk find!Exit!" + os.linesep)
        resultlog.close()
        sys.exit(255)

    # add nvme/hdd/dfx name to diskname list
    diskname_list.extend(nvme_list_final)
    diskname_list.extend(hdd_list_final)
    diskname_list.extend(dfx_list_final)
    disk_number = len(diskname_list)
    # add system disk part to diskname list
    if sys_part is not None:
        diskname_list.append(sys_part)
else:
    diskname_list = target_list

# create conf dir
conf_dir = log_path_dir + "/fio_conf"
if not os.path.isdir(conf_dir):
    os.mkdir(conf_dir)
writeconf_dir = conf_dir + "/write"
if not os.path.isdir(writeconf_dir):
    os.mkdir(writeconf_dir)
readconf_dir = conf_dir + "/read"
if not os.path.isdir(readconf_dir):
    os.mkdir(readconf_dir)
randwriteconf_dir = conf_dir + "/randwrite"
if not os.path.isdir(randwriteconf_dir):
    os.mkdir(randwriteconf_dir)
randreadconf_dir = conf_dir + "/randread"
if not os.path.isdir(randreadconf_dir):
    os.mkdir(randreadconf_dir)
randreadconf_dir = conf_dir + "/randread"
if not os.path.isdir(randreadconf_dir):
    os.mkdir(randreadconf_dir)
write128k2hconf_dir = conf_dir + "/write128k2h"
if not os.path.isdir(write128k2hconf_dir):
    os.mkdir(write128k2hconf_dir)
randwrite4k6hconf_dir = conf_dir + "/randwrite4k6h"
if not os.path.isdir(randwrite4k6hconf_dir):
    os.mkdir(randwrite4k6hconf_dir)

# create result dir
result_dir = log_path_dir + "/result"
if not os.path.isdir(result_dir):
    os.mkdir(result_dir)
writeresult_dir = result_dir + "/write"
if not os.path.isdir(writeresult_dir):
    os.mkdir(writeresult_dir)
readresult_dir = result_dir + "/read"
if not os.path.isdir(readresult_dir):
    os.mkdir(readresult_dir)
randwriteresult_dir = result_dir + "/randwrite"
if not os.path.isdir(randwriteresult_dir):
    os.mkdir(randwriteresult_dir)
randreadresult_dir = result_dir + "/randread"
if not os.path.isdir(randreadresult_dir):
    os.mkdir(randreadresult_dir)
randreadresult_dir = result_dir + "/randread"
if not os.path.isdir(randreadresult_dir):
    os.mkdir(randreadresult_dir)
write128k2hresult_dir = result_dir + "/write128k2h"
if not os.path.isdir(write128k2hresult_dir):
    os.mkdir(write128k2hresult_dir)
randwrite4k6hresult_dir = result_dir + "/randwrite4k6h"
if not os.path.isdir(randwrite4k6hresult_dir):
    os.mkdir(randwrite4k6hresult_dir)

# create conf file
# gen conf for write
if re.search(r'[Nn][Oo][Nn][Ee]', write_policy_list[0]) is None:
    for item_diskname_write in diskname_list:
        for item_block_write in write_policy_list:
            conf_for_item_write = gen_conf(item_diskname_write, "write", item_block_write, "600", "128", "1", "1")
            with open(writeconf_dir + "/raw-write-{}-{}".format(item_block_write, item_diskname_write), mode="wb") as file_handle_write:  # like: write-4k-nvme1n1
                for item_conf_detail_write in conf_for_item_write:
                    file_handle_write.write(item_conf_detail_write)
# gen conf for read
if re.search(r'[Nn][Oo][Nn][Ee]', read_policy_list[0]) is None:
    for item_diskname_read in diskname_list:
        for item_block_read in read_policy_list:
            conf_for_item_read = gen_conf(item_diskname_read, "read", item_block_read, "600", "128", "1", "1")
            with open(readconf_dir + "/raw-read-{}-{}".format(item_block_read, item_diskname_read), mode="wb") as file_handle_read:  # like: write-4k-nvme1n1
                for item_conf_detail_read in conf_for_item_read:
                    file_handle_read.write(item_conf_detail_read)
# gen conf for randwrite
if re.search(r'[Nn][Oo][Nn][Ee]', randwrite_policy_list[0]) is None:
    for item_diskname_randwrite in diskname_list:
        for item_block_randwrite in randwrite_policy_list:
            conf_for_item_randwrite = gen_conf(item_diskname_randwrite, "randwrite", item_block_randwrite, "600", "128", "4", "1")
            with open(randwriteconf_dir + "/raw-randwrite-{}-{}".format(item_block_randwrite, item_diskname_randwrite), mode="wb") as file_handle_randwrite:  # like: write-4k-nvme1n1
                for item_conf_detail_randwrite in conf_for_item_randwrite:
                    file_handle_randwrite.write(item_conf_detail_randwrite)
# gen conf for randread
if re.search(r'[Nn][Oo][Nn][Ee]', randread_policy_list[0]) is None:
    for item_diskname_randread in diskname_list:
        for item_block_randread in randread_policy_list:
            conf_for_item_randread = gen_conf(item_diskname_randread, "randread", item_block_randread, "600", "128", "4", "1")
            with open(randreadconf_dir + "/raw-randread-{}-{}".format(item_block_randread, item_diskname_randread), mode="wb") as file_handle_randread:  # like: write-4k-nvme1n1
                for item_conf_detail_randread in conf_for_item_randread:
                    file_handle_randread.write(item_conf_detail_randread)
# gen conf for write_128k_2h
for item_diskname_write128k2h in diskname_list:
    conf_for_item_write128k2h = gen_conf(item_diskname_write128k2h, "write", "128k", "7200", "128", "1", "0")
    with open(write128k2hconf_dir + "/2h-write128k2h-128k-{}".format(item_diskname_write128k2h), mode="wb") as file_handle_write128k2h:  # like: write-4k-nvme1n1
        for item_conf_detail_randread in conf_for_item_write128k2h:
            file_handle_write128k2h.write(item_conf_detail_randread)
# gen conf for randwrite_4k_6h
for item_diskname_randwrite4k6h in diskname_list:
    conf_for_item_randwrite4k6h = gen_conf(item_diskname_randwrite4k6h, "randwrite", "4k", "21600", "128", "4", "0")
    with open(randwrite4k6hconf_dir + "/6h-randwrite4k6h-4k-{}".format(item_diskname_randwrite4k6h), mode="wb") as file_handle_randwrite4k6h:  # like: write-4k-nvme1n1
        for item_conf_detail_randwrite4k6h in conf_for_item_randwrite4k6h:
            file_handle_randwrite4k6h.write(item_conf_detail_randwrite4k6h)

# gen dir for rawdata and images
rawdata_dir = log_path_dir + "/rawdata"
if not os.path.isdir(rawdata_dir):
    os.mkdir(rawdata_dir)
image_dir = log_path_dir + "/image"
if not os.path.isdir(image_dir):
    os.mkdir(image_dir)

# run_item_list = os.listdir(run_dir)
os.chdir(rawdata_dir)
# run fio and plot
resultlog.write("Begin FIO stress test!Start time {}".format(time_start_write) + os.linesep)
print("Begin FIO stress test!Start time {}".format(time_start_write))

# run write
if re.search(r'[Nn][Oo][Nn][Ee]', write_policy_list[0]) is None:

    time_temp = time.localtime(time.time())
    print("Start run write at:{}!".format(time.strftime('%Y-%m-%-d %H:%M:%S', time_temp)))
    resultlog.write("Start run write at:".format(time.strftime('%Y-%m-%-d %H:%M:%S', time_temp)) + os.linesep)

    for block_write in write_policy_list:
        time_temp = time.localtime(time.time())
        print("Start run write-{} at: {}".format(block_write, time.strftime('%Y-%m-%-d %H:%M:%S', time_temp)))
        resultlog.write("Start run write-{} at: {}".format(block_write, time.strftime('%Y-%m-%-d %H:%M:%S', time_temp)) + os.linesep)
        run_fio("write", block_write, diskname_list, "raw", "1")

    time_temp = time.localtime(time.time())
    print("End write at: {}".format(time.strftime('%Y-%m-%-d %H:%M:%S', time_temp)))
    resultlog.write("End write at: {}".format(time.strftime('%Y-%m-%-d %H:%M:%S', time_temp)) + os.linesep)

else:
    print("No write! Skip!")
    resultlog.write("No write! Skip!" + os.linesep)

# run read
if re.search(r'[Nn][Oo][Nn][Ee]', read_policy_list[0]) is None:
    time_temp = time.localtime(time.time())
    print("Start run read at: {}".format(time.strftime('%Y-%m-%-d %H:%M:%S', time_temp)))
    resultlog.write("Start run read at:{}".format(time.strftime('%Y-%m-%-d %H:%M:%S', time_temp)) + os.linesep)

    for block_read in read_policy_list:
        time_temp = time.localtime(time.time())
        print("Start run read-{} at: {}".format(block_read, time.strftime('%Y-%m-%-d %H:%M:%S', time_temp)))
        resultlog.write("Start run read-{} at: {}".format(block_read, time.strftime('%Y-%m-%-d %H:%M:%S', time_temp)) + os.linesep)
        run_fio("read", block_read, diskname_list, "raw", "1")

    time_temp = time.localtime(time.time())
    print("End read at: {}".format(time.strftime('%Y-%m-%-d %H:%M:%S', time_temp)))
    resultlog.write("End read at: {}".format(time.strftime('%Y-%m-%-d %H:%M:%S', time_temp)) + os.linesep)

else:
    print("No read! Skip!")
    resultlog.write("No read! Skip!" + os.linesep)

# run randread
if re.search(r'[Nn][Oo][Nn][Ee]', randread_policy_list[0]) is None:
    # run write 128k 2h
    time_temp = time.localtime(time.time())
    print("Start run write128k2h at: {}".format(time.strftime('%Y-%m-%-d %H:%M:%S', time_temp)))
    resultlog.write("Start run write128k2h at: {}".format(time.strftime('%Y-%m-%-d %H:%M:%S', time_temp)) + os.linesep)
    run_fio("write128k2h", "128k", diskname_list, "2h", "0")

    time_temp = time.localtime(time.time())
    print("End write128k2h at: {}".format(time.strftime('%Y-%m-%-d %H:%M:%S', time_temp)))
    resultlog.write("End write128k2h at: {}".format(time.strftime('%Y-%m-%-d %H:%M:%S', time_temp)) + os.linesep)

    # run randread
    time_temp = time.localtime(time.time())
    print("Start run randread at: {}".format(time.strftime('%Y-%m-%-d %H:%M:%S', time_temp)))
    resultlog.write("Start run randread at: {}".format(time.strftime('%Y-%m-%-d %H:%M:%S', time_temp)) + os.linesep)

    for block_randread in randread_policy_list:
        time_temp = time.localtime(time.time())
        print("Start run randread-{} at: {}".format(block_randread, time.strftime('%Y-%m-%-d %H:%M:%S', time_temp)))
        resultlog.write("Start run randread-{} at: {}".format(block_randread, time.strftime('%Y-%m-%-d %H:%M:%S', time_temp)) + os.linesep)
        run_fio("randread", block_randread, diskname_list, "raw", "4")

    time_temp = time.localtime(time.time())
    print("End randread at: {}".format(time.strftime('%Y-%m-%-d %H:%M:%S', time_temp)))
    resultlog.write("End randread at: {}".format(time.strftime('%Y-%m-%-d %H:%M:%S', time_temp)) + os.linesep)
else:
    print("No randread! Skip!")
    resultlog.write("No randread! Skip!" + os.linesep)

# run randwrite
if re.search(r'[Nn][Oo][Nn][Ee]', randwrite_policy_list[0]) is None:

    time_temp = time.localtime(time.time())
    print("Start run randwrite4k6h at: {}".format(time.strftime('%Y-%m-%-d %H:%M:%S', time_temp)))
    resultlog.write("Start run randwrite4k6h at: {}".format(time.strftime('%Y-%m-%-d %H:%M:%S', time_temp)) + os.linesep)
    run_fio("randwrite4k6h", "4k", diskname_list, "6h", "0")

    time_temp = time.localtime(time.time())
    print("End randwrite4k6h at: {}".format(time.strftime('%Y-%m-%-d %H:%M:%S', time_temp)))
    resultlog.write("End randwrite4k6h at: {}".format(time.strftime('%Y-%m-%-d %H:%M:%S', time_temp)) + os.linesep)

    for block_randwrite in randwrite_policy_list:
        time_temp = time.localtime(time.time())
        print("Start run randwrite-{} at: {}".format(block_randwrite, time.strftime('%Y-%m-%-d %H:%M:%S', time_temp)))
        resultlog.write("Start run randwrite-{} at: {}".format(block_randwrite, time.strftime('%Y-%m-%-d %H:%M:%S', time_temp)) + os.linesep)
        run_fio("randwrite", block_randwrite, diskname_list, "raw", "4")

    time_temp = time.localtime(time.time())
    print("End randwrite at: {}".format(time.strftime('%Y-%m-%-d %H:%M:%S', time_temp)))
    resultlog.write("End randwrite at: {}".format(time.strftime('%Y-%m-%-d %H:%M:%S', time_temp)) + os.linesep)
else:
    print("No randwrite! Skip!")
    resultlog.write("No randwrite! Skip!" + os.linesep)

time_end_temp = time.localtime(time.time())
time_end_write = time.strftime('%Y-%m-%d %H:%M:%S', time_end_temp)

resultlog.write("End FIO stress test!End time: {0}".format(time_end_write) + os.linesep)
print("End FIO stress test!End time {0}".format(time_end_write))
resultlog.close()
sys.exit(0)
