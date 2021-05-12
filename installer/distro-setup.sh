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

# Setup o/s mount points
(cat <<EOF2
tmpfs                   /tmp                    tmpfs   defaults        0 0
tmpfs                   /dev/shm                tmpfs   defaults        0 0
devpts                  /dev/pts                devpts  gid=5,mode=620  0 0
sysfs                   /sys                    sysfs   defaults        0 0
proc                    /proc                   proc    defaults        0 0
${1}               	    /                       ext4    defaults        1 1
/dev/sda4               /data                   ext4    defaults        1 1
overlay                 /etc                    overlay x-systemd.after=/,x-systemd.x-systemd.after=/data,lowerdir=/etc,upperdir=/data/overlay/rootfs_etc/rw,workdir=/data/overlay/rootfs_etc/work 0 0
overlay                 /var                    overlay x-systemd.after=/,x-systemd.x-systemd.after=/data,lowerdir=/var,upperdir=/data/overlay/rootfs_var/rw,workdir=/data/overlay/rootfs_var/work 0 0
EOF2
) > /etc/fstab

# Configure default hostname
echo "HOSTNAME=localhost" > /etc/sysconfig/network

# Disable selinux
sed -ie "s/SELINUX=/SELINUX=disabled/g" /etc/selinux/config

exit 0