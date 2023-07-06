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
    rm -rf $k3s_rancher_dir/k3s/agent/images
else
    echo "$k3s_rancher_dir is not exist"
fi

air_gap_image_dir="/var/lib/rancher/k3s/agent/images"
tsg_diagnose_images_dir="/opt/tsg/tsg-diagnose/images"
if [ -d "$tsg_diagnose_images_dir" ]; then
    echo "$tsg_diagnose_images_dir is exist"
    if [ -d "$air_gap_image_dir" ]; then
        mkdir -p /data$air_gap_image_dir
        mv $tsg_diagnose_images_dir/* /data$air_gap_image_dir
    fi
else
    echo "$tsg_diagnose_images_dir is not exist"
fi


# copy mrzcpd alternatives file to dest
mrzcpd_alternatives_dir="/var/lib/alternatives"

if [ -d "$mrzcpd_alternatives_dir" ]; then
    echo "$mrzcpd_alternatives_dir is exist"
    rm -rf /data$mrzcpd_alternatives_dir
    mkdir -p /data$mrzcpd_alternatives_dir
    cp -a $mrzcpd_alternatives_dir/* /data$mrzcpd_alternatives_dir
else
    echo "$mrzcpd_alternatives_dir is not exist"
fi

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
