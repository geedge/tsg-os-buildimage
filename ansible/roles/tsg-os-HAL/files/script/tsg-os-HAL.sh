#!/bin/sh

set -x

tsg_os_HAL_cfg_file="/etc/sysconfig/tsg-os-HAL.conf"

grub_cfg_file="/boot/grub/grub.cfg"
mrzcpd_cfg_file="/etc/sysconfig/mrzcpd"
tsg_clixon_cfg_file="/opt/tsg/clixon/etc/mgnt-srv.conf"
k3s_cfg_file="/etc/rancher/k3s/config.yaml"
mrglobal_cfg_template="/opt/tsg/clixon/etc/mrglobal.conf.jinja"

cpu_core_num=$(lscpu | grep "CPU(s):" | head -n 1 | sed  -r 's/CPU\(s\):\s{1,}//g')
numa_nodes=$(numactl --hardware | grep available | awk -F"[()]" '{print $2}')
mem_num=$(free -m | grep Mem | awk '{print $2}')

HUGEPAGES=
NUMA_NODE_CNT=
MRZCPD_IOCORE=
CLIXON_IOCORE=
MRZCPD_DIRECT_PKTMBUF=
MRZCPD_INDIRECT_PKTMBUF=

load_tsg_os_HAL_config()
{
    if [ -f "${tsg_os_HAL_cfg_file}" ]; then
        source ${tsg_os_HAL_cfg_file}
    fi
}

set_k3s_config()
{
    local mem_num="$1"

    if [ $mem_num -le "32768" ]; then
        kube_reserved="512Mi"
        system_reserved="512Mi"
        eviction_hard="64Mi"
    elif [ $mem_num -le "65536" ]; then
        kube_reserved="1Gi"
        system_reserved="1Gi"
        eviction_hard="1Gi"
    else
        kube_reserved="2Gi"
        system_reserved="2Gi"
        eviction_hard="2Gi"
    fi

cat <<EOF > ${k3s_cfg_file}
kubelet-arg:
  - "kube-reserved=memory=${kube_reserved}"
  - "system-reserved=memory=${system_reserved}"
  - "eviction-hard=memory.available<${eviction_hard}"
EOF
}

set_tsg_clixon_conf()
{
    [ -f ${mrglobal_cfg_template} ] && sed -i "s/^sz_direct_pktmbuf=.*$/sz_direct_pktmbuf=${MRZCPD_DIRECT_PKTMBUF}/g" ${mrglobal_cfg_template}
    [ -f ${mrglobal_cfg_template} ] && sed -i "s/^sz_indirect_pktmbuf=.*$/sz_indirect_pktmbuf=${MRZCPD_INDIRECT_PKTMBUF}/g" ${mrglobal_cfg_template}

    [ -f ${mrglobal_cfg_template} ] && sed -i "s/^iocore=.*$/iocore=${MRZCPD_IOCORE}/g" ${mrglobal_cfg_template}

    [ -f ${tsg_clixon_cfg_file} ] && sed -i "s/^cpu_range=.*$/cpu_range=${CLIXON_IOCORE}/g" ${tsg_clixon_cfg_file}
}

set_os_hugepages()
{
    [ -f ${mrzcpd_cfg_file} ] && sed -i "s/HUGEPAGE_NUM_1G=\w*/HUGEPAGE_NUM_1G=${HUGEPAGES}/g" ${mrzcpd_cfg_file}

    sysctl -w vm.nr_hugepages=${HUGEPAGES}
    return 0
}

set_hugepages()
{
    if [ ! -n "$HUGEPAGES" ]; then
        if [ $mem_num -le "32768" ]; then
            HUGEPAGES=4
        elif [ $mem_num -le "65536" ]; then
            HUGEPAGES=8
        else
            HUGEPAGES=16
        fi
    fi
}

set_mrzcpd_indirect_pktmbuf()
{
    if [ ! -n "$MRZCPD_INDIRECT_PKTMBUF" ]; then
        MRZCPD_INDIRECT_PKTMBUF=`expr 8192 / $NUMA_NODE_CNT`
    fi
}

set_mrzcpd_direct_pktmbuf()
{
    if [ ! -n "$MRZCPD_DIRECT_PKTMBUF" ]; then
        if [ $mem_num -le "32768" ]; then
            MRZCPD_DIRECT_PKTMBUF=`expr 262144 / $NUMA_NODE_CNT`
        elif [ $mem_num -le "65536" ]; then
            MRZCPD_DIRECT_PKTMBUF=`expr 1048576 / $NUMA_NODE_CNT`
        else
            MRZCPD_DIRECT_PKTMBUF=`expr 2097152 / $NUMA_NODE_CNT`
        fi
    fi
}

allocate_cpu()
{
    local numa_node_min=0
    local numa_node_max=0
    local numa_node_cpu_cnt=0
    local numa_cpu_cnt_min=0
    local numa_list

    if [ -n "$MRZCPD_IOCORE" ] && [ -n "$CLIXON_IOCORE" ] && [ -n "$NUMA_NODE_CNT" ]; then
        return 0
    fi

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

set_bridge()
{
    ip link add br_dign_c type bridge
    ip link add br_dign_s type bridge
    ip link set br_dign_c up
    ip link set br_dign_s up
}

load_tsg_os_HAL_config

allocate_cpu
set_hugepages
set_mrzcpd_indirect_pktmbuf
set_mrzcpd_direct_pktmbuf

set_k3s_config ${mem_num}
set_tsg_clixon_conf
set_os_hugepages
set_bridge
