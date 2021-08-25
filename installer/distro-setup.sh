#!/bin/sh -x

# Create default user: user,admin,support
echo "Setting user user password as user"
useradd -G systemd-journal -s /bin/bash -m user
echo user | passwd user --stdin
#echo "user    ALL=(ALL)       ALL" >> /etc/sudoers
echo user | passwd --stdin

echo "Setting user admin password as admin"
useradd -G systemd-journal -s /bin/bash -m admin
echo admin | passwd admin --stdin
echo "%admin    ALL=(ALL)       ALL" >> /etc/sudoers
echo admin | passwd --stdin

echo "Setting user support password as support"
useradd -G systemd-journal -s /bin/bash -m support
echo support | passwd support --stdin
echo "%support    ALL=(ALL)       ALL" >> /etc/sudoers
echo support | passwd --stdin

# prepare overlayfs
mkdir -p /data/overlay/rootfs_etc/rw
mkdir -p /data/overlay/rootfs_etc/work
mkdir -p /data/overlay/rootfs_var/rw
mkdir -p /data/overlay/rootfs_var/work
mkdir -p /data/overlay/rootfs_home/rw
mkdir -p /data/overlay/rootfs_home/work

#provision path
mkdir -p /data/tsg-os-provision
mkdir -p /data/tsg-os-provision/provision.yml.d

# presistent journald
mkdir -p /var/log/journal

# treat /boot/grub2 as /boot/grub
rm -rf /boot/grub2
ln -sf /boot/grub /boot/grub2

# treat grub2* as grub*
ln -sf /usr/bin/grub2-editenv /usr/bin/grub-editenv

rm -rf /data/overlay/rootfs_var/rw/lib/rpm
rm -rf /data/overlay/rootfs_var/rw/lib/docker
rm -rf /data/overlay/rootfs_etc/rw/ld.so.conf.d

# Setup o/s mount points
(cat <<EOF2
${1}               	    /                       ext4    defaults        1 1
/dev/sda2               /mnt/onie-boot/         ext4    defaults        1 1
/dev/sda3               /update                 ext4    defaults        1 1
/dev/sda5               /data                   ext4    defaults        1 1
overlay                 /etc                    overlay x-systemd.requires=/,x-systemd.requires=/data,lowerdir=/etc,upperdir=/data/overlay/rootfs_etc/rw,workdir=/data/overlay/rootfs_etc/work 0 0
overlay                 /var                    overlay x-systemd.requires=/,x-systemd.requires=/data,lowerdir=/var,upperdir=/data/overlay/rootfs_var/rw,workdir=/data/overlay/rootfs_var/work 0 0
overlay                 /home                   overlay x-systemd.requires=/,x-systemd.requires=/data,lowerdir=/home,upperdir=/data/overlay/rootfs_home/rw,workdir=/data/overlay/rootfs_home/work 0 0
EOF2
) > /etc/fstab

# Configure default hostname
echo "HOSTNAME=localhost" > /etc/sysconfig/network

# Disable selinux
sed -ie "s/SELINUX=/SELINUX=disabled/g" /etc/selinux/config

ldconfig
exit 0
