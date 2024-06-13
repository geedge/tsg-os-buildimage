#!/bin/sh

nic_cpu_affinity_disable()
{
(cat <<EOF1
[device]
rxcore_enable=0

EOF1
) >> ${tsg_clixon_cfg_file}
}

nic_cpu_affinity_enable()
{
(cat <<EOF1
[device]
rxcore_enable=1
device=$1

EOF1
) >> ${tsg_clixon_cfg_file}
}

set_nic_cpu_affinity()
{
(cat <<EOF1
[device:$1]
rx_cores=$2

EOF1
) >> ${tsg_clixon_cfg_file}
}

delete_nic_cpu_affinity_config()
{
    sed -i '/^\[device.*\]/,/^$/d' ${tsg_clixon_cfg_file}
}

output_common_cpu()
{
    local common_list

    list1=$(echo $1 | tr ',' ' ')
    list2=$(echo $2 | tr ',' ' ')

    for numa_core in $list1;
    do
        for iocore in $list2;
        do
            if [ $numa_core -eq $iocore ]; then
                common_list=$common_list","$numa_core
                break
            fi
        done
    done
    common_list=${common_list#*,}
    echo $common_list
}

build_nic_cpu_affinity_configuration()
{
    local cpus
    local cpu_list
    local numa_cpus
    local devices
    local device_list
    local NIC_CPU_Affinity_Switch=$1

    delete_nic_cpu_affinity_config
    if [ -z "$NIC_CPU_Affinity_Switch" ] || [ "$NIC_CPU_Affinity_Switch" == "0" ]; then
        nic_cpu_affinity_disable
        return
    fi

    for((i=0;i<$NUMA_NODE_CNT;i++));
    do
        numa_cpus=$(numactl --hardware | grep "node $i cpus: " | sed -r "s/node $i cpus: //g" | tr ' ' ',')
        cpus=$(output_common_cpu $numa_cpus $IOCORE)
        cpu_list+=("$cpus")
    done
    
    devices=$(lshw -c network -businfo | grep network | awk '{print $2}')
    for device in $devices
    do
        if [ $device == "network" ]; then
            continue
        fi
        businfo=$(ethtool -i $device | grep "bus-info:"| awk '{print $2}')
        numa_node=$(lspci -s $businfo -vv | grep "NUMA node:" | awk '{print $3}')

        if [ -z "$numa_node" ] || [ $numa_node -ge $NUMA_NODE_CNT ] || [ -z ${cpu_list[$numa_node]} ]; then
            continue
        fi
        set_nic_cpu_affinity $device ${cpu_list[$numa_node]} ${tsg_clixon_cfg_file}
        device_list=$device_list","$device
    done

    device_list=${device_list#*,}
    nic_cpu_affinity_enable $device_list
}

