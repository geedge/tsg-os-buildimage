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
#  copy k3s image tar file to air-gap dir
air_gap_image_dir="/var/lib/rancher/k3s/agent/images"
if [ -d "$air_gap_image_dir" ]; then
    echo "$air_gap_image_dir is exist"
    rm -rf /data$air_gap_image_dir
    mkdir -p /data$air_gap_image_dir
    mv $air_gap_image_dir/* /data$air_gap_image_dir
else
    echo "$air_gap_image_dir is not exist"
fi

tsg_diagnose_images_dir="/opt/tsg/tsg-diagnose/images"
if [ -d "$tsg_diagnose_images_dir" ]; then
    echo "$tsg_diagnose_images_dir is exist"
    mkdir -p /data$air_gap_image_dir
    mv $tsg_diagnose_images_dir/* /data$air_gap_image_dir
else
    echo "$tsg_diagnose_images_dir is not exist"
fi

#  copy helm packages to dest 
helm_charts_dir="/var/lib/rancher/k3s/server/static/charts"
if [ -d "$helm_charts_dir" ]; then
    echo "$helm_charts_dir is exist"
    rm -rf /data$helm_charts_dir
    mkdir -p /data$helm_charts_dir
    cp -a $helm_charts_dir/* /data$helm_charts_dir
else
    echo "$helm_charts_dir is not exist"
fi

#  copy manifests config to dest 
k3s_manifests_dir="/var/lib/rancher/k3s/server/manifests"
if [ -d "$k3s_manifests_dir" ]; then
    echo "$k3s_manifests_dir is exist"
    rm -rf /data$k3s_manifests_dir
    mkdir -p /data$k3s_manifests_dir
    cp -a $k3s_manifests_dir/* /data$k3s_manifests_dir
else
    echo "$k3s_manifests_dir is not exist"
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
