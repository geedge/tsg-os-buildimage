#!/bin/sh

write_devices_disable()
{
(cat <<EOF1
[device]
rxcore_enable=0

EOF1
) >> $1
}

write_devices_enable()
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
        if [ $device == "network" ]; then
            continue
        fi
        businfo=$(ethtool -i $device | grep "bus-info:"| awk '{print $2}')
        numa_node=$(lspci -s $businfo -vv | grep "NUMA node:" | awk '{print $3}')

        if [ ! -n "$numa_node" ] || [ $numa_node -ge $NUMA_NODE_CNT ]; then
            continue
        fi
        write_device_rxcore_conf $device ${mrzcpd_rx_core[$numa_node]} ${tsg_clixon_cfg_file}
        str_device=$str_device","$device
    done
    str_device=${str_device#*,}

    if [ ! -n "$str_device" ]; then
        write_devices_disable ${tsg_clixon_cfg_file}
    else
        write_devices_enable $str_device ${tsg_clixon_cfg_file}
    fi
}

output_common_str()
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

allocate_cpu()
{
    local numa_node_cpu_cnt=0
    local numa_cpu_cnt_min=0
    local numa_list
    local mrzcpd_start
    local mrzcpd_end
    local clixon_start

    if [ ! -n "$NUMA_NODE_CNT" ]; then
        NUMA_NODE_CNT=`lscpu | grep "NUMA node(s):" | head -n 1 | sed  -r 's/NUMA node\(s\):\s{1,}//g'`
    fi

    if [ -n "$IOCORE" ] && [ -n "$WORKLOAD_CORE" ]; then
        for((i=0;i<$NUMA_NODE_CNT;i++));
        do
            numa_list=$(numactl --hardware | grep "node $i cpus: " | sed -r "s/node $i cpus: //g" | tr ' ' ',')
            mrzcpd_core=$(output_common_str $numa_list $IOCORE)
            mrzcpd_rx_core+=($mrzcpd_core)
        done
    else
        unset IOCORE
        unset WORKLOAD_CORE

        for((i=0;i<$NUMA_NODE_CNT;i++));
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

        for((i=0;i<$NUMA_NODE_CNT;i++));
        do
            numa_list=$(numactl --hardware | grep "node $i cpus: " | sed -r "s/node $i cpus: //g")
            mrzcpd_core=$(echo $numa_list | cut -d ' ' -f $mrzcpd_start-$mrzcpd_end | tr ' ' ',')
            IOCORE=$IOCORE","$mrzcpd_core
            mrzcpd_rx_core+=($mrzcpd_core)
            clixon_core=$(echo $numa_list | cut -d ' ' -f $clixon_start- | tr ' ' ',')
            WORKLOAD_CORE=$WORKLOAD_CORE","$clixon_core
        done
        IOCORE=${IOCORE#*,}
        WORKLOAD_CORE=${WORKLOAD_CORE#*,}
    fi

    set_mrzcpd_rx_core
}
