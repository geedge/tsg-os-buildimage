#!/bin/sh -x

# Create default user onie, with password onie
echo "Setting user onie password as onie"
useradd -s /bin/bash -m -k /dev/null onie
echo onie | passwd onie --stdin
echo "onie    ALL=(ALL)       ALL" >> /etc/sudoers
echo onie | passwd --stdin

# prepare overlayfs
mkdir -p /data/overlay/rootfs_etc/rw
mkdir -p /data/overlay/rootfs_etc/work
mkdir -p /data/overlay/rootfs_var/rw
mkdir -p /data/overlay/rootfs_var/work

#provision path
mkdir -p /data/tsg-os-provision

# app_proto_engine's license
mkdir -p /data/app_proto_engine/license

# presistent journald
mkdir -p /var/log/journal

# treat /boot/grub2 as /boot/grub
rm -rf /boot/grub2
ln -sf /boot/grub /boot/grub2

# treat grub2* as grub*
ln -sf /usr/bin/grub2-editenv /usr/bin/grub-editenv

# Setup o/s mount points
(cat <<EOF2
tmpfs                   /tmp                    tmpfs   defaults        0 0
tmpfs                   /dev/shm                tmpfs   defaults        0 0
devpts                  /dev/pts                devpts  gid=5,mode=620  0 0
sysfs                   /sys                    sysfs   defaults        0 0
proc                    /proc                   proc    defaults        0 0
${1}               	    /                       ext4    defaults        1 1
/dev/sda4               /data                   ext4    defaults        1 1
/dev/sda2               /mnt/onie-boot/         ext4    defaults        1 1
overlay                 /etc                    overlay x-systemd.requires=/,x-systemd.requires=/data,lowerdir=/etc,upperdir=/data/overlay/rootfs_etc/rw,workdir=/data/overlay/rootfs_etc/work 0 0
overlay                 /var                    overlay x-systemd.requires=/,x-systemd.requires=/data,lowerdir=/var,upperdir=/data/overlay/rootfs_var/rw,workdir=/data/overlay/rootfs_var/work 0 0
EOF2
) > /etc/fstab

# Configure default hostname
echo "HOSTNAME=localhost" > /etc/sysconfig/network

# Disable selinux
sed -ie "s/SELINUX=/SELINUX=disabled/g" /etc/selinux/config

ldconfig
exit 0
