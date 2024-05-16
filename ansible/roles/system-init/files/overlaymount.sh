#!/bin/bash

# Mount the overlay rootfs
#touch /etc/overlay-mount.log
read_blk_dev()
{
    kernel_name_descriptor=$(blkid | grep ONIE-BOOT | awk -F ":" '{print $1}' | awk -F "/" '{print $NF}')
    major_device_number=$(cat /proc/partitions | grep ${kernel_name_descriptor} | awk '{print $1}')
    disk_device_name=$(cat /proc/partitions | awk -v major="$major_device_number" '$1 == major && $2 == "0" {print $4}')
    echo "/dev/${disk_device_name}"
}

blk_dev=$(read_blk_dev)
distro_part=4
distro_dev="${blk_dev}${distro_part}"
data_part=5
data_dev="${blk_dev}${data_part}"
mount ${distro_dev} /sysroot
mkdir -p /data
mount ${data_dev} /data
mount -t overlay overlay -o lowerdir=/sysroot/etc,upperdir=/data/overlay/rootfs_etc/rw,workdir=/data/overlay/rootfs_etc/work /sysroot/etc -o x-systemd.requires=/sysroot,x-systemd.requires=/data
umount /data