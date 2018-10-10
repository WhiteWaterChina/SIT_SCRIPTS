#Author:Ward Yan
###usage: client_ctrl_ip client_username client_password sut_devicename_list client_devicename_list threads_number test_time
import matplotlib
matplotlib.use('Agg')
import os
import sys
import time
import re
import subprocess
import matplotlib.pyplot as plyt
import paramiko
import json
import numpy

#path = os.path.abspath(os.path.join(os.path.dirname(__file__),os.pardir,os.pardir))
#sys.path.append(path)

current_path = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir))
sys.path.append(current_path)
time_start = time.strftime('%Y%m%d%H%M%S', time.localtime(time.time()))
log_dir_name = time_start + "_SIT_NETSTRESS_TEST_RHEL"
log_file_name = time_start + "_SIT_NETSTRESS_TEST_RHEL.log"
log_path_temp = current_path + "/log"
if not os.path.isdir(log_path_temp):
    os.mkdir(log_path_temp)

log_path_dir = log_path_temp + "/" + log_dir_name
log_path = log_path_dir + "/" + log_file_name
if not os.path.isdir(log_path_dir):
    os.mkdir(log_path_dir)
result = open(log_path, mode="w")
result.write("Begin net stress test!Start time %s" % time_start + os.linesep)
print("Begin net stress test!Start time %s" % time_start)

if len(sys.argv) != 8:
    print("Input length is incorrect!")
    print("Usage:%s client_ctrl_ip client_username client_password sut_devicename_list client_devicename_list threads_number test_time" % sys.argv[0])
    result.write("Input length is incorrect!" + os.linesep)
    result.write("Usage:%s client_ctrl_ip client_username client_password sut_devicename_list client_devicename_list threads_number test_time" % sys.argv[0] + os.linesep)
    result.close()
    sys.exit(255)

client_ctrl_ip = sys.argv[1]
client_username = sys.argv[2]
client_password = sys.argv[3]
sut_devicenames = sys.argv[4]
client_devicenames = sys.argv[5]
threads_number = sys.argv[6]
test_time = sys.argv[7]

#test input list length
sut_devicename_list_temp = sut_devicenames.split(";")
client_devicename_list_temp = client_devicenames.split(";")
sut_devicename_list = [item.strip()for item in sut_devicename_list_temp if len(item) != 0]
client_devicename_list = [item.strip() for item in client_devicename_list_temp if len(item) != 0]

if len(sut_devicename_list) != len(client_devicename_list):
    print("Input error! The length of sut_devicename_list need equal the length of client_devicename_list!")
    result.write("Input error! The length of sut_devicename_list need equal the length of client_devicename_list!" + os.linesep)
    result.close()
    sys.exit(255)

ssh_to_client = paramiko.SSHClient()
ssh_to_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

# login to client to start server
ssh_to_client.connect(client_ctrl_ip, 22, username=client_username, password=client_password)
ssh_to_client.exec_command(command='iperf -s -w 256k &')
ssh_to_client.close()
#test for input time
for index_sut_devicename, sut_devicename in enumerate(sut_devicename_list):
    client_devicename = client_devicename_list[index_sut_devicename]
    SutDevicePath = log_path_dir + '/Sut' + sut_devicename
    if not os.path.isdir(SutDevicePath):
        os.makedirs(SutDevicePath)

    # calculate N
    speed_now_list = subprocess.Popen("ethtool %s|grep Speed|awk -F ':' '{print $2}'|awk '{match($0,/([0-9]+)/,a);print a[1]}'" % sut_devicename, shell=True, stdout=subprocess.PIPE)
    speed_now_list.wait()
    speed_now = speed_now_list.stdout.readlines()[0].strip()

    if speed_now == "10000":
        N = 2
    elif speed_now == "25000":
        N = 3
    elif speed_now == "40000":
        N = 5
    elif speed_now == "100000":
        N = 10
    else:
        N = 4

    logname_result_iperf_sut = SutDevicePath + "/" + "result_iperf_sut_%s.txt" % test_time
    log_result = open(logname_result_iperf_sut, mode="wb")
    #get sut test ip
    ssh_to_client.connect(client_ctrl_ip, 22, username=client_username, password=client_password)
    stdin_getip, stdout_getip, stderr_getip = ssh_to_client.exec_command("ip addr show|grep %s|grep inet|awk '{match($s,/([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/,a);print a[1]}'" % client_devicename)
    client_test_ip_temp = stdout_getip.readlines()
    client_test_ip = client_test_ip_temp[0].strip()
    ssh_to_client.close()

    # iperf -c in sut
    subprocess.Popen("iperf -c %s -t %s -i 5 -w 256k -P %s |grep -i sum" % (client_test_ip, test_time, threads_number), shell=True, stdout=log_result, bufsize=1)


# test if iperf ended in sut
while 1 != 2:
    check_iperf_process = subprocess.Popen('ps -aux|grep "iperf -c"|grep -v grep', shell=True, stdout=subprocess.PIPE).stdout.readlines()
    # print(check_iperf_process)
    if len(check_iperf_process) == 0:
        print("iperf test for %s sedonds end!" % test_time)
        result.write("iperf test for %s sedonds end!" % test_time + os.linesep)
        time.sleep(2)
        break
    else:
        time.sleep(10)

#test for 1800 seconds
for index_sut_devicename, sut_devicename in enumerate(sut_devicename_list):
    client_devicename = client_devicename_list[index_sut_devicename]
    SutDevicePath = log_path_dir + '/Sut' + sut_devicename
    if not os.path.isdir(SutDevicePath):
        os.makedirs(SutDevicePath)

    # calculate N
    speed_now_list = subprocess.Popen("ethtool %s|grep Speed|awk -F ':' '{print $2}'|awk '{match($0,/([0-9]+)/,a);print a[1]}'" % sut_devicename, shell=True, stdout=subprocess.PIPE)
    speed_now_list.wait()
    speed_now = speed_now_list.stdout.readlines()[0].strip()

    if speed_now == "10000":
        N = 2
    elif speed_now == "25000":
        N = 3
    elif speed_now == "40000":
        N = 5
    elif speed_now == "100000":
        N = 10
    else:
        N = 8

    logname_result_iperf_sut = SutDevicePath + "/" + "result_iperf_sut_1800.txt"
    log_result = open(logname_result_iperf_sut, mode="wb")
    #get sut test ip
    ssh_to_client.connect(client_ctrl_ip, 22, username=client_username, password=client_password)
    stdin_getip_2, stdout_getip, stderr_getip_2 = ssh_to_client.exec_command("ip addr show|grep %s|grep inet|awk '{match($s,/([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/,a);print a[1]}'" % client_devicename)
    client_test_ip_temp = stdout_getip.readlines()
    client_test_ip = client_test_ip_temp[0].strip()
    ssh_to_client.close()

    # iperf -c in sut
    subprocess.Popen("iperf -c %s -t 1800 -i 5 -w 256k -P %s |grep -i sum" % (client_test_ip, threads_number), shell=True, stdout=log_result, bufsize=1)


# test if iperf ended in sut
while 1 != 2:
    check_iperf_process = subprocess.Popen('ps -aux|grep "iperf -c"|grep -v grep', shell=True, stdout=subprocess.PIPE).stdout.readlines()
    # print(check_iperf_process)
    if len(check_iperf_process) == 0:
        print("iperf test for 1800 seconds end!")
        result.write("iperf test for 1800 seconds end!")
        time.sleep(2)
        break
    else:
        time.sleep(10)
#close iperf in client remotely
ssh_to_client.connect(client_ctrl_ip, 22, username=client_username, password=client_password)
ssh_to_client.exec_command(command='killall -9 iperf')
ssh_to_client.close()

#check status
tc_result = {}
tc_result["total_result"] = "fail"
for index_sutdevicename, sut_devicename in enumerate(sut_devicename_list):

    tc_result["%s" % sut_devicename] = {}
    tc_result["%s" % sut_devicename]["result_%s" % sut_devicename] = "fail"
    # check ethtool -S result
    tc_result["%s" % sut_devicename]["ethtool_s_result"] = {}
    tc_result["%s" % sut_devicename]["ethtool_s_result"]["result"] = "fail"
    ethtool_s = subprocess.Popen('ethtool -S %s|grep -iE "err|fail|drop|lost"' % sut_devicename, shell=True, stdout=subprocess.PIPE)
    ethtool_s.wait()
    ethtool_s_temp = ethtool_s.stdout.readlines()
    for item_ethtool in ethtool_s_temp:
        name_error = unicode()
        number_error = unicode()
        item_ethtool_temp = [item.strip() for item in item_ethtool.split(":") if len(item) != 0]
        if len(item_ethtool_temp) == 2:
            name_error = item_ethtool_temp[0]
            number_error = item_ethtool_temp[1]
        elif len(item_ethtool_temp) == 3:
            name_error = item_ethtool_temp[1]
            number_error = item_ethtool_temp[2]
        if int(number_error) > 0:
            tc_result["%s" % sut_devicename]["ethtool_s_result"]["%s" % name_error] = number_error
    if len(tc_result["%s" % sut_devicename]["ethtool_s_result"]) == 1:
        tc_result["%s" % sut_devicename]["ethtool_s_result"]["result"] = "pass"
    # check lspci result
    # get pcie number
    pcie_bus = subprocess.Popen(
        "ethtool -i %s|grep 'bus-info'|awk '{match($0,/([0-9a-zA-Z]+:[0-9a-zA-Z]+\.[0-9a-zA-Z]+)/,a);print a[1]}'" % sut_devicename,
        shell=True, stdout=subprocess.PIPE).stdout.readlines()[0].strip()
    tc_result["%s" % sut_devicename]["lspci_vvv"] = {}
    tc_result["%s" % sut_devicename]["lspci_vvv"]["result"] = "fail"
    lspci_result = subprocess.Popen('lspci -vvv -s %s|grep -E "UESta|CESta"|grep +' % pcie_bus, shell=True,
                                    stdout=subprocess.PIPE).stdout.readlines()
    if len(lspci_result) == 0:
        tc_result["%s" % sut_devicename]["lspci_vvv"]["result"] = "pass"
    else:
        for item_lspci in lspci_result:
            name_item = item_lspci.split(":")[0].strip()
            error_info = item_lspci.split(":")[1].strip()
            tc_result["%s" % sut_devicename]["lspci_vvv"]["%s" % name_item] = {}
            pattern_error = re.compile(r"(\w*)\+")
            name_error = re.findall(pattern=pattern_error, string=error_info)
            for item_error in name_error:
                tc_result["%s" % sut_devicename]["lspci_vvv"]["%s" % name_item]["%s" % item_error] = "+"
    # check dmesg
    # get driver name
    sut_driver_name = subprocess.Popen("ethtool -i %s|grep driver|awk -F ':' '{print $2}'" % sut_devicename, shell=True,
                                       stdout=subprocess.PIPE).stdout.readlines()[0].strip()
    tc_result["%s" % sut_devicename]["dmesg_result"] = {}
    tc_result["%s" % sut_devicename]["dmesg_result"]["result"] = "fail"
    dmesg_result = subprocess.Popen(
        'dmesg|grep -E "%s|%s" |grep -iE "fail|err|warn|unsupport"' % (pcie_bus, sut_driver_name), shell=True,
        stdout=subprocess.PIPE).stdout.readlines()
    if len(dmesg_result) == 0:
        tc_result["%s" % sut_devicename]["dmesg_result"]["result"] = "pass"
    else:
        dmesg_error_list = []
        for item_dmesg in dmesg_result:
            dmesg_error_info = item_dmesg.strip()
            dmesg_error_list.append(dmesg_error_info)
        error_info_write = ";".join(dmesg_error_list)
        tc_result["%s" % sut_devicename]["dmesg_result"]["error_info"] = error_info_write
    # generate total result for one device
    if tc_result["%s" % sut_devicename]["ethtool_s_result"]["result"] == "pass" and \
                    tc_result["%s" % sut_devicename]["lspci_vvv"]["result"] == "pass" and \
                    tc_result["%s" % sut_devicename]["dmesg_result"]["result"] == "pass":
        tc_result["%s" % sut_devicename]["result_%s" % sut_devicename] = "pass"
resultcode = 0
for index_sutdevicename_sub, sut_devicename_sub in enumerate(sut_devicename_list):
    if tc_result["%s" % sut_devicename_sub]["result_%s" % sut_devicename_sub] == "pass":
        resultcode += 0
    else:
        resultcode += 1
if resultcode == 0:
    tc_result["total_result"] = "pass"

# change to json
data_string = json.dumps(tc_result, sort_keys=True, indent=4)
result.write("Below is the status check!" + os.linesep)
result.write(data_string + os.linesep)

#plot iperf result
image_path_dir = log_path_dir + "/image_result"
if not os.path.isdir(image_path_dir):
    os.mkdir(image_path_dir)
#plot iperf result for input test time
for index_sut_devicename, sut_devicename in enumerate(sut_devicename_list):
    iperf_result_list = []
    data_time= []
    data_high_list = []
    data_low_list = []
    data_average_list = []
    SutDevicePath = log_path_dir + '/Sut' + sut_devicename
    logpath = SutDevicePath + "/" + "result_iperf_sut_%s.txt" % test_time
    data_file = open(logpath, mode="r")
    data_filter = data_file.readlines()
    #testpath = SutDevicePath + "/" + "result_iperf_sut_test.txt"
    data_file.close()
    data_filter.pop()
    for item in data_filter:
        iperf_data_line = re.search(r'\[SUM\] .*?(\d+\.*\d*)\s(G|M)bits/sec', item)
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
    #plot
    filename_to_write = sut_devicename + "_iperf_result_image_%s" % test_time
    figure_1 = plyt.figure(filename_to_write)
    figure = figure_1.add_subplot(111)
    plyt.title(sut_devicename + "_iperf_result_image_%s" % test_time)
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
for index_sut_devicename_1800, sut_devicename_1800 in enumerate(sut_devicename_list):
    iperf_result_list_1800 = []
    data_time_1800 = []
    data_high_list_1800 = []
    data_low_list_1800 = []
    data_average_list_1800 = []
    SutDevicePath_1800 = log_path_dir + '/Sut' + sut_devicename_1800
    logpath_1800 = SutDevicePath_1800 + "/" + "result_iperf_sut_1800.txt"
    data_file_1800 = open(logpath_1800, mode="r")
    data_filter_1800 = data_file_1800.readlines()
    #testpath = SutDevicePath + "/" + "result_iperf_sut_test.txt"
    data_file_1800.close()
    data_filter_1800.pop()
    for item_1800 in data_filter_1800:
        iperf_data_line_1800 = re.search(r'\[SUM\] .*?(\d+\.*\d*)\s(G|M)bits/sec', item_1800)
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
    filename_to_write_1800 = sut_devicename_1800 + "_iperf_result_image_1800"
    figure_1_1800 = plyt.figure(filename_to_write_1800)
    figure_1800 = figure_1_1800.add_subplot(111)
    plyt.title(sut_devicename_1800 + "_iperf_result_image_1800")
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


