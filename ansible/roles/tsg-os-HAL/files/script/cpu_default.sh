#!/bin/sh

write_devices_conf()
{
(cat <<EOF1
[device]
rxcore_enable=0

EOF1
) >> ${tsg_clixon_cfg_file}
}

del_device_rxcore_conf()
{
    sed -i '/^\[device.*\]/,/^$/d' ${tsg_clixon_cfg_file}
}

allocate_cpu()
{
    local numa_node_cpu_cnt=0
    local numa_cpu_cnt_min=0
    local numa_list
    local mrzcpd_cnt
    local clixon_min_index

    if [ ! -n "$NUMA_NODE_CNT" ]; then
        NUMA_NODE_CNT=`lscpu | grep "NUMA node(s):" | head -n 1 | sed  -r 's/NUMA node\(s\):\s{1,}//g'`
    fi

    if [ ! -n "$IOCORE" ] || [ ! -n "$WORKLOAD_CORE" ]; then
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
            mrzcpd_cnt=1
            clixon_min_index=2
        elif [ $numa_cpu_cnt_min -le 16 ]; then
            mrzcpd_cnt=2
            clixon_min_index=3
        else
            mrzcpd_cnt=4
            clixon_min_index=5
        fi

        for((i=0;i<$NUMA_NODE_CNT;i++));
        do
            numa_list=$(numactl --hardware | grep "node $i cpus: " | sed -r "s/node $i cpus: //g" | sed -r "s/^0 //g")
            mrzcpd_core=$(echo $numa_list | cut -d ' ' -f 1-$mrzcpd_cnt | tr ' ' ',')
            IOCORE=$IOCORE","$mrzcpd_core
            clixon_core=$(echo $numa_list | cut -d ' ' -f $clixon_min_index- | tr ' ' ',')
            WORKLOAD_CORE=$WORKLOAD_CORE","$clixon_core
        done
        IOCORE=${IOCORE#*,}
        WORKLOAD_CORE=${WORKLOAD_CORE#*,}
    fi
    del_device_rxcore_conf
    write_devices_conf
}
