#!/bin/sh

set -x

write_devices_conf()
{
(cat <<EOF1
[device]
rxcore_enable=1
device=$1

EOF1
) >> $2
}

write_device_rxcore_conf()
{
(cat <<EOF1
[device:$1]
rx_cores=$2

EOF1
) >> $3
}

del_device_rxcore_conf()
{
    sed -i '/^\[device.*\]/,/^$/d' ${tsg_clixon_cfg_file}
}

set_mrzcpd_rx_core()
{
    local devices
    local str_device

    del_device_rxcore_conf

    devices=$(lshw -c network -businfo | grep network | awk '{print $2}')
    for device in $devices
    do
        businfo=$(ethtool -i $device | grep "bus-info:"| awk '{print $2}')
        numa_node=$(lspci -s $businfo -vv | grep "NUMA node:" | awk '{print $3}')
        write_device_rxcore_conf $device ${mrzcpd_rx_core[$numa_node]} ${tsg_clixon_cfg_file}
        str_device=$str_device","$device
    done
    str_device=${str_device#*,}
    write_devices_conf $str_device ${tsg_clixon_cfg_file}
}

allocate_cpu()
{
    local numa_node_min=0
    local numa_node_max=0
    local numa_node_cpu_cnt=0
    local numa_cpu_cnt_min=0
    local numa_list
    local numa_nodes
    local mrzcpd_start
    local mrzcpd_end
    local clixon_start

    numa_nodes=$(numactl --hardware | grep available | awk -F"[()]" '{print $2}')

    if [[ $numa_nodes == *-* ]]
    then
        read numa_node_min numa_node_max <<< $(echo $numa_nodes | awk -F- '{print $1" "$2}')
    else
        numa_node_min=$numa_nodes
        numa_node_max=$numa_nodes
    fi
    NUMA_NODE_CNT=`expr $numa_node_max - $numa_node_min + 1`
    for((i=$numa_node_min;i<=$numa_node_max;i++));
    do
        numa_node_cpu_cnt=$(numactl --hardware | awk '/^node ['$i']+ cpus:/ {print NF-3}')
        if [ $numa_cpu_cnt_min -eq 0 ] || [ $numa_node_cpu_cnt -lt $numa_cpu_cnt_min ]; then
            numa_cpu_cnt_min=$numa_node_cpu_cnt
        fi
    done

    if [ $numa_cpu_cnt_min -le 4 ]; then
        mrzcpd_start=2
        mrzcpd_end=2
        clixon_start=3
    elif [ $numa_cpu_cnt_min -le 16 ]; then
        mrzcpd_start=3
        mrzcpd_end=4
        clixon_start=5
    elif [ $numa_cpu_cnt_min -le 32 ]; then
        mrzcpd_start=5
        mrzcpd_end=8
        clixon_start=9
    else
        mrzcpd_start=5
        mrzcpd_end=12
        clixon_start=13
    fi

    for((i=$numa_node_min;i<=$numa_node_max;i++));
    do
        numa_list=$(numactl --hardware | grep "node $i cpus: " | sed -r "s/node $i cpus: //g")
        mrzcpd_core=$(echo $numa_list | cut -d ' ' -f $mrzcpd_start-$mrzcpd_end | tr ' ' ',')
        MRZCPD_IOCORE=$MRZCPD_IOCORE","$mrzcpd_core
        mrzcpd_rx_core+=($mrzcpd_core)
        clixon_core=$(echo $numa_list | cut -d ' ' -f $clixon_start- | tr ' ' ',')
        CLIXON_IOCORE=$CLIXON_IOCORE","$clixon_core
    done
    MRZCPD_IOCORE=${MRZCPD_IOCORE#*,}
    CLIXON_IOCORE=${CLIXON_IOCORE#*,}

    set_mrzcpd_rx_core
}
