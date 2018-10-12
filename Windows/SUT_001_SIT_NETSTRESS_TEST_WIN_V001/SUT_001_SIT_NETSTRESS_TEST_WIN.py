# -*- coding:cp936 -*-
###usage: client_ctrl_ip client_username client_password sut_deviceip_list client_deviceip_list threads_number test_time
import matplotlib
matplotlib.use('Agg')
import os
import sys
import time
import re
import wmi
import subprocess
import matplotlib.pyplot as plyt
import numpy

# current_path = os.getcwd()
current_path = os.path.abspath(os.path.dirname(__file__))
sys.path.append(current_path)
time_start = time.strftime('%Y%m%d%H%M%S', time.localtime(time.time()))
log_dir_name = time_start + "_SIT_NETSTRESS_TEST_WIN"
log_file_name = time_start + "_SIT_NETSTRESS_TEST_WIN.log"
log_path_temp = current_path + "\log"
if not os.path.isdir(log_path_temp):
    os.mkdir(log_path_temp)

log_path_dir = log_path_temp + "\\" + log_dir_name
log_path = log_path_dir + "\\" + log_file_name
if not os.path.isdir(log_path_dir):
    os.mkdir(log_path_dir)
result = open(log_path, mode="w")
result.write("Begin net stress test!Start time %s" % time_start + os.linesep)
print("Begin net stress test!Start time %s" % time_start)

if len(sys.argv) != 8:
    print("Input length is incorrect!")
    print("Usage:%s client_ctrl_ip client_username client_password sut_deviceip_list client_deviceip_list threads_number test_time" % sys.argv[0])
    result.write("Input length is incorrect!" + os.linesep)
    result.write("Usage:%s client_ctrl_ip client_username client_password sut_deviceip_list client_deviceip_list threads_number test_time" % sys.argv[0] + os.linesep)
    result.close()
    sys.exit(255)
#get input
client_ctrl_ip = sys.argv[1]
client_username = sys.argv[2]
client_password = sys.argv[3]
sut_deviceips = sys.argv[4]
client_deviceips = sys.argv[5]
threads_number = sys.argv[6]
test_time = sys.argv[7]

if test_time == "1800":
    print  "Input  test time %s is equal 1800,in case of misunderstanding, change it to 1801!" % test_time
    result.write("Input  test time %s is equal 1800,in case of misunderstanding, change it to 1801!" % test_time + os.linesep)
    test_time = str(int(test_time) + 1)

if threads_number == "1":
    print("Input Error!Please increase threads_number to at least 2!")
    result.write("Input Error!Please increase threads_number to at least 2!" + os.linesep)
    result.close()
    sys.exit(255)

#test input list length
sut_deviceip_list_temp = sut_deviceips.split(";")
client_deviceip_list_temp = client_deviceips.split(";")
sut_deviceip_list = [item.strip()for item in sut_deviceip_list_temp if len(item) != 0]
client_deviceip_list = [item.strip() for item in client_deviceip_list_temp if len(item) != 0]

if len(sut_deviceip_list) != len(client_deviceip_list):
    print("Input error! The length of sut_devicenip_list need equal the length of client_deviceip_list!")
    result.write("Input error! The length of sut_deviceip_list need equal the length of client_deviceip_list!" + os.linesep)
    result.close()
    sys.exit(255)

#connect to remote windows to start iperf -s  -w 256k
connect_to_remote = wmi.WMI(computer=client_ctrl_ip, user=client_username, password=client_password)
cmd_create_iperf_remote = r"c:\windowstool\windowstool\iperf-2.0.5-cygwin\iperf.exe -s -w 256k"
connect_to_remote.Win32_Process.Create(CommandLine=cmd_create_iperf_remote)
#test for input time
connect_to_local = wmi.WMI()
for index_sut_deviceip, sut_deviceip in enumerate(sut_deviceip_list):
    client_deviceip = client_deviceip_list[index_sut_deviceip]
    SutDevicePath = log_path_dir + '\Sut' + sut_deviceip
    if not os.path.isdir(SutDevicePath):
        os.makedirs(SutDevicePath)
    # for item_netinfo_get_index in connect_to_local.Win32_NetworkAdapterConfiguration():
    #     if item_netinfo_get_index.IpAddress is not None:
    #         net_ip_temp = (item_netinfo_get_index.IpAddress)[0].strip()
    #         if net_ip_temp == sut_deviceip:
    #             index_net = item_netinfo_get_index.Index
    #
    # for item_netinfo_get_speed in connect_to_local.Win32_NetworkAdapter():
    #     if item_netinfo_get_speed.Index == index_net:
    #         speed_now = item_netinfo_get_speed.speed.strip()
    # if speed_now == "1000000000":
    #     N = 2
    # elif speed_now == "10000000000":
    #     N = 2
    # elif speed_now == "25000000000":
    #     N = 3
    # elif speed_now == "40000000000":
    #     N = 5
    # elif speed_now == "100000000000":
    #     N = 11
    # else:
    #     N = 4

    logname_result_iperf_sut = SutDevicePath + "\\" + "result_iperf_sut_%s.txt" % test_time
    name_scripts_to_run_iperf_c = SutDevicePath + "\\" + "iperf_c_sut_%s.ps1" % test_time
    scripts_to_run_iperf_c = open(name_scripts_to_run_iperf_c, mode="wb")
    # iperf -c in sut
    start_iperf_c_local = r"c:\windowstool\windowstool\iperf-2.0.5-cygwin\iperf.exe -c %s -t %s -i 5 -w 256k -P %s|out-file -append -force -encoding ascii %s"% (client_deviceip, test_time, threads_number, logname_result_iperf_sut)
    scripts_to_run_iperf_c.write(start_iperf_c_local)
    scripts_to_run_iperf_c.close()
    subprocess.Popen(["powershell.exe", "%s" % name_scripts_to_run_iperf_c],stdout=subprocess.PIPE)

# test if iperf ended in sut after test_time
time.sleep(30)
while 1 != 2:
    check_iperf_process = connect_to_local.win32_Process(name="iperf.exe")
    if len(check_iperf_process) == 0:
        print("iperf test for %s seconds end!" % test_time)
        result.write("iperf test for %s seconds end!" % test_time + os.linesep)
        time.sleep(2)
        break
    else:
        time.sleep(10)
# end iperf -s remotely
time.sleep(10)
for item_iperf_remote in connect_to_remote.win32_process():
    if item_iperf_remote.name == "iperf.exe":
        item_iperf_remote.Terminate()
time.sleep(60)

#test for 1800 seconds
# cmd_create_iperf_remote = r"c:\windowstool\windowstool\iperf-2.0.5-cygwin\iperf.exe -s -w 256k"
connect_to_remote.Win32_Process.Create(CommandLine=cmd_create_iperf_remote)

for index_sut_deviceip, sut_deviceip in enumerate(sut_deviceip_list):
    client_deviceip = client_deviceip_list[index_sut_deviceip]
    SutDevicePath = log_path_dir + '\Sut' + sut_deviceip
    if not os.path.isdir(SutDevicePath):
        os.makedirs(SutDevicePath)
    # for item_netinfo_get_index in connect_to_local.Win32_NetworkAdapterConfiguration():
    #     if item_netinfo_get_index.IpAddress is not None:
    #         net_ip_temp = (item_netinfo_get_index.IpAddress)[0].strip()
    #         if net_ip_temp == sut_deviceip:
    #             index_net = item_netinfo_get_index.Index
    #
    # for item_netinfo_get_speed in connect_to_local.Win32_NetworkAdapter():
    #     if item_netinfo_get_speed.Index == index_net:
    #         speed_now = item_netinfo_get_speed.speed.strip()
    # if speed_now == "1000000000":
    #     N = 2
    # elif speed_now == "10000000000":
    #     N = 2
    # elif speed_now == "25000000000":
    #     N = 3
    # elif speed_now == "40000000000":
    #     N = 5
    # elif speed_now == "100000000000":
    #     N = 11
    # else:
    #     N = 4

    logname_result_iperf_sut = SutDevicePath + "\\" + "result_iperf_sut_1800.txt"
    name_scripts_to_run_iperf_c = SutDevicePath + "\\" + "iperf_c_sut_1800.ps1"
    scripts_to_run_iperf_c = open(name_scripts_to_run_iperf_c, mode="wb")
    # iperf -c in sut
    start_iperf_c_local = r"c:\windowstool\windowstool\iperf-2.0.5-cygwin\iperf.exe -c %s -t 1800 -i 5 -w 256k -P %s|out-file -append -force -encoding ascii %s" % (
    client_deviceip, threads_number, logname_result_iperf_sut)
    scripts_to_run_iperf_c.write(start_iperf_c_local)
    scripts_to_run_iperf_c.close()
    subprocess.Popen(["powershell.exe", "%s" % name_scripts_to_run_iperf_c], stdout=subprocess.PIPE)

# test if iperf ended in sut after 1800 seconds
time.sleep(30)
while 1 != 2:
    check_iperf_process = connect_to_local.win32_Process(name="iperf.exe")
    if len(check_iperf_process) == 0:
        print("iperf test for 1800 seconds end!")
        result.write("iperf test for 1800 seconds end!" + os.linesep)
        time.sleep(2)
        break
    else:
        time.sleep(10)
# end iperf -s remotely
time.sleep(10)
for item_iperf_remote in connect_to_remote.win32_process():
    if item_iperf_remote.name == "iperf.exe":
        item_iperf_remote.Terminate()
time.sleep(60)
# plot iperf result
image_path_dir = log_path_dir + "\image_result"
if not os.path.isdir(image_path_dir):
    os.mkdir(image_path_dir)
#plot for test time
for index_sut_deviceip, sut_deviceip in enumerate(sut_deviceip_list):
    iperf_result_list = []
    data_time= []
    data_high_list = []
    data_low_list = []
    data_average_list = []
    SutDevicePath = log_path_dir + '\Sut' + sut_deviceip
    logpath = SutDevicePath + "\\" + "result_iperf_sut_%s.txt" % test_time
    data_file = open(logpath, mode="r")
    data_filter = data_file.readlines()
    data_file.close()
    data_filter.pop()
    pattern_speed = re.compile(r"\[SUM\] .*?(\d+\.*\d*)\s(M|G)bits/sec")
    for item in data_filter:
        iperf_data_line = re.search(pattern=pattern_speed, string=item)
        if iperf_data_line is not None:
            if len(iperf_data_line.groups()) != 2:
                continue
            else:
                if iperf_data_line.groups()[1] == "M":
                    data_one_line = float(iperf_data_line.groups()[0]) / 1000
                else:
                    data_one_line = float(iperf_data_line.groups()[0])
                iperf_result_list.append(data_one_line)
    average_data = float(sum(iperf_result_list)) / float(len(iperf_result_list))
    data_high = average_data * 1.1
    data_low = average_data * 0.9
    data_higest = max(iperf_result_list)
    index_higest = iperf_result_list.index(data_higest)
    data_lowest = min(iperf_result_list)
    index_lowest = iperf_result_list.index(data_lowest)

    for i in range(1, len(iperf_result_list) + 1):
        data_time.append(i*5)
    for count in range(len(iperf_result_list)):
        data_high_list.append(data_high)
        data_low_list.append(data_low)
        data_average_list.append(average_data)
    data_x = numpy.array(data_time)
    data_y = numpy.array(iperf_result_list)
    # plot
    filename_to_write = sut_deviceip + "_iperf_result_image_%s" % test_time
    figure_1 = plyt.figure(filename_to_write)
    figure = figure_1.add_subplot(111)
    plyt.title(sut_deviceip + "_iperf_result_image_%s" % test_time)
    plyt.xlabel('time(s)')
    plyt.ylabel('Speed(Gbits/s)')
    plyt.plot(data_x, data_y, label='Actul Speed')
    plyt.plot(data_x, numpy.array(data_high_list), label='110% Average')
    plyt.plot(data_x, numpy.array(data_low_list), label='90% Average')
    plyt.plot(data_x, numpy.array(data_average_list), label='Average')
    leg = plyt.legend(loc='best', ncol=2, mode="expand", shadow=False, fancybox=True)
    leg.get_frame().set_alpha(0.5)
    time.sleep(1)
    filename_to_write_all = filename_to_write + '.png'
    filename_to_save = os.path.join(image_path_dir, filename_to_write_all)
    figure_1.savefig(filename_to_save)

#plot for 1800 seconds
for index_sut_deviceip_1800, sut_deviceip_1800 in enumerate(sut_deviceip_list):
    iperf_result_list_1800 = []
    data_time_1800 = []
    data_high_list_1800 = []
    data_low_list_1800 = []
    data_average_list_1800 = []
    SutDevicePath_1800 = log_path_dir + '\Sut' + sut_deviceip_1800
    logpath_1800 = SutDevicePath_1800 + "\\" + "result_iperf_sut_1800.txt"
    data_file_1800 = open(logpath_1800, mode="r")
    data_filter_1800 = data_file_1800.readlines()
    data_file_1800.close()
    data_filter_1800.pop()
    pattern_speed = re.compile(r"\[SUM\] .*?(\d+\.*\d*)\s(M|G)bits/sec")
    for item_1800 in data_filter_1800:
        iperf_data_line_1800 = re.search(pattern=pattern_speed, string=item_1800)
        if iperf_data_line_1800 is not None:
            if len(iperf_data_line_1800.groups()) != 2:
                continue
            else:
                if iperf_data_line_1800.groups()[1] == "M":
                    data_one_line_1800 = float(iperf_data_line_1800.groups()[0]) / 1000
                else:
                    data_one_line_1800 = float(iperf_data_line_1800.groups()[0])
                iperf_result_list_1800.append(data_one_line_1800)
    average_data_1800 = float(sum(iperf_result_list_1800)) / float(len(iperf_result_list_1800))
    data_high_1800 = average_data_1800 * 1.1
    data_low_1800 = average_data_1800 * 0.9
    data_higest_1800 = max(iperf_result_list_1800)
    index_higest_1800 = iperf_result_list_1800.index(data_higest_1800)
    data_lowest_1800 = min(iperf_result_list_1800)
    index_lowest_1800 = iperf_result_list_1800.index(data_lowest_1800)

    for i in range(1, len(iperf_result_list_1800) + 1):
        data_time_1800.append(i * 5)

    for count_1800 in range(len(iperf_result_list_1800)):
        data_high_list_1800.append(data_high_1800)
        data_low_list_1800.append(data_low_1800)
        data_average_list_1800.append(average_data_1800)

    data_x_1800 = numpy.array(data_time_1800)
    data_y_1800 = numpy.array(iperf_result_list_1800)
    # plot
    filename_to_write_1800 = sut_deviceip_1800 + "_iperf_result_image_1800"
    figure_1_1800 = plyt.figure(filename_to_write_1800)
    figure_1800 = figure_1_1800.add_subplot(111)
    plyt.title(sut_deviceip_1800 + "_iperf_result_image_1800")
    plyt.xlabel('time(s)')
    plyt.ylabel('Speed(Gbits/s)')
    plyt.plot(data_x_1800, data_y_1800, label='Actul Speed')
    plyt.plot(data_x_1800, numpy.array(data_high_list_1800), label='110% Average')
    plyt.plot(data_x_1800, numpy.array(data_low_list_1800), label='90% Average')
    plyt.plot(data_x_1800, numpy.array(data_average_list_1800), label='Average')
    leg = plyt.legend(loc='best', ncol=2, mode="expand", shadow=False, fancybox=True)
    leg.get_frame().set_alpha(0.5)
    time.sleep(1)
    filename_to_write_all_1800 = filename_to_write_1800 + '.png'
    filename_to_save_1800 = os.path.join(image_path_dir, filename_to_write_all_1800)
    figure_1_1800.savefig(filename_to_save_1800)

time_end = time.strftime('%Y%m%d%H%M%S', time.localtime(time.time()))
print("End net stress test!Start time %s" % time_end)
result.write("End net stress test!Start time %s" % time_end + os.linesep)
result.close()
sys.exit(0)