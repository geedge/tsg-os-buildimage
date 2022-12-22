#!/bin/sh

set -xe

tsg_os_HAL_cfg_file="/etc/sysconfig/tsg-os-HAL"

grub_cfg_file="/boot/grub/grub.cfg"
mrzcpd_cfg_file="/etc/sysconfig/mrzcpd"
tsg_clixon_cfg_file="/opt/tsg/clixon/etc/mgnt-srv.conf"
k3s_cfg_file="/etc/rancher/k3s/config.yaml"
mrglobal_cfg_template="/opt/tsg/clixon/etc/mrglobal.conf.jinja"

cpu_core_num=$(lscpu | grep "CPU(s):" | head -n 1 | sed  -r 's/CPU\(s\):\s{1,}//g')
mem_num=$(free -m | grep Mem | awk '{print $2}')

HUGEPAGES=
MRZCPD_IOCORE=
MRZCPD_DIRECT_PKTMBUF=
TSG_CLIXON_CPU_QUOTAS_MIN=

load_tsg_os_HAL_config()
{
    [ -f ${tsg_os_HAL_cfg_file} ] || return 1
    
    source ${tsg_os_HAL_cfg_file}
    return 0
}

set_resouce_by_HAL()
{
    local mem_num="$1"
    local cpu_core_num="$2"

    if [ $mem_num -le "32768" ]; then
        HUGEPAGES=4
        MRZCPD_DIRECT_PKTMBUF=262144
    elif [ $mem_num -le "65536" ]; then
        HUGEPAGES=8
        MRZCPD_DIRECT_PKTMBUF=1048576
    else
        HUGEPAGES=16
        MRZCPD_DIRECT_PKTMBUF=2097152
    fi

    if [ ${cpu_core_num} -le "4" ]; then
        MRZCPD_IOCORE="1"
        TSG_CLIXON_CPU_QUOTAS_MIN=2
    elif [ ${cpu_core_num} -le "16" ]; then
        MRZCPD_IOCORE="1,2"
        TSG_CLIXON_CPU_QUOTAS_MIN=4
    else
        MRZCPD_IOCORE="1,2,3,4"
        TSG_CLIXON_CPU_QUOTAS_MIN=9
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

    [ -f ${mrglobal_cfg_template} ] && sed -i "s/^iocore=.*$/iocore=${MRZCPD_IOCORE}/g" ${mrglobal_cfg_template}

    [ -f ${tsg_clixon_cfg_file} ] && sed -i "s/^cpu_range=.*$/cpu_range=${TSG_CLIXON_CPU_QUOTAS_MIN}/g" ${tsg_clixon_cfg_file}
}

set_os_hugepages()
{
    [ -f ${mrzcpd_cfg_file} ] && sed -i "s/HUGEPAGE_NUM_1G=\w*/HUGEPAGE_NUM_1G=${HUGEPAGES}/g" ${mrzcpd_cfg_file}

    sysctl -w vm.nr_hugepages=${HUGEPAGES}
    return 0
}

load_tsg_os_HAL_config || set_resouce_by_HAL ${mem_num} ${cpu_core_num}

set_k3s_config ${mem_num}
set_tsg_clixon_conf
set_os_hugepages
