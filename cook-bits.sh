#!/bin/bash

#
#  Copyright (C) 2017 Rajendra Dendukuri <rajendra.dendukuri@broadcom.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#

# Make an ONIE installer using CentOS 7 chroot environment
#
# inputs: cento7 chroot package
# output: ONIE compatible OS installer image
#
# Comments: This script expects that yumbootsstrap is installed on
#           on the Linux host where it is executed.

#!/bin/sh

set -e

IN=./input
OUT=./output
rm -rf $OUT
mkdir -p $OUT

INSTALLER_TEMPLATE_DIR=./installer
WORKDIR=./work
EXTRACTDIR="$WORKDIR/extract"
INSTALLDIR="$WORKDIR/installer"

# Create a centos-7 chroot package if not done already
DISTR0_VER="21.04.1"
MACHINE_ID="9140NPCP01R01"

CHROOT_PKG="tsg-os-${DISTR0_VER}-${MACHINE_ID}-chroot.tar.bz2"
output_file="${OUT}/tsg-os-${DISTR0_VER}-${MACHINE_ID}-ONIE.bin"

echo -n "Creating $output_file: ."

# prepare workspace
[ -d $EXTRACTDIR ] && chmod +w -R $EXTRACTDIR
rm -rf $WORKDIR
mkdir -p $EXTRACTDIR
mkdir -p $INSTALLDIR

# Copy distro package
cp -f ${IN}/${CHROOT_PKG} $INSTALLDIR

# Create custom install.sh script
cp $INSTALLER_TEMPLATE_DIR/install.sh $INSTALLDIR/install.sh
chmod +x $INSTALLDIR/install.sh
sed -i -e "s/%%DISTR0_VER%%/$DISTR0_VER/" $INSTALLDIR/install.sh
sed -i -e "s/%%MACHINE_ID%%/$MACHINE_ID/" $INSTALLDIR/install.sh
sed -i -e "s/%%CHROOT_PKG%%/$CHROOT_PKG/" $INSTALLDIR/install.sh

# Create o/s setup script
cp $INSTALLER_TEMPLATE_DIR/distro-setup.sh $INSTALLDIR/distro-setup.sh
chmod +x $INSTALLDIR/distro-setup.sh

echo -n "."

# Repackage $INSTALLDIR into a self-extracting installer image
sharch="$WORKDIR/sharch.tar"
tar -C $WORKDIR -cf $sharch installer || {
    echo "Error: Problems creating $sharch archive"
    exit 1
}

[ -f "$sharch" ] || {
    echo "Error: $sharch not found"
    exit 1
}
echo -n "."

sha1=$(cat $sharch | sha1sum | awk '{print $1}')
echo -n "."

cp sharch_body.sh $output_file || {
    echo "Error: Problems copying sharch_body.sh"
    exit 1
}

# Replace variables in the sharch template
sed -i -e "s/%%IMAGE_SHA1%%/$sha1/" $output_file
echo -n "."
cat $sharch >> $output_file
rm -rf $tmp_dir
echo " Done."
