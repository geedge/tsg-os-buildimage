#!/bin/sh

set -x

allocate_cpu()
{
    local numa_node_min=0
    local numa_node_max=0
    local numa_node_cpu_cnt=0
    local numa_cpu_cnt_min=0
    local numa_list
    local numa_nodes
    local mrzcpd_cnt
    local clixon_min_index

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
        mrzcpd_cnt=1
        clixon_min_index=2
    elif [ $numa_cpu_cnt_min -le 16 ]; then
        mrzcpd_cnt=2
        clixon_min_index=3
    else
        mrzcpd_cnt=4
        clixon_min_index=5
    fi


    for((i=$numa_node_min;i<=$numa_node_max;i++));
    do
        numa_list=$(numactl --hardware | grep "node $i cpus: " | sed -r "s/node $i cpus: //g" | sed -r "s/^0 //g")
        mrzcpd_core=$(echo $numa_list | cut -d ' ' -f 1-$mrzcpd_cnt | tr ' ' ',')
        MRZCPD_IOCORE=$MRZCPD_IOCORE","$mrzcpd_core
        clixon_core=$(echo $numa_list | cut -d ' ' -f $clixon_min_index- | tr ' ' ',')
        CLIXON_IOCORE=$CLIXON_IOCORE","$clixon_core
    done
    MRZCPD_IOCORE=${MRZCPD_IOCORE#*,}
    CLIXON_IOCORE=${CLIXON_IOCORE#*,}
}
