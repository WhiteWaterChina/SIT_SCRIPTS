# Author:Ward Yan
# usage: client_ctrl_ip client_username client_password sut_devicename_list client_devicename_list test_time
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
import argparse


def plot_image(log_path_sub, figure_title, filepath_to_save):
    iperf_result_list = []
    data_time = []
    data_high_list = []
    data_low_list = []
    data_average_list = []
    data_file = open(log_path_sub, mode="r")
    data_filter = data_file.readlines()
    data_file.close()
    data_filter.pop()
    for item_sub in data_filter:
        iperf_data_line = re.search(r'\[SUM\] .*?(\d+\.*\d*)\s([GM])bits/sec', item_sub)
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
    # data_higest = max(iperf_result_list)
    # index_higest = iperf_result_list.index(data_higest)
    # data_lowest = min(iperf_result_list)
    # index_lowest = iperf_result_list.index(data_lowest)
    for i in range(1, len(iperf_result_list) + 1):
        data_time.append(i * 5)
    for count in range(len(iperf_result_list)):
        data_high_list.append(data_high)
        data_low_list.append(data_low)
        data_average_list.append(average_data)
    data_x = numpy.array(data_time)
    data_y = numpy.array(iperf_result_list)
    # plot
    figure_1 = plyt.figure(figure_title)
    figure_1.add_subplot(111)
    plyt.title(figure_title)
    plyt.xlabel('time(s)')
    plyt.ylabel('Speed(Gbits/s)')
    plyt.plot(data_x, data_y, label='Actul Speed')
    plyt.plot(data_x, numpy.array(data_high_list), label='110% Average')
    plyt.plot(data_x, numpy.array(data_low_list), label='90% Average')
    plyt.plot(data_x, numpy.array(data_average_list), label='Average')
    leg = plyt.legend(loc='best', ncol=2, mode="expand", shadow=False, fancybox=True)
    leg.get_frame().set_alpha(0.5)
    time.sleep(1)
    figure_1.savefig(filepath_to_save)


def root_arg():
    parser = argparse.ArgumentParser(description="Script to test network card two way!")
    parser.add_argument('--ip', '-ip', required=True, type=str, dest='client_ctrl_ip',
                        help="The ip of the control client, must can be connected to SUT")
    parser.add_argument('--username', '-u', default='root', type=str, dest='client_username',
                        help="The username of the control client, default is root")
    parser.add_argument('--password', '-p', default='111111', type=str, dest='client_password',
                        help="The password of the control client, default is 111111")
    parser.add_argument('--client', required=True, type=str, dest='client_devicenames',
                        help="The list of the NIC device names on client,must split by ';'. For expmple: eno1;eno2;")
    parser.add_argument('--sut', required=True, type=str, dest='sut_devicenames',
                        help="The list of the NIC device names on SUT, must split by ';'. For expmple: eno1;eno2;")
    parser.add_argument('--time', '-t', required=True, type=int, dest='test_time', help="The total time of the test")
    input_arg_sub = parser.parse_args()
    return input_arg_sub


def calculate_threads(device_name):
    # calculate N
    speed_now_list = subprocess.Popen(
        "ethtool {}|grep Speed|awk -F ':' '{{print $2}}'|awk '{{match($0,/([0-9]+)/,a);print a[1]}}'".format(
            device_name), shell=True, stdout=subprocess.PIPE)
    speed_now_list.wait()
    speed_now = speed_now_list.stdout.readlines()[0].strip()

    if speed_now == "10000":
        threads_number = 2
    elif speed_now == "25000":
        threads_number = 3
    elif speed_now == "40000":
        threads_number = 5
    elif speed_now == "100000":
        threads_number = 10
    else:
        threads_number = 4
    return threads_number


def check_iperf(destination, ssh_client, client_ip, client_username_sub, client_password_sub):
    if destination == "local":
        retcode_check_iperf_local = subprocess.Popen("which iperf3", shell=True, stdout=subprocess.PIPE)
        retcode_check_iperf_local.wait()
        if retcode_check_iperf_local.returncode != 0:
            return ["Pls install iperf3 for local", retcode_check_iperf_local.returncode]
        reccode_check_iperf_ver_local = subprocess.Popen("iperf3 -h|grep forceflush", shell=True,
                                                         stdout=subprocess.PIPE)
        reccode_check_iperf_ver_local.wait()
        if reccode_check_iperf_ver_local.returncode != 0:
            return ["Pls install iperf3 with parameter 'forceflush' for local. For example:iperf-3.3",
                    reccode_check_iperf_ver_local.returncode]
        return ["Check iperf3 for local pass!", 0]
    elif destination == "remote":
        ssh_client.connect(client_ip, 22, username=client_username_sub, password=client_password_sub)
        stdin_1, stdout_1, stderr_1 = ssh_client.exec_command(command="which iperf3")
        if stdout_1.channel.recv_exit_status() != 0:
            ssh_client.close()
            return ["Pls install iperf3 for remote", stdout_1.channel.recv_exit_status()]
        else:
            ssh_client.close()
            ssh_client.connect(client_ip, 22, username=client_username_sub, password=client_password_sub)
        stdin_2, stdout_2, stderr_2 = ssh_client.exec_command(command="iperf3 -h|grep forceflush")
        if stdout_2.channel.recv_exit_status() != 0:
            ssh_client.close()
            return ["Pls install iperf3 with parameter 'forceflush' for remote. For example:iperf-3.3",
                    stdout_2.channel.recv_exit_status()]
        else:
            ssh_client.close()
        return ["Check iperf3 for remote pass!", 0]


current_path = os.path.abspath(os.path.dirname(__file__))
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

# create log dir for sut
log_path_dir_sut = log_path_temp + "/" + log_dir_name + "/sut"
if not os.path.isdir(log_path_dir_sut):
    os.mkdir(log_path_dir_sut)

# creat log dir for client
log_path_dir_client = log_path_temp + "/" + log_dir_name + "/client"
if not os.path.isdir(log_path_dir_client):
    os.mkdir(log_path_dir_client)

result = open(log_path, mode="w")
result.write("Begin net stress test!Start time {}".format(time_start) + os.linesep)
print("Begin net stress test!Start time {}".format(time_start))

input_arg = root_arg()
client_ctrl_ip = input_arg.client_ctrl_ip
client_username = input_arg.client_username
client_password = input_arg.client_password
sut_devicenames = input_arg.sut_devicenames
client_devicenames = input_arg.client_devicenames
test_time = input_arg.test_time

# test input list length
sut_devicename_list_temp = sut_devicenames.split(";")
client_devicename_list_temp = client_devicenames.split(";")
sut_devicename_list = [item.strip() for item in sut_devicename_list_temp if len(item) != 0]
client_devicename_list = [item.strip() for item in client_devicename_list_temp if len(item) != 0]

if len(sut_devicename_list) != len(client_devicename_list):
    print("Input error! The length of sut_devicename_list need equal the length of client_devicename_list!")
    result.write(
        "Input error! The length of sut_devicename_list need equal the length of client_devicename_list!" + os.linesep)
    result.close()
    sys.exit(255)

ssh_to_client = paramiko.SSHClient()
ssh_to_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

# mkdir client log file
client_log_path = "/root/netstresslog/{}".format(time_start)
ssh_to_client.connect(client_ctrl_ip, 22, username=client_username, password=client_password)
ssh_to_client.exec_command(
    command="if [ ! -d {client_log_dir} ];then mkdir -p {client_log_dir};fi".format(client_log_dir=client_log_path))
for client_devicename in client_devicename_list:
    client_net_log_name = client_log_path + "/Client" + client_devicename
    ssh_to_client.exec_command(
        command="if [ ! -d {client_net_log_name} ];then mkdir -p {client_net_log_name};fi".format(
            client_net_log_name=client_net_log_name))

# kill iperf in remote
ssh_to_client.exec_command(command="killall -9 iperf")
ssh_to_client.close()
# kill iperf in sut
subprocess.Popen("killall -9 iperf", shell=True, stdout=subprocess.PIPE).wait()
# login to client to start iperf server
ssh_to_client.connect(client_ctrl_ip, 22, username=client_username, password=client_password)
ssh_to_client.exec_command(command='iperf -s &')
ssh_to_client.close()
# start iperf server in sut
subprocess.Popen("iperf -s &", shell=True, stdout=subprocess.PIPE).wait()
print("Start to test for {} seconds!".format(test_time))
result.write("Start to test for {} seconds!".format(test_time))

# test for input total time
for index_sut_devicename, sut_devicename in enumerate(sut_devicename_list):
    client_devicename = client_devicename_list[index_sut_devicename]
    SutDevicePath = log_path_dir_sut + '/Sut' + sut_devicename
    ClientDevicePath = client_log_path + "/Client" + client_devicename
    if not os.path.isdir(SutDevicePath):
        os.makedirs(SutDevicePath)

    logname_result_iperf_sut_input_time = SutDevicePath + "/" + "result_iperf_sut_{}.txt".format(test_time)
    # log_result_sut_input_time = open(logname_result_iperf_sut_input_time, mode="wb")
    with open(logname_result_iperf_sut_input_time, mode="wb") as f:
        f.write("start" + os.linesep)
    logname_result_iperf_client_input_time = ClientDevicePath + "/result_iperf_client_{}.txt".format(test_time)
    # log_result_client = open(logname_result_iperf_client, mode="wb")

    # get client test ip
    ssh_to_client.connect(client_ctrl_ip, 22, username=client_username, password=client_password)
    stdin_getip, stdout_getip, stderr_getip = ssh_to_client.exec_command(
        "ip addr show|grep {}|grep inet|awk '{{match($s,/([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/,a);print a[1]}}'".format(
            client_devicename))
    client_test_ip_temp = stdout_getip.readlines()
    try:
        client_test_ip = client_test_ip_temp[0].strip()
    except IndexError:
        print("Can not get ip for Client Device:{}".format(client_devicename))
        result.write("Can not get ip for Client Device:{}".format(client_devicename))
        sys.exit(255)
    finally:
        ssh_to_client.close()
    # get sut test ip
    sut_test_ip_temp = subprocess.Popen(
        "ip addr show|grep {}|grep inet|awk '{{match($s,/([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/,a);print a[1]}}'".format(
            sut_devicename), shell=True, stdout=subprocess.PIPE).stdout.readlines()
    try:
        sut_test_ip = sut_test_ip_temp[0].strip()
    except IndexError:
        print("Can not get ip for Sut Device:{}".format(sut_devicename))
        result.write("Can not get ip for Sut Device:{}".format(sut_devicename))
        sys.exit(255)
    threads_iperf = calculate_threads(sut_devicename)
    # start iperf3 -c in sut
    subprocess.Popen("iperf -c {} -t {} -i 5 -w 256k -P {} >> {} &".format(client_test_ip, test_time, threads_iperf,
                                                                           logname_result_iperf_sut_input_time),
                     shell=True, bufsize=0, universal_newlines=True)
    # start iperf3 -c in client
    ssh_to_client.connect(client_ctrl_ip, 22, username=client_username, password=client_password)
    ssh_to_client.exec_command(
        command="iperf -c {} -t {} -i 5 -w 256k -P {} >> {} &".format(sut_test_ip, test_time, threads_iperf,
                                                                      logname_result_iperf_client_input_time))
    ssh_to_client.close()

# test if iperf3 ended in sut
while 1 != 2:
    check_iperf_process = subprocess.Popen('ps -aux|grep "iperf -c"|grep -v grep', shell=True,
                                           stdout=subprocess.PIPE).stdout.readlines()
    # print(check_iperf_process)
    if len(check_iperf_process) == 0:
        print("iperf test for {} seconds end from sut to client!".format(test_time))
        result.write("iperf test for {} seconds end from sut to client!".format(test_time) + os.linesep)
        time.sleep(2)
        ssh_to_client.connect(client_ctrl_ip, 22, username=client_username, password=client_password)
        stdin_getiperf, stdout_getiperf, stderr_getiperf = ssh_to_client.exec_command(
            'ps -aux|grep "iperf -c"|grep -v grep')
        ssh_to_client.close()
        if len(stdout_getiperf.readlines()) == 0:
            print("iperf test for {} seconds end from client to sut!".format(test_time))
            result.write("iperf test for {} seconds end from client to sut!".format(test_time) + os.linesep)
            time.sleep(2)
            break
    else:
        time.sleep(10)

# test for 1800 seconds
print("Start to test for 1800 seconds!")
result.write("Start to test for 1800 seconds!")
for index_sut_devicename, sut_devicename in enumerate(sut_devicename_list):
    client_devicename = client_devicename_list[index_sut_devicename]
    SutDevicePath = log_path_dir_sut + '/Sut' + sut_devicename
    ClientDevicePath = client_log_path + "/Client" + client_devicename
    if not os.path.isdir(SutDevicePath):
        os.makedirs(SutDevicePath)

    logname_result_iperf_sut_1800 = SutDevicePath + "/" + "result_iperf_sut_1800.txt"
    with open(logname_result_iperf_sut_1800, mode="wb") as f:
        f.write("start" + os.linesep)
    # log_result_sut_1800 = open(logname_result_iperf_sut_1800, mode="wb")
    logname_result_iperf_client_1800 = ClientDevicePath + "/result_iperf_client_1800.txt"

    # get client test ip
    ssh_to_client.connect(client_ctrl_ip, 22, username=client_username, password=client_password)
    stdin_getip_2, stdout_getip_1800, stderr_getip_2 = ssh_to_client.exec_command(
        "ip addr show|grep {}|grep inet|awk '{{match($s,/([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/,a);print a[1]}}'".format(
            client_devicename))
    client_test_ip_temp = stdout_getip_1800.readlines()
    try:
        client_test_ip_1800 = client_test_ip_temp[0].strip()
    except IndexError:
        print("Can not get ip for Client Device:{}".format(client_devicename))
        result.write("Can not get ip for Client Device:{}".format(client_devicename))
        break
    finally:
        ssh_to_client.close()
    # get sut test ip
    sut_test_ip_temp = subprocess.Popen(
        "ip addr show|grep {}|grep inet|awk '{{match($s,/([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/,a);print a[1]}}'".format(
            sut_devicename), shell=True, stdout=subprocess.PIPE).stdout.readlines()
    try:
        sut_test_ip_1800 = sut_test_ip_temp[0].strip()
    except IndexError:
        print("Can not get ip for Sut Device:{}".format(sut_devicename))
        result.write("Can not get ip for Sut Device:{}".format(sut_devicename))
        break

    threads_iperf_1800 = calculate_threads(sut_devicename)
    # iperf3 -c in sut for 1800s
    subprocess.Popen("iperf -c {} -t 1800 -i 5 -w 256k -P {} >> {} &".format(client_test_ip_1800, threads_iperf_1800,
                                                                             logname_result_iperf_sut_1800), shell=True,
                     bufsize=0, universal_newlines=True)
    # start iperf3 -c in client for 1800s
    ssh_to_client.connect(client_ctrl_ip, 22, username=client_username, password=client_password)
    ssh_to_client.exec_command(
        command="iperf -c {} -t 1800 -i 5 -w 256k -P {} >> {} &".format(sut_test_ip_1800, threads_iperf_1800,
                                                                        logname_result_iperf_client_1800))
    ssh_to_client.close()
# test if iperf3 ended in sut
while 1 != 2:
    check_iperf_process = subprocess.Popen('ps -aux|grep "iperf -c"|grep -v grep', shell=True,
                                           stdout=subprocess.PIPE).stdout.readlines()
    if len(check_iperf_process) == 0:
        print("iperf test for 1800 seconds end from sut to client!")
        result.write("iperf test for 1800 seconds end from sut to client!" + os.linesep)
        time.sleep(2)
        ssh_to_client.connect(client_ctrl_ip, 22, username=client_username, password=client_password)
        stdin_getiperf, stdout_getiperf, stderr_getiperf = ssh_to_client.exec_command(
            'ps -aux|grep "iperf -c"|grep -v grep')
        ssh_to_client.close()
        if len(stdout_getiperf.readlines()) == 0:
            print("iperf test for 1800 seconds end from client to sut!")
            result.write("iperf test for 1800 seconds end from client to sut!" + os.linesep)
            time.sleep(2)
            break
    else:
        time.sleep(10)
# close iperf server in client remotely
ssh_to_client.connect(client_ctrl_ip, 22, username=client_username, password=client_password)
ssh_to_client.exec_command(command='killall -9 iperf')
ssh_to_client.close()
# close iperf server in sut
subprocess.Popen("killall -9 iperf", shell=True, stdout=subprocess.PIPE).wait()

# check status
tc_result = {"total_result": "fail"}
for index_sutdevicename, sut_devicename in enumerate(sut_devicename_list):
    tc_result["{}".format(sut_devicename)] = {}
    tc_result["{}".format(sut_devicename)]["result_{}".format(sut_devicename)] = "fail"
    # check ethtool -S result
    tc_result["{}".format(sut_devicename)]["ethtool_s_result"] = {}
    tc_result["{}".format(sut_devicename)]["ethtool_s_result"]["result"] = "fail"
    ethtool_s = subprocess.Popen('ethtool -S {}|grep -iE "err|fail|drop|lost"'.format(sut_devicename), shell=True,
                                 stdout=subprocess.PIPE)
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
            tc_result["{}".format(sut_devicename)]["ethtool_s_result"]["{}".format(name_error)] = number_error
    if len(tc_result["{}".format(sut_devicename)]["ethtool_s_result"]) == 1:
        tc_result["{}".format(sut_devicename)]["ethtool_s_result"]["result"] = "pass"
    # check lspci result
    # get pcie number
    pcie_bus = subprocess.Popen(
        "ethtool -i {}|grep 'bus-info'|awk '{{match($0,/([0-9a-zA-Z]+:[0-9a-zA-Z]+\.[0-9a-zA-Z]+)/,a);print a[1]}}'".format(
            sut_devicename), shell=True, stdout=subprocess.PIPE).stdout.readlines()[0].strip()
    tc_result["{}".format(sut_devicename)]["lspci_vvv"] = {}
    tc_result["{}".format(sut_devicename)]["lspci_vvv"]["result"] = "fail"
    lspci_result = subprocess.Popen('lspci -vvv -s {}|grep -E "UESta|CESta"|grep +'.format(pcie_bus), shell=True,
                                    stdout=subprocess.PIPE).stdout.readlines()
    if len(lspci_result) == 0:
        tc_result["{}".format(sut_devicename)]["lspci_vvv"]["result"] = "pass"
    else:
        for item_lspci in lspci_result:
            name_item = item_lspci.split(":")[0].strip()
            error_info = item_lspci.split(":")[1].strip()
            tc_result["{}".format(sut_devicename)]["lspci_vvv"]["{}".format(name_item)] = {}
            pattern_error = re.compile(r"(\w*)\+")
            name_error = re.findall(pattern=pattern_error, string=error_info)
            for item_error in name_error:
                tc_result["{}".format(sut_devicename)]["lspci_vvv"]["{}".format(name_item)][
                    "{}".format(item_error)] = "+"
    # check dmesg
    # get driver name
    sut_driver_name = subprocess.Popen("ethtool -i {}|grep driver|awk -F ':' '{{print $2}}'".format(sut_devicename), shell=True, stdout=subprocess.PIPE).stdout.readlines()[0].strip()
    tc_result["{}".format(sut_devicename)]["dmesg_result"] = {}
    tc_result["{}".format(sut_devicename)]["dmesg_result"]["result"] = "fail"
    dmesg_result = subprocess.Popen(
        'dmesg|grep -E "{}|{}" |grep -iE "fail|err|warn|unsupport"'.format(pcie_bus, sut_driver_name), shell=True,
        stdout=subprocess.PIPE).stdout.readlines()
    if len(dmesg_result) == 0:
        tc_result["{}".format(sut_devicename)]["dmesg_result"]["result"] = "pass"
    else:
        dmesg_error_list = []
        for item_dmesg in dmesg_result:
            dmesg_error_info = item_dmesg.strip()
            dmesg_error_list.append(dmesg_error_info)
        error_info_write = ";".join(dmesg_error_list)
        tc_result["{}".format(sut_devicename)]["dmesg_result"]["error_info"] = error_info_write
    # generate total result for one device
    if tc_result["{}".format(sut_devicename)]["ethtool_s_result"]["result"] == "pass" and \
            tc_result["{}".format(sut_devicename)]["lspci_vvv"]["result"] == "pass" and \
            tc_result["{}".format(sut_devicename)]["dmesg_result"]["result"] == "pass":
        tc_result["{}".format(sut_devicename)]["result_{}".format(sut_devicename)] = "pass"
resultcode = 0
for index_sutdevicename_sub, sut_devicename_sub in enumerate(sut_devicename_list):
    if tc_result["{}".format(sut_devicename_sub)]["result_{}".format(sut_devicename_sub)] == "pass":
        resultcode += 0
    else:
        resultcode += 1
if resultcode == 0:
    tc_result["total_result"] = "pass"

# change status to json
data_string = json.dumps(tc_result, sort_keys=True, indent=4)
result.write("Below is the status check!" + os.linesep)
result.write(data_string + os.linesep)

# plot iperf result
image_path_dir = log_path_dir + "/image_result"
if not os.path.isdir(image_path_dir):
    os.mkdir(image_path_dir)

# copy data from client to sut
# zip log in client
ssh_to_client.connect(client_ctrl_ip, 22, username=client_username, password=client_password)
ssh_to_client.exec_command(command='cd /root/netstresslog/;tar -zcf {}.tgz {}'.format(time_start, time_start))
ssh_to_client.close()
# copy
copy_from_client = paramiko.Transport('{}:22'.format(client_ctrl_ip))
copy_from_client.connect(username=client_username, password=client_password)
download_from_client = paramiko.SFTPClient.from_transport(copy_from_client)
local_path_client_log = os.path.join(log_path_dir_client, "{}.tgz".format(time_start))
download_from_client.get(localpath=local_path_client_log, remotepath="/root/netstresslog/{}.tgz".format(time_start))

# unzip client log file
subprocess.Popen("cd {};tar -zxf {}.tgz".format(log_path_dir_client, time_start), shell=True,
                 stdout=subprocess.PIPE).wait()

# plot iperf result for input test time for sut
for index_sut_devicename, sut_devicename in enumerate(sut_devicename_list):
    sutDevicePathInputTime = log_path_dir_sut + '/Sut' + sut_devicename
    sutLogPathInputTime = sutDevicePathInputTime + "/" + "result_iperf_sut_{}.txt".format(test_time)
    sutFigureTitleInputTime = "Sut2Client_" + sut_devicename + "_iperf_result_image_{}s".format(test_time)
    sutFilenameToWriteInputTime = sutFigureTitleInputTime + '.png'
    sutFilenameToSaveInputTime = os.path.join(image_path_dir, sutFilenameToWriteInputTime)
    plot_image(sutLogPathInputTime, sutFigureTitleInputTime, sutFilenameToSaveInputTime)

# plot iperf result for input test time for client
for index_client_devicename, client_devicename in enumerate(client_devicename_list):
    clientDevicePathInputTime = log_path_dir_client + "/{}".format(time_start) + '/Client' + client_devicename
    clientLogPathInputTime = clientDevicePathInputTime + "/" + "result_iperf_client_{}.txt".format(test_time)
    clientFigureTitleInputTime = "Client2Sut_" + client_devicename + "_iperf_result_image_{}".format(test_time)
    clientFilenameToWriteInputTime = clientFigureTitleInputTime + '.png'
    clientFilenameToSaveInputTime = os.path.join(image_path_dir, clientFilenameToWriteInputTime)
    plot_image(clientLogPathInputTime, clientFigureTitleInputTime, clientFilenameToSaveInputTime)

# plot for 1800 seconds for sut
for index_sut_devicename, sut_devicename in enumerate(sut_devicename_list):
    sutDevicePath1800 = log_path_dir_sut + '/Sut' + sut_devicename
    sutLogPath1800 = sutDevicePath1800 + "/" + "result_iperf_sut_1800.txt"
    sutFigureTitle1800 = "Sut2Client_" + sut_devicename + "_iperf_result_image_1800s"
    sutFilenameToWrite1800 = sutFigureTitle1800 + '.png'
    sutFilenameToSave1800 = os.path.join(image_path_dir, sutFilenameToWrite1800)
    plot_image(sutLogPath1800, sutFigureTitle1800, sutFilenameToSave1800)

# plot for 1800 seconds for client
for index_client_devicename, client_devicename in enumerate(client_devicename_list):
    clientDevicePath1800 = log_path_dir_client + "/{}".format(time_start) + '/Client' + client_devicename
    clientLogPath1800 = clientDevicePath1800 + "/" + "result_iperf_client_1800.txt"
    clientFigureTitle1800 = "Client2Sut_" + client_devicename + "_iperf_result_image_1800s"
    clientFilenameToWrite1800 = clientFigureTitle1800 + '.png'
    clientFilenameToSave1800 = os.path.join(image_path_dir, clientFilenameToWrite1800)
    plot_image(clientLogPath1800, clientFigureTitle1800, clientFilenameToSave1800)

time_end = time.strftime('%Y%m%d%H%M%S', time.localtime(time.time()))
print("End net stress test!Start time {}".format(time_end))
result.write("End net stress test!Start time {}".format(time_end) + os.linesep)
result.close()
sys.exit(0)
