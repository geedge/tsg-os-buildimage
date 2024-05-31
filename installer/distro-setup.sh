#!/bin/sh -x

blk_dev=${1}

#  mount /data/home
mkdir -p /data/home/
mount  --bind  /data/home/    /home/

# Create default user: user,admin,support
echo "Setting user user password as user"
useradd -G systemd-journal -s /bin/bash -m user
echo GDNT2023J8e+76 | passwd user --stdin
#echo "user    ALL=(ALL)       ALL" >> /etc/sudoers
echo GDNT2023J8e+76 | passwd --stdin

echo "Setting user admin password as admin"
useradd -G systemd-journal -s /bin/bash -m admin
echo GDNT202342U9.x | passwd admin --stdin
echo "%admin    ALL=(ALL)       ALL" >> /etc/sudoers
echo GDNT202342U9.x | passwd --stdin

echo "Setting user support password as support"
useradd -G systemd-journal -s /bin/bash -m support
echo GDNT2023QV3:vI | passwd support --stdin
echo "%support    ALL=(ALL)       ALL" >> /etc/sudoers
echo GDNT2023QV3:vI | passwd --stdin

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
# generate machine-id if /data/overlay/rootfs_etc/rw/persistent-machine-id not exsit
mkdir -p /data/var/lib/tsg-os
cat /dev/null > /etc/machine-id
PATH_PERSISTENT_MACHINE_ID="/data/var/lib/tsg-os/persistent-machine-id"
if [ -f "$PATH_PERSISTENT_MACHINE_ID" ]; then
    cat $PATH_PERSISTENT_MACHINE_ID > /etc/machine-id
else
    /usr/bin/systemd-machine-id-setup
    cat /etc/machine-id > $PATH_PERSISTENT_MACHINE_ID
fi

###clear /etc/rancher
# k3s_overlay_etc_rancher="/data/overlay/rootfs_etc/rw/rancher"
# if [ -d "$k3s_overlay_etc_rancher" ]; then
#     echo "$k3s_overlay_etc_rancher is exist"
#     rm -rf $k3s_overlay_etc_rancher
# else
#     echo "$k3s_overlay_etc_rancher is not exist"
# fi

###clear /data/var/lib/rancher dir
# copy k3s image tar file to air-gap dir
k3s_rancher_dir="/var/lib/rancher"
if [ -d "$k3s_rancher_dir" ]; then
    echo "$k3s_rancher_dir is exist"
    rm -rf /data$k3s_rancher_dir
    rm -rf /data/var/lib/kubelet
    mkdir -p /data$k3s_rancher_dir
    cp -a $k3s_rancher_dir/* /data$k3s_rancher_dir
    rm -rf $k3s_rancher_dir/k3s/agent/images/*
else
    echo "$k3s_rancher_dir is not exist"
fi

# Setup o/s mount points
(cat <<EOF2
LABEL=TSG-OS-SYSROOT    /                       ext4    defaults        1 1
LABEL=ONIE-BOOT         /mnt/onie-boot/         ext4    defaults        1 1
LABEL=TSG-OS-UPDATE     /update                 ext4    defaults        1 1
LABEL=TSG-OS-DATA       /data                   ext4    defaults        1 1
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
