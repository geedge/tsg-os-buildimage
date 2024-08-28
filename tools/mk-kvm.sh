#!/bin/sh

#  Copyright (C) 2014 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0
set -xe

MEM=28672
DISK=$1

# Path to ONIE installer .iso image
CDROM="onie-uefi-kvm_x86_64.iso"

# Path to OVMF firmware for qemu
# Download OVMF from http://www.tianocore.org/ovmf/
OVMF="OVMF.fd"

# VM will listen on telnet port $KVM_PORT
KVM_PORT=9000

# VNC display to use
VNC_PORT=0

# set mode=disk to boot from hard disk
mode=disk

# set mode=cdrom to boot from the CDROM
# mode=cdrom

# set mode=net to boot from network adapters
# mode=net

# set firmware=uefi to boot with UEFI firmware, otherwise the system
# will boot into legacy mode.
# firmware=uefi

boot=c
if [ "$mode" = "cdrom" ] ; then
    boot="order=cd,once=d"
    cdrom="-cdrom $CDROM"
elif [ "$mode" = "net" ] ; then
    boot="order=cd,once=n,menu=on"
fi

if [ "$firmware" = "uefi" ] ; then
    [ -r "$OVMF" ] || {
        echo "ERROR:  Cannot find the OVMF firmware for UEFI: $OVMF"
        echo "Please make sure to install the OVMF.fd in the expected directory"
        exit 1
    }
    bios="-bios $OVMF"
fi

/usr/libexec/qemu-kvm -m $MEM \
    -name "onie" \
    -smp 4,cores=2,threads=1,sockets=2 \
    $bios \
    -boot $boot $cdrom \
    -device e1000,netdev=onienet \
    -netdev user,id=onienet,hostfwd=:0.0.0.0:3040-:22 \
    -nographic \
    -no-reboot \
    -drive file=$DISK,media=disk,if=virtio,index=0

exit 0
