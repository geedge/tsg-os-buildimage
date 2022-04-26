#!/usr/bin/env python3
import json
import subprocess

CPU_LAYOUTS_CONF_PATH = "/opt/tsg/tsg-os-provision/.cpu_layouts.json"
PROXY_CONF_PATH = "/opt/tsg/tsg-os-provision/.proxy.json"

def get_cpu_machine():
    model_info = (subprocess.check_output("lscpu | grep \"Model name:\" | head -n 1 | sed  -r \'s/Model name:\s{1,}//g\'", shell=True).strip()).decode()
    socket_info = int((subprocess.check_output("lscpu | grep \"Socket(s):\" | head -n 1 | sed  -r \'s/Socket\(s\):\s{1,}//g\'", shell=True).strip()).decode())
    return (model_info, socket_info)

def get_cpu_layouts():
    with open(CPU_LAYOUTS_CONF_PATH, 'r',encoding='utf-8') as f:
        temp=json.load(f)
        f.close()
    return temp

def get_proxy_config():
    with open(PROXY_CONF_PATH, 'r',encoding='utf-8') as f:
        temp=json.load(f)
        f.close()
    return temp

def get_cpu_affinity():
    matched = 0
    mrzcpd_cpu_affinity = []
    sapp_cpu_affinity = []
    tfe_cpu_affinity = []
    cpu_machine = get_cpu_machine()
    cpu_layouts = get_cpu_layouts()
    for layout in cpu_layouts:
        if (layout['match']['sockets'] == cpu_machine[1]) and (cpu_machine[0].find(layout['match']['model_name']) != -1):
            matched = 1
            sapp_cpu_affinity = layout['sapp_affinity']
            mrzcpd_cpu_affinity = layout['mrzcpd_affinity']
            tfe_cpu_affinity = layout['tfe_affinity']
            break
    if matched == 0:
        print("Warning: not match cpu model name and sockets,please checkout cpuinfo and cpu_layouts config ...")
        exit(1)
    return (mrzcpd_cpu_affinity, sapp_cpu_affinity, tfe_cpu_affinity)

def append_range_list(start,end,rangelist):
    if start == end:
        rangelist.append(('%d' % start))
    else:
        rangelist.append(('%d-%d' % (start,end)))

def get_range_isolate_cpu():
    proxy_config = get_proxy_config()
    isolate_range_cpu_list = []
    range_start = range_end = -1
    cpu_affinity = get_cpu_affinity()
    isolate_cpu_list = cpu_affinity[0] + cpu_affinity[1]
    if proxy_config['enable'] == 0:
        isolate_cpu_list = isolate_cpu_list + cpu_affinity[2]
    isolate_cpu_list.sort()
                        
    for i,val in enumerate(isolate_cpu_list):
        if i == 0:
            range_start = val
            range_end = val
            continue
        if val - range_end == 1:
            range_end = val
            continue
        else:
            append_range_list(range_start,range_end,isolate_range_cpu_list)
            range_start = val
            range_end = val

    append_range_list(range_start,range_end, isolate_range_cpu_list)
    print(",".join(isolate_range_cpu_list))
    
if __name__ == '__main__':
    get_range_isolate_cpu()
