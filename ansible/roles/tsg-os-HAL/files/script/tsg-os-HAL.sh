#!/bin/sh

set -x

tsg_os_HAL_cfg_file="/etc/sysconfig/tsg-os-HAL.conf"

grub_cfg_file="/boot/grub/grub.cfg"
mrzcpd_cfg_file="/etc/sysconfig/mrzcpd"
tsg_clixon_cfg_file="/opt/tsg/clixon/etc/mgnt-srv.conf"
k3s_cfg_file="/etc/rancher/k3s/config.yaml"
mrglobal_cfg_template="/opt/tsg/clixon/etc/mrglobal.conf.jinja"

cpu_core_num=$(lscpu | grep "CPU(s):" | head -n 1 | sed  -r 's/CPU\(s\):\s{1,}//g')
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
        kube_reserved="2Gi"
        system_reserved="12Gi"
    elif [ $mem_num -le "65536" ]; then
        kube_reserved="2Gi"
        system_reserved="16Gi"
    elif [ $mem_num -le "131072" ]; then
        kube_reserved="2Gi"
        system_reserved="24Gi"
    else
        kube_reserved="2Gi"
        system_reserved="40Gi"
    fi

cat <<EOF > ${k3s_cfg_file}
kubelet-arg:
  - "kube-reserved=memory=${kube_reserved}"
  - "system-reserved=memory=${system_reserved}"
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

    # sysctl -w vm.nr_hugepages=${HUGEPAGES}
    return 0
}

set_hugepages()
{
    if [ ! -n "$HUGEPAGES" ]; then
        if [ $mem_num -le "32768" ]; then
            HUGEPAGES=4
        elif [ $mem_num -le "65536" ]; then
            HUGEPAGES=8
        elif [ $mem_num -le "131072" ]; then
            HUGEPAGES=16
        else
            HUGEPAGES=32
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
        elif [ $mem_num -le "131072" ]; then
            MRZCPD_DIRECT_PKTMBUF=`expr 2097152 / $NUMA_NODE_CNT`
        else
            MRZCPD_DIRECT_PKTMBUF=`expr 4194304 / $NUMA_NODE_CNT`
        fi
    fi
}

set_cpu_list()
{
    local vendor
    if [ -n "$MRZCPD_IOCORE" ] && [ -n "$CLIXON_IOCORE" ] && [ -n "$NUMA_NODE_CNT" ]; then
        return 0
    fi

    vendor=$(lscpu | grep "^Vendor ID" | awk '{print $3}')
    if [ $vendor == 'AuthenticAMD' ]; then
        . /opt/tsg/tsg-os-HAL/scripts/cpu_amd.sh
    else
        . /opt/tsg/tsg-os-HAL/scripts/cpu_default.sh
    fi

    allocate_cpu
}

set_bridge()
{
    ip link add br_dign_c type bridge
    ip link add br_dign_s type bridge
    ip link set br_dign_c up
    ip link set br_dign_s up
}

set_grub_cmdline_file()
{
    local result=0
    local grub_cmdline_key="$1"
    local grub_cmdline_value="$2"

    if ! grep -q " ${grub_cmdline_key}=" "$grub_cfg_file"; then
        sed -i "/ linux / s/$/ ${grub_cmdline_key}=${grub_cmdline_value}/" $grub_cfg_file
        result=1
    elif ! grep -q " ${grub_cmdline_key}=${grub_cmdline_value}" "$grub_cfg_file"; then
        sed -i "s/ ${grub_cmdline_key}=\w\+/ ${grub_cmdline_key}=${grub_cmdline_value}/g" $grub_cfg_file
        result=1
    fi
    return $result
}

set_grub_cmdline()
{
    local set_grub_flag=0

    grub_cmdline_key=("hugepagesz" "hugepages")
    grub_cmdline_value=("1G" ${HUGEPAGES})

    for index in "${!grub_cmdline_key[@]}"
    do
        set_grub_cmdline_file ${grub_cmdline_key[$index]} ${grub_cmdline_value[$index]}
        if [ "$?" == "1" ]; then
            set_grub_flag=1
        fi
    done

    if [ "$set_grub_flag" == "1" ]; then
        reboot
    fi
}

load_tsg_os_HAL_config
set_hugepages
set_grub_cmdline

/opt/tsg/mrzcpd/bin/mrmarch --auto

set_cpu_list
set_mrzcpd_indirect_pktmbuf
set_mrzcpd_direct_pktmbuf

set_k3s_config ${mem_num}
set_tsg_clixon_conf
set_os_hugepages
set_bridge
