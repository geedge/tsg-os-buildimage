#!/bin/sh

allocate_cpu()
{
    local cpus
    local numa_cpus
    local clixon_cpus
    local mrzcpd_end
    local clixon_start
    local numa_cpu_cnt_min=0
    local numa_node_cpu_cnt=0

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
            mrzcpd_end=1
            clixon_start=2
        elif [ $numa_cpu_cnt_min -le 16 ]; then
            mrzcpd_end=2
            clixon_start=3
        else
            mrzcpd_end=4
            clixon_start=5
        fi

        for((i=0;i<$NUMA_NODE_CNT;i++));
        do
            numa_cpus=$(numactl --hardware | grep "node $i cpus: " | sed -r "s/node $i cpus: //g" | sed -r "s/^0 //g")
            cpus=$(echo $numa_cpus | cut -d ' ' -f 1-$mrzcpd_end | tr ' ' ',')
            IOCORE=$IOCORE","$cpus
            clixon_cpus=$(echo $numa_cpus | cut -d ' ' -f $clixon_start- | tr ' ' ',')
            WORKLOAD_CORE=$WORKLOAD_CORE","$clixon_cpus
        done
        IOCORE=${IOCORE#*,}
        WORKLOAD_CORE=${WORKLOAD_CORE#*,}
    fi
}
