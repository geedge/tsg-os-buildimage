#!/bin/sh -x

# Create default user onie, with password onie
echo "Setting user onie password as onie"
useradd -s /bin/bash -m -k /dev/null onie
echo onie | passwd onie --stdin
echo "onie    ALL=(ALL)       ALL" >> /etc/sudoers
echo onie | passwd --stdin

# Setup o/s mount points
(cat <<EOF2
tmpfs                   /tmp                    tmpfs   defaults        0 0
tmpfs                   /dev/shm                tmpfs   defaults        0 0
devpts                  /dev/pts                devpts  gid=5,mode=620  0 0
sysfs                   /sys                    sysfs   defaults        0 0
proc                    /proc                   proc    defaults        0 0
/dev/sda3               /config                 ext4    defaults        1 1
/dev/sda4               /data                   ext4    defaults        1 1
${1}               	/                       ext4    defaults        1 1
EOF2
) > /etc/fstab

# Configure default hostname
echo "HOSTNAME=localhost" > /etc/sysconfig/network

# Disable selinux
sed -ie "s/SELINUX=/SELINUX=disabled/g" /etc/selinux/config

# Fix grub2 cannot read envcfg from grub2
ln -sf /boot/grub2/grubenv /boot/grub/grubenv

# restore /etc/passwd, /etc/group, and /etc/shadow
mkdir -p /config/sysroot/etc/
mkdir -p /config/sysroot/etc/ssh

if [ ! -f /config/sysroot/etc/passwd ]; then
    cp /etc/passwd /config/sysroot/etc/passwd 
fi  

if [ ! -f /config/sysroot/etc/group ]; then
    cp /etc/group /config/sysroot/etc/group
fi

if [ ! -f /config/sysroot/etc/shadow ]; then
    cp /etc/shadow /config/sysroot/etc/shadow
fi

ln -sf "/config/sysroot/etc/passwd" /etc/passwd
ln -sf "/config/sysroot/etc/group" /etc/group
ln -sf "/config/sysroot/etc/shadow" /etc/shadow

# regenerate ssh host keys
if [ ! -f /config/sysroot/etc/ssh/ssh_host_dsa_key ]; then
    ssh-keygen -q -N "" -t dsa -f /config/sysroot/etc/ssh/ssh_host_dsa_key
fi

if [ ! -f /config/sysroot/etc/ssh/ssh_host_rsa_key ]; then
    ssh-keygen -q -N "" -t rsa -b 4096 -f /config/sysroot/etc/ssh/ssh_host_rsa_key
fi

if [ ! -f /config/sysroot/etc/ssh/ssh_host_ecdsa_key ]; then
    ssh-keygen -q -N "" -t ecdsa -f /config/sysroot/etc/ssh/ssh_host_ecdsa_key
fi

if [ ! -f /config/sysroot/etc/ssh/ssh_host_ed25519_key ]; then
    ssh-keygen -q -N "" -t ed25519 -f /config/sysroot/etc/ssh/ssh_host_ed25519_key
fi

ln -sf "/config/sysroot/etc/ssh/ssh_host_dsa_key" /etc/ssh/ssh_host_dsa_key
ln -sf "/config/sysroot/etc/ssh/ssh_host_rsa_key" /etc/ssh/ssh_host_rsa_key
ln -sf "/config/sysroot/etc/ssh/ssh_host_ecdsa_key" /etc/ssh/ssh_host_ecdsa_key
ln -sf "/config/sysroot/etc/ssh/ssh_host_ed25519_key" /etc/ssh/ssh_host_ed25519_key

exit 0
