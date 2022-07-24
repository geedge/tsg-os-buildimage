#!/bin/sh -x

blk_dev=${1}

#  mount /data/home
mkdir -p /data/home/
mount  --bind  /data/home/    /home/

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

# umount  /home/

umount  /home/

# prepare overlayfs
mkdir -p /data/overlay/rootfs_etc/rw
mkdir -p /data/overlay/rootfs_etc/work
mkdir -p /data/var
#mkdir -p /data/overlay/rootfs_var/rw
#mkdir -p /data/overlay/rootfs_var/work
#mkdir -p /data/overlay/rootfs_home/rw
#mkdir -p /data/overlay/rootfs_home/work

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

# look for empty dir    cp /var /data/var
DIR="/data/var"
if [ "$(ls -A $DIR)" ]; then
    echo "$DIR is not Empty"
else
    echo "$DIR is Empty"
    cp -a  /var/*   /data/var/
fi
#  copy rpm
rm -rf /data/var/lib/rpm
cp -a /var/lib/rpm    /data/var/lib/
#
rm -rf /data/var/lib/docker
rm -rf /data/overlay/rootfs_etc/rw/ld.so.conf.d

# Setup o/s mount points
(cat <<EOF2
${blk_dev}4             /                       ext4    defaults        1 1
${blk_dev}2             /mnt/onie-boot/         ext4    defaults        1 1
${blk_dev}3             /update                 ext4    defaults        1 1
${blk_dev}5             /data                   ext4    defaults        1 1
overlay                 /etc                    overlay x-systemd.requires=/,x-systemd.requires=/data,lowerdir=/etc,upperdir=/data/overlay/rootfs_etc/rw,workdir=/data/overlay/rootfs_etc/work 0 0
/data/var               /var/              none     bind,x-systemd.requires=/,x-systemd.requires=/data           0 0
/data/home              /home/             none     bind,x-systemd.requires=/,x-systemd.requires=/data           0 0
EOF2
) > /etc/fstab

# Configure default hostname
echo "HOSTNAME=localhost" > /etc/sysconfig/network

# Disable selinux
sed -ie "s/SELINUX=.*/SELINUX=disabled/g" /etc/selinux/config

ldconfig
exit 0
