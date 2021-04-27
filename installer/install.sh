#!/bin/sh

blk_dev=/dev/sda
random_dev=/dev/urandom
root_disk=hd0
distro_part=5
distro_dev="/dev/sda${distro_part}"
distro_mnt=/mnt/distro
onie_root_dir=/mnt/onie-boot/onie
distro_config_mnt=/mnt/distro_config
kernel_args=""
grub_serial_command=""

vol_label_tsg_os_sysroot_primary="TSG-OS-SYSROOT-1"
vol_label_tsg_os_sysroot_secondry="TSG-OS-SYSROOT-2"
vol_label_tsg_os_config="TSG-OS-CONFIG"
vol_label_tsg_os_data="TSG-OS-DATA"
exp_part_tsg_os_config=3
exp_part_tsg_os_data=4
exp_part_tsg_os_sysroot_primary=5
exp_part_tsg_os_sysroot_secondry=6
size_part_tsg_os_config="128M"
size_part_tsg_os_data="128M"
size_part_tsg_os_sysroot_primary="4096M"
size_part_tsg_os_sysroot_secondry="2048M"
dev_part_tsg_os_sysroot_primary="/dev/sda${exp_part_tsg_os_sysroot_primary}"
dev_part_tsg_os_sysroot_secondry="/dev/sda${exp_part_tsg_os_sysroot_secondry}"
dev_part_tsg_os_config="/dev/sda${exp_part_tsg_os_config}"
dev_part_tsg_os_data="/dev/sda${exp_part_tsg_os_data}"

DISTR0_VER="%%DISTR0_VER%%"
MACHINE_ID="%%MACHINE_ID%%"
CHROOT_PKG="%%CHROOT_PKG%%"

check_is_upgrade() {
  part_tsg_os_data=$(sgdisk -p $blk_dev | grep -e "$vol_label_tsg_os_data" | awk '{print $1}')
  part_tsg_os_config=$(sgdisk -p $blk_dev | grep -e "$vol_label_tsg_os_config" | awk '{print $1}')
  part_tsg_os_sysroot_primary=$(sgdisk -p $blk_dev | grep -e "$vol_label_tsg_os_sysroot_primary" | awk '{print $1}')
  part_tsg_os_sysroot_secondry=$(sgdisk -p $blk_dev | grep -e "$vol_label_tsg_os_sysroot_secondry" | awk '{print $1}')

  if [ "$part_tsg_os_data" != "$exp_part_tsg_os_data" ]; then return 1
  elif [ "$part_tsg_os_config" != "$exp_part_tsg_os_config" ]; then return 1
  elif [ "$part_tsg_os_sysroot_primary" != "$exp_part_tsg_os_sysroot_primary" ]; then return 1
  elif [ "$part_tsg_os_sysroot_secondry" != "$exp_part_tsg_os_sysroot_secondry" ]; then return 1
  fi
  
  return 0
}

format_sysroot_partitions() {
  mkfs.ext4 -L "TGS-OS-SYSROOT-1" $dev_part_tsg_os_sysroot_primary || {
    echo "ERROR: Unable to create file system on \$dev_part_tsg_os_sysroot_primary"
    exit 1
  }

  mkfs.ext4 -L "TGS-OS-SYSROOT-2" $dev_part_tsg_os_sysroot_secondry || {
    echo "ERROR: Unable to create file system on \$dev_part_tsg_os_sysroot_secondry"
    exit 1
  }
}

format_presistent_partitions() {
  mkfs.ext4 -L "TSG-OS-CONFIG" $dev_part_tsg_os_config || {
    echo "ERROR: Unable to create file system on \$dev_part_tsg_os_config"
    exit 1
  }

  mkfs.ext4 -L "TSG-OS-DATA" $dev_part_tsg_os_data || {
    echo "ERROR: Unable to create file system on \$dev_part_tsg_os_data"
    exit 1
  }
}

create_gpt_partitions() {
  # remove old partitions
  for p in $(seq 3 9) ; do
    umount -f $blk_dev$p  > /dev/null 2&>1
    sgdisk -d $p $blk_dev > /dev/null 2&>1
  done

  partprobe ${blk_dev}

  echo "Create partition TSG-OS-CONFIG."
  begin=$(sgdisk -F $blk_dev)
  sgdisk --new=${exp_part_tsg_os_config}:${begin}:+${size_part_tsg_os_config} \
         --change-name=${exp_part_tsg_os_config}:"TSG-OS-CONFIG" ${blk_dev} || {
        echo "ERROR: Unable to create partition TSG-OS-CONFIG on $blk_dev"
        exit 1
  }

  echo "Create partition TSG-OS-DATA."
  begin=$(sgdisk -F $blk_dev)
  sgdisk --new=${exp_part_tsg_os_data}:${begin}:+${size_part_tsg_os_data} \
         --change-name=${exp_part_tsg_os_data}:"TSG-OS-DATA" ${blk_dev} || {
        echo "ERROR: Unable to create partition TSG-OS-DATA on $blk_dev"
        exit 1
  }

  echo "Create partition TSG-OS-SYSROOT-1."
  begin=$(sgdisk -F $blk_dev)
  sgdisk --new=${exp_part_tsg_os_sysroot_primary}:${begin}:+${size_part_tsg_os_sysroot_primary} \
         --change-name=${exp_part_tsg_os_sysroot_primary}:"TSG-OS-SYSROOT-1" ${blk_dev} || {
        echo "ERROR: Unable to create partition TSG-OS-SYSROOT-1 on $blk_dev"
        exit 1
  }

  echo "Create partition TSG-OS-SYSROOT-2."
  begin=$(sgdisk -F $blk_dev)
  sgdisk --new=${exp_part_tsg_os_sysroot_secondry}:${begin}:+${size_part_tsg_os_sysroot_secondry} \
         --change-name=${exp_part_tsg_os_sysroot_secondry}:"TSG-OS-SYSROOT-2" ${blk_dev} || {
        echo "ERROR: Unable to create partition TSG-OS-SYSROOT-2 on $blk_dev"
        exit 1
  }

  partprobe ${blk_dev}
}

cd $(dirname $0)
# bonk out on errors

if check_is_upgrade; then
   echo "Upgrading TSG-OS, the config and data partitions will be keeped in $blk_dev."
  
   format_sysroot_partitions || {
       echo "ERROR: Unable to format sysroot partition on $blk_dev, TSG-OS install failed."
       exit 1
   }

else
   echo "Installing TSG-OS, all partitions on $blk_dev will be erased."

   create_gpt_partitions || {
       echo "ERROR: Unable to create partitions on $blk_dev, TSG-OS install failed."
       exit 1
   }

   format_sysroot_partitions || {
       echo "ERROR: Unable to format sysroot partition on $blk_dev, TSG-OS install failed."
       exit 1
   }

   format_presistent_partitions || {
       echo "ERROR: Unable to format presistent partitions on $blk_dev, TSG-OS install failed."
       exit 1
   }
fi

# Mount filesystem
mkdir -p $distro_mnt || {
    echo "ERROR: Unable to create distro file system mount point: \$distro_mnt"
    exit 1
}

mount -t ext4 -o defaults,rw $distro_dev $distro_mnt || {
    echo "ERROR: Unable to mount $distro_dev on $distro_mnt"
    exit 1
}

set -ex

cp -f distro-setup.sh ${distro_mnt}
echo "Extract chroot environment ..."
tar -xf ${CHROOT_PKG} -C ${distro_mnt}

[ -e ${distro_mnt}/dev/pts ] && {
    mount -o bind /dev/pts \${distro_mnt}/dev/pts
}

mount -t proc proc ${distro_mnt}/proc
mount -t sysfs sys ${distro_mnt}/sys
cp -a ${blk_dev} ${distro_mnt}/${blk_dev}
cp -a ${random_dev} ${distro_mnt}/${random_dev}

mkdir -p ${distro_mnt}/config
mount -t ext4 /dev/sda${exp_part_tsg_os_config} ${distro_mnt}/config

echo "Setting up TSG-OS sysroot .."
chroot ${distro_mnt} /distro-setup.sh ${distro_dev}

[ -e ${distro_mnt}/dev/pts ] && {
   umount ${distro_mnt}/dev/pts
}

umount ${distro_mnt}/proc
umount ${distro_mnt}/sys
umount ${distro_mnt}/config

# Install boot loader
echo "Install GRUB2 bootloader .."
grub-install --boot-directory="${distro_mnt}/boot" --recheck "${blk_dev}" || {
        echo "ERROR: grub-install failed on: ${blk_dev}"
        exit 1
}

# Prepare boot loader configuration file
grub_cfg=$(mktemp)

# Add common configuration, like the timeout and serial console.
(cat <<EOF2

${grub_serial_command}
terminal_input serial
terminal_output serial
set timeout=5

# Add the logic to support grub-reboot
if [ -s \$prefix/grubenv ]; then
  load_env
fi
if [ "\${saved_entry}" ] ; then
   set default="\${saved_entry}"
   set saved_entry=
   save_env saved_entry
fi

if [ "\${next_entry}" ] ; then
   set default="\${next_entry}"
   set next_entry=
   save_env next_entry
fi

EOF2
) >> ${grub_cfg}


# Add a menu entry for o/s distro
(cat <<EOF3
menuentry 'TSG-OS v${DISTR0_VER} (${MACHINE_ID})' {
  set root='(${root_disk},gpt${distro_part})'
  echo    'Loading TSG-OS v${DISTR0_VER} (${MACHINE_ID}) ...'
  linux   /boot/vmlinuz ${kernel_args} root=${blk_dev}${distro_part}
  echo    'Loading TSG-OS v${DISTR0_VER} (${MACHINE_ID}) initial ramdisk ...'
  initrd  /boot/initrd.img
 }
EOF3
) >> ${grub_cfg}


# Add menu entries for ONIE -- use the grub fragment provided by the
# ONIE distribution.
$onie_root_dir/grub.d/50_onie_grub >> ${grub_cfg}

# Copy boot loader config to appropriate location
cp -f ${grub_cfg} ${distro_mnt}/boot/grub/grub.cfg
cat ${grub_cfg} >> ${distro_mnt}/etc/grub.d/40_onie_grub

umount ${distro_mnt}

cd /

echo "TSG-OS install successfully, need to reboot."
exit 0
