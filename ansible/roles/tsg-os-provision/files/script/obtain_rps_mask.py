#!/usr/bin/env python3
import psutil
import platform
import subprocess
import yaml
import math
import json

CPU_LAYOUTS_CONF_PATH = "/opt/tsg/tsg-os-provision/.cpu_layouts.json"

def get_cpu_machine():
    model_info = (subprocess.check_output("lscpu | grep \"Model name:\" | head -n 1 | sed  -r \'s/Model name:\s{1,}//g\'", shell=True).strip()).decode()
    socket_info = int((subprocess.check_output("lscpu | grep \"Socket(s):\" | head -n 1 | sed  -r \'s/Socket\(s\):\s{1,}//g\'", shell=True).strip()).decode())
    #return (psutil.cpu_count(), retstr)
    return (model_info, socket_info)

def get_cpu_layouts():
    with open(CPU_LAYOUTS_CONF_PATH, 'r',encoding='utf-8') as f:
        temp=json.load(f)
        f.close()
    return temp

def get_cpu_affinity():
    matched = 0
    tfe_cpu_affinity = []
    mrzcpd_cpu_affinity = []
    cpu_machine = get_cpu_machine()
    cpu_layouts = get_cpu_layouts()
    for layout in cpu_layouts:
        if (layout['match']['sockets'] == cpu_machine[1]) and (cpu_machine[0].find(layout['match']['model_name']) != -1):
            matched = 1
            tfe_cpu_affinity = layout['tfe_affinity']
            mrzcpd_cpu_affinity = layout['mrzcpd_affinity']
            break
    if matched == 0:
        print("Warning: not match cpu model name and sockets,please checkout cpuinfo and cpu_layouts config ...")
        exit(1)
    return (mrzcpd_cpu_affinity, tfe_cpu_affinity)

def calc_rps_mask():
    rps_list_size = math.ceil(psutil.cpu_count()/32)
    rps_list = [0] * rps_list_size
    cpu_affinity = get_cpu_affinity()
    for core in cpu_affinity[1]:
        rps_list_index = core // 32
        rps_core_location = core % 32
        rps_list[rps_list_index] = rps_list[rps_list_index] | (2 ** rps_core_location)

    result_queue_rps = ""
    is_top = False
    for rps in reversed(rps_list):
        if is_top == False:
            result_queue_rps = ('%x' % rps)
            is_top = True
        else:
            result_queue_rps = result_queue_rps + ',' + ('%08x' % rps)
    result_output = {"rps_size": len(cpu_affinity[0]), "rps_mask": result_queue_rps}
    print(json.dumps(result_output))  

if __name__ == '__main__':
    calc_rps_mask()
