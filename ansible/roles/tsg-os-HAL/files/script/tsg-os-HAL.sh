#!/bin/sh

set -x

tsg_os_HAL_cfg_file="/etc/sysconfig/tsg-os-HAL.conf"

grub_cfg_file="/boot/grub/grub.cfg"
tsg_clixon_cfg_file="/opt/tsg/clixon/etc/mgnt-srv.conf"
k3s_cfg_file="/etc/rancher/k3s/config.yaml"
mrzcpd_conf_file="/var/run/share/container_mrzcpd.conf"
cpu_partitioning_conf_file='/etc/tuned/cpu-partitioning-variables.conf'

cpu_core_num=$(lscpu | grep "CPU(s):" | head -n 1 | sed  -r 's/CPU\(s\):\s{1,}//g')
mem_num=$(free -m | grep Mem | awk '{print $2}')

HUGEPAGES=
KUBE_RESERVED=
SYSTEM_RESERVED=
NUMA_NODE_CNT=
MRZCPD_IOCORE=
CLIXON_IOCORE=
MRZCPD_DIRECT_PKTMBUF=
MRZCPD_INDIRECT_PKTMBUF=
MRZCPD_POLL_WAIT_THROTTLE=512
MRZCPD_SZ_DATA=4096
MRZCPD_SZ_TUNNEL=8192
MRZCPD_CHECK_BUFFER_LEAK=1
TRAFFIC_ENGINE_LOGS_VDISK_PATH="/data/vdisks"
TRAFFIC_ENGINE_LOGS_VDISK_SIZE_BYTES=

load_tsg_os_HAL_config()
{
    if [ -f "${tsg_os_HAL_cfg_file}" ]; then
        source ${tsg_os_HAL_cfg_file}
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
    [ -f ${tsg_clixon_cfg_file} ] && sed -i "s/^cpu_range=.*$/cpu_range=${CLIXON_IOCORE}/g" ${tsg_clixon_cfg_file}
    [ -f ${tsg_clixon_cfg_file} ] && sed -i "s/^hugepages=.*$/hugepages=${HUGEPAGES}/g" ${tsg_clixon_cfg_file}
}

set_mrzcpd_conf()
{
    echo "sz_indirect_pktmbuf=${MRZCPD_INDIRECT_PKTMBUF}" > ${mrzcpd_conf_file}
    echo "sz_direct_pktmbuf=${MRZCPD_DIRECT_PKTMBUF}" >> ${mrzcpd_conf_file}
    echo "iocore=${MRZCPD_IOCORE}" >> ${mrzcpd_conf_file}
    echo "poll_wait_throttle=${MRZCPD_POLL_WAIT_THROTTLE}" >> ${mrzcpd_conf_file}
    echo "sz_data=${MRZCPD_SZ_DATA}" >> ${mrzcpd_conf_file}
    echo "sz_tunnel=${MRZCPD_SZ_TUNNEL}" >> ${mrzcpd_conf_file}
    echo "check_buffer_leak=${MRZCPD_CHECK_BUFFER_LEAK}" >> ${mrzcpd_conf_file}
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
    grub_cmdline_value=("1G" ${HUGEPAGES} ${MRZCPD_IOCORE})

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

build_and_mount_traffic_engine_logs_vdisk()
{
    local vdisk_path=${TRAFFIC_ENGINE_LOGS_VDISK_PATH}
    local vdisk_file="vdisk-traffic-engine-logs.ext4"
    local vdisk_size=${TRAFFIC_ENGINE_LOGS_VDISK_SIZE_BYTES}
    local mount_path="/var/log/traffic-engine"
    local present_vdisk_size=0
    local is_new_vdisk=0
    local loop_device=

    mkdir -p ${vdisk_path}
    mkdir -p ${mount_path}

    #Read /dev/sda5 size and get vdisk_size.
    if [ ! -n "${vdisk_size}" ]; then
        dev_sda5_size=`lsblk -b -o SIZE /dev/sda5 | sed -n 2p | tr -d ' '`
        vdisk_size=$((dev_sda5_size/2))
    fi

    #Read present vdisk size.
    if [ -e "${vdisk_path}/${vdisk_file}" ]; then
        present_vdisk_size=`stat -c "%s" ${vdisk_path}/${vdisk_file}`
    fi

    #Create volume file.
    if [ ! -e "${vdisk_path}/${vdisk_file}" ]; then
        dd of=${vdisk_path}/${vdisk_file} bs=${vdisk_size} seek=1 count=0
        mkfs -t ext4 ${vdisk_path}/${vdisk_file}
        is_new_vdisk=1
    elif [ ${vdisk_size} -gt ${present_vdisk_size} ]; then
        dd of=${vdisk_path}/${vdisk_file} bs=${vdisk_size} seek=1 count=0 oflag=append
    fi

    #mount volume on /var/log/traffic-engine or resize loop device
    #condition 1: ${mount_path} not mounted.                      action: mount
    #condition 2: ${mount_path} mounted and need mount new vdisk. action: umount and mount new disk.
    #condition 3: ${mount_path} mounted and vdisk size changed.   action: resize loop device.
    loop_device=`df | grep ${mount_path} | awk '{print $1}'`
    if [ -z ${loop_device} ]; then
        mount -o loop,rw ${vdisk_path}/${vdisk_file} ${mount_path}
    elif [ ${is_new_vdisk} -eq 1 ]; then
        umount ${mount_path}
        mount -o loop,rw ${vdisk_path}/${vdisk_file} ${mount_path}
    elif [ ${vdisk_size} -gt ${present_vdisk_size} ]; then
        losetup -c ${loop_device}
        resize2fs  ${loop_device}
    fi
}


set_cpu_partitioning()
{
cat <<EOF > ${cpu_partitioning_conf_file}
isolated_cores=${MRZCPD_IOCORE}
EOF
}

load_tsg_os_HAL_config
mkdir -p /run/mrzcpd/hugepages
mkdir -p /var/run/share

build_and_mount_traffic_engine_logs_vdisk
set_hugepages
set_cpu_list
set_grub_cmdline

set_cpu_partitioning

mount -t hugetlbfs -o pagesize=1073741824 nodev /var/run/mrzcpd/hugepages
modprobe vfio
echo 1 > /sys/module/vfio/parameters/enable_unsafe_noiommu_mode
modprobe vfio_pci

set_mrzcpd_indirect_pktmbuf
set_mrzcpd_direct_pktmbuf

set_k3s_config ${mem_num}
set_tsg_clixon_conf
set_mrzcpd_conf
