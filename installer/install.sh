#!/bin/sh

install_device_platform()
{
    # Virtual IO block device
    if grep -q vda /proc/partitions ; then
        echo /dev/vda
        return 0
    fi

    # SATA, SCSI, USB block device
    if grep -q sda /proc/partitions ; then
        echo /dev/sda
        return 0
    fi

    echo /dev/sda
}

blk_dev=$(install_device_platform)
echo "TSG-OS install on ${blk_dev}"
random_dev=/dev/urandom
root_disk=hd0
distro_part=4
distro_dev="${blk_dev}${distro_part}"
distro_mnt=/mnt/distro
onie_root_dir=/mnt/onie-boot/onie

kernel_args="%%KERNAL_ARGS%%"
grub_serial_command="%%GRUB_SERIAL_COMMAND%%"
DISTR0_VER="%%DISTR0_VER%%"
MACHINE_ID="%%MACHINE_ID%%"
CHROOT_PKG="%%CHROOT_PKG%%"
CONTAINER_IMAGES_PKG="%%CONTAINER_IMAGES_PKG%%"

size_part_tsg_os_update="%%SIZE_PART_UPDATE%%"
size_part_tsg_os_sysroot="%%SIZE_PART_SYSROOT%%"
size_part_tsg_os_data="%%SIZE_PART_DATA%%"

vol_label_tsg_os_update="TSG-OS-UPDATE"
vol_label_tsg_os_sysroot="TSG-OS-SYSROOT"
vol_label_tsg_os_data="TSG-OS-DATA"

exp_part_tsg_os_update=3
exp_part_tsg_os_sysroot=4
exp_part_tsg_os_data=5

dev_part_tsg_os_update="${blk_dev}${exp_part_tsg_os_update}"
dev_part_tsg_os_sysroot="${blk_dev}${exp_part_tsg_os_sysroot}"
dev_part_tsg_os_data="${blk_dev}${exp_part_tsg_os_data}"

tsg_os_efi_prefix="TSG-OS"
tsg_os_efi_label="TSG-OS: ${DISTR0_VER} (${MACHINE_ID})"

# auto-detect whether BIOS or UEFI
if [ -d "/sys/firmware/efi/efivars" ] ; then
    firmware="uefi"
else
    firmware="bios"
fi

check_is_upgrade()
{
  part_tsg_os_update=$(sgdisk -p $blk_dev | grep -e "$vol_label_tsg_os_update" | awk '{print $1}')
  part_tsg_os_sysroot=$(sgdisk -p $blk_dev | grep -e "$vol_label_tsg_os_sysroot" | awk '{print $1}')
  part_tsg_os_data=$(sgdisk -p $blk_dev | grep -e "$vol_label_tsg_os_data" | awk '{print $1}')

  if [ "$part_tsg_os_update"  != "$exp_part_tsg_os_update" ]; then return 1
  elif [ "$part_tsg_os_sysroot" != "$exp_part_tsg_os_sysroot" ]; then return 1
  elif [ "$part_tsg_os_data" != "$exp_part_tsg_os_data" ]; then return 1
  fi
  return 0
}

format_update_partitions() {
  mkfs.ext4 -L "TGS-OS-UPDATE" $dev_part_tsg_os_update || {
    echo "ERROR: Unable to create file system on \$dev_part_tsg_os_update"
    exit 1
  }
}

format_sysroot_partitions() {
  mkfs.ext4 -L "TGS-OS-SYSROOT" $dev_part_tsg_os_sysroot || {
    echo "ERROR: Unable to create file system on \$dev_part_tsg_os_sysroot"
    exit 1
  }
}

format_presistent_partitions() {
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

  echo "Create partition TSG-OS-UPDATE."
  begin=$(sgdisk -F $blk_dev)
  sgdisk --new=${exp_part_tsg_os_update}:${begin}:+${size_part_tsg_os_update} \
         --change-name=${exp_part_tsg_os_update}:"TSG-OS-UPDATE" ${blk_dev} || {
        echo "ERROR: Unable to create partition TSG-OS-UPDATE on $blk_dev"
        exit 1
  }

  echo "Create partition TSG-OS-SYSROOT."
  begin=$(sgdisk -F $blk_dev)
  sgdisk --new=${exp_part_tsg_os_sysroot}:${begin}:+${size_part_tsg_os_sysroot} \
         --change-name=${exp_part_tsg_os_sysroot}:"TSG-OS-SYSROOT" ${blk_dev} || {
        echo "ERROR: Unable to create partition TSG-OS-SYSROOT on $blk_dev"
        exit 1
  }

  echo "Create partition TSG-OS-DATA."
  begin=$(sgdisk -F $blk_dev)
  end=$(sgdisk -E $blk_dev)

  sgdisk --new=${exp_part_tsg_os_data}:${begin}:${end} \
         --change-name=${exp_part_tsg_os_data}:"TSG-OS-DATA" ${blk_dev} || {
        echo "ERROR: Unable to create partition TSG-OS-DATA on $blk_dev"
        exit 1
  }

  partprobe ${blk_dev}
}

# Install legacy BIOS GRUB for DEMO OS
install_grub()
{
    local demo_mnt="$1"
    local blk_dev="$2"

    # get running machine from conf file
    [ -r /etc/machine.conf ] && . /etc/machine.conf

    local grub_target="i386-pc"

    grub-install --target="$grub_target" \
        --boot-directory="$demo_mnt" --recheck "$blk_dev" || {
        echo "ERROR: grub-install failed on: $blk_dev"
        exit 1
    }
}

# Install UEFI BIOS GRUB for DEMO OS
install_uefi_grub()
{
    local demo_mnt="$1"
    local blk_dev="$2"

    # get running machine from conf file
    [ -r /etc/machine.conf ] && . /etc/machine.conf

    # Look for the EFI system partition UUID on the same block device as
    # the ONIE-BOOT partition.
    local uefi_part=0
    for p in $(seq 8) ; do
        if sgdisk -i $p $blk_dev | grep -q C12A7328-F81F-11D2-BA4B-00A0C93EC93B ; then
            uefi_part=$p
            break
        fi
    done

    [ $uefi_part -eq 0 ] && {
        echo "ERROR: Unable to determine UEFI system partition"
        exit 1
    }

    # erase any related EFI BootOrder variables from NVRAM.
    for b in $(efibootmgr | grep "$tsg_os_efi_prefix" | awk '{ print $1 }') ; do
        local num=${b#Boot}
        # Remove trailing '*'
        num=${num%\*}
        efibootmgr -b $num -B > /dev/null 2>&1
    done

    # Regular GRUB install
    grub_install_log=$(mktemp)
    grub-install \
        --no-nvram \
        --bootloader-id="$tsg_os_efi_prefix" \
        --efi-directory="/boot/efi" \
        --boot-directory="$demo_mnt" \
        --recheck \
        "$blk_dev" > /$grub_install_log 2>&1 || {
        echo "ERROR: grub-install failed on: $blk_dev"
        cat $grub_install_log && rm -f $grub_install_log
        exit 1
    }
    rm -f $grub_install_log

    # Configure EFI NVRAM Boot variables.  --create also sets the
    # new boot number as active.
    efibootmgr --quiet --create \
        --label "$tsg_os_efi_label" \
        --disk $blk_dev --part $uefi_part \
        --loader "/EFI/$tsg_os_efi_prefix/$onie_uefi_boot_loader" || {
        echo "ERROR: efibootmgr failed to create new boot variable on: $blk_dev"
        exit 1
    }
}


############################### START AT HERE #########################################
lib_dir="/lib/onie"
. $lib_dir/onie-blkdev-common

cd $(dirname $0)

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

    format_update_partitions || {
       echo "ERROR: Unable to format update partitions on $blk_dev, TSG-OS install failed."
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

# bonk out on errors
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

mkdir -p ${distro_mnt}/data
mount -t ext4 ${blk_dev}${exp_part_tsg_os_data} ${distro_mnt}/data

echo "Setting up TSG-OS sysroot .."
chroot ${distro_mnt} /distro-setup.sh ${blk_dev}

[ -e ${distro_mnt}/dev/pts ] && {
   umount ${distro_mnt}/dev/pts
}

if [ -f ${CONTAINER_IMAGES_PKG} ]; then
    mkdir -p ${distro_mnt}/data/var/lib/rancher/k3s/agent/images
    rm -rf ${distro_mnt}/data/var/lib/rancher/k3s/agent/images/tsg-*-docker.tar
    tar -xf ${CONTAINER_IMAGES_PKG} -C ${distro_mnt}/data/var/lib/rancher/k3s/agent/images
fi

umount ${distro_mnt}/proc
umount ${distro_mnt}/sys
umount ${distro_mnt}/data

# Install boot loader
echo "Install GRUB2 bootloader .."

if [ "$firmware" = "uefi" ] ; then
    install_uefi_grub "${distro_mnt}/boot" "$blk_dev"
else
    install_grub "${distro_mnt}/boot" "$blk_dev"
fi

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
menuentry 'TSG-OS ${DISTR0_VER} (${MACHINE_ID})' {
  set root='(${root_disk},gpt${distro_part})'
  echo    'Loading TSG-OS ${DISTR0_VER} (${MACHINE_ID}) ...'
  linux   /boot/vmlinuz ${kernel_args} root=${blk_dev}${distro_part}
  echo    'Loading TSG-OS ${DISTR0_VER} (${MACHINE_ID}) initial ramdisk ...'
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
