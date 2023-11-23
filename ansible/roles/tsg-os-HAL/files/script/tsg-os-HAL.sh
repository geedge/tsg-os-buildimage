#!/bin/sh

set -x

tsg_os_HAL_cfg_file="/etc/sysconfig/tsg-os-HAL.conf"

grub_cfg_file="/boot/grub/grub.cfg"
mrzcpd_cfg_file="/etc/sysconfig/mrzcpd"
tsg_clixon_cfg_file="/opt/tsg/clixon/etc/mgnt-srv.conf"
k3s_cfg_file="/etc/rancher/k3s/config.yaml"
mrglobal_cfg_template="/opt/tsg/clixon/etc/mrglobal.conf.jinja"
cpu_partitioning_conf_file='/etc/tuned/cpu-partitioning-variables.conf'

cpu_core_num=$(lscpu | grep "CPU(s):" | head -n 1 | sed  -r 's/CPU\(s\):\s{1,}//g')
mem_num=$(free -m | grep Mem | awk '{print $2}')

HUGEPAGES=
KUBE_RESERVED=
SYSTEM_RESERVED=
NUMA_NODE_CNT=
IOCORE=
WORKLOAD_CORE=
MRZCPD_DIRECT_PKTMBUF=
MRZCPD_INDIRECT_PKTMBUF=
MRZCPD_POLL_WAIT_THROTTLE=512
MRZCPD_SZ_DATA=4096
MRZCPD_SZ_TUNNEL=8192
MRZCPD_CHECK_BUFFER_LEAK=1
NF_COUNT=16
NIC_CPU_Affinity_Switch=

cpu_format_conversion()
{
    local core_min
    local core_max
    local core_list

    if [[ $1 == *-* ]]; then
        read core_min core_max <<< $(echo $1 | awk -F- '{print $1" "$2}')
        for((i=$core_min;i<=$core_max;i++));
        do
            core_list=$core_list","$i
        done
        core_list=${core_list#*,}
    else
        core_list=$1
    fi
    echo $core_list
}

load_tsg_os_HAL_config()
{
    if [ -f "${tsg_os_HAL_cfg_file}" ]; then
        source ${tsg_os_HAL_cfg_file}

        if [ ! -n "$IOCORE" ] && [ -n "$MRZCPD_IOCORE" ]; then
            IOCORE=$MRZCPD_IOCORE
        fi

        if [ ! -n "$WORKLOAD_CORE" ] && [ -n "$CLIXON_IOCORE" ]; then
            WORKLOAD_CORE=$CLIXON_IOCORE
        fi

        if [ -n $IOCORE ]; then
            core_list=$(echo $IOCORE | tr ',' ' ')
            for core in $core_list;
            do
                core_format=$core_format","$(cpu_format_conversion $core)
            done
            core_format=${core_format#*,}
            IOCORE=$core_format
        fi
    fi
}

set_k3s_config()
{
    local mem_num="$1"
    local system_mem

    if [ ! -n "$KUBE_RESERVED" ]; then
        KUBE_RESERVED=2
    fi

    if [ ! -n "$SYSTEM_RESERVED" ]; then
        if [ $mem_num -le "32768" ]; then
            SYSTEM_RESERVED=8
        elif [ $mem_num -le "65536" ]; then
            SYSTEM_RESERVED=8
        elif [ $mem_num -le "131072" ]; then
            SYSTEM_RESERVED=16
        else
            SYSTEM_RESERVED=32
        fi
    fi

    system_mem=$(($HUGEPAGES + $SYSTEM_RESERVED))
cat <<EOF > ${k3s_cfg_file}
kubelet-arg:
  - "kube-reserved=memory=${KUBE_RESERVED}Gi"
  - "system-reserved=memory=${system_mem}Gi"
EOF
}

set_tsg_clixon_conf()
{
    [ -f ${mrglobal_cfg_template} ] && sed -i "s/^sz_direct_pktmbuf=.*$/sz_direct_pktmbuf=${MRZCPD_DIRECT_PKTMBUF}/g" ${mrglobal_cfg_template}
    [ -f ${mrglobal_cfg_template} ] && sed -i "s/^sz_indirect_pktmbuf=.*$/sz_indirect_pktmbuf=${MRZCPD_INDIRECT_PKTMBUF}/g" ${mrglobal_cfg_template}

    [ -f ${mrglobal_cfg_template} ] && sed -i "s/^iocore=.*$/iocore=${IOCORE}/g" ${mrglobal_cfg_template}

    [ -f ${mrglobal_cfg_template} ] && sed -i "s/^poll_wait_throttle=.*$/poll_wait_throttle=${MRZCPD_POLL_WAIT_THROTTLE}/g" ${mrglobal_cfg_template}
    [ -f ${mrglobal_cfg_template} ] && sed -i "s/^sz_data=.*$/sz_data=${MRZCPD_SZ_DATA}/g" ${mrglobal_cfg_template}
    [ -f ${mrglobal_cfg_template} ] && sed -i "s/^sz_tunnel=.*$/sz_tunnel=${MRZCPD_SZ_TUNNEL}/g" ${mrglobal_cfg_template}
    [ -f ${mrglobal_cfg_template} ] && sed -i "s/^check_buffer_leak=.*$/check_buffer_leak=${MRZCPD_CHECK_BUFFER_LEAK}/g" ${mrglobal_cfg_template}

    [ -f ${tsg_clixon_cfg_file} ] && sed -i "s/^cpu_range=.*$/cpu_range=${WORKLOAD_CORE}/g" ${tsg_clixon_cfg_file}
    [ -f ${tsg_clixon_cfg_file} ] && sed -i "s/^nf_count=.*$/nf_count=${NF_COUNT}/g" ${tsg_clixon_cfg_file}
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

    vendor=$(lscpu | grep "^Vendor ID" | awk '{print $3}')
    if [ -n "$NIC_CPU_Affinity_Switch" ] && [ "$NIC_CPU_Affinity_Switch" == "1" ]; then
        . /opt/tsg/tsg-os-HAL/scripts/cpu_amd.sh
    elif [ -n "$NIC_CPU_Affinity_Switch" ] && [ "$NIC_CPU_Affinity_Switch" == "0" ]; then
        . /opt/tsg/tsg-os-HAL/scripts/cpu_default.sh
    elif [ $vendor == 'AuthenticAMD' ]; then
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
        sed -i "/ linux / s/$/ ${grub_cmdline_key}=${grub_cmdline_value} /" $grub_cfg_file
        result=1
    elif ! grep -qE " ${grub_cmdline_key}=${grub_cmdline_value}\s| ${grub_cmdline_key}=${grub_cmdline_value}$" "$grub_cfg_file"; then
        sed -i "s/ ${grub_cmdline_key}=\(\w\+,\)*\(\w\+-\w\+,*\)*\w*,*\s*/ ${grub_cmdline_key}=${grub_cmdline_value} /" $grub_cfg_file
        result=1
    fi
    return $result
}

set_grub_cmdline()
{
    local set_grub_flag=0

    grub_cmdline_key=("hugepagesz" "hugepages" "isolcpus")
    grub_cmdline_value=("1G" ${HUGEPAGES} ${IOCORE})

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

set_cpu_partitioning()
{
cat <<EOF > ${cpu_partitioning_conf_file}
isolated_cores=${IOCORE}
EOF
}

load_tsg_os_HAL_config
set_hugepages
set_cpu_list
set_grub_cmdline

/opt/tsg/mrzcpd/bin/mrmarch --auto
set_cpu_partitioning

set_mrzcpd_indirect_pktmbuf
set_mrzcpd_direct_pktmbuf

set_k3s_config ${mem_num}
set_tsg_clixon_conf
set_os_hugepages
set_bridge
