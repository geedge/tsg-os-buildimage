#!/bin/sh -e

total_mem=$(free -g | grep Mem | awk '{print $2}')

if [ $total_mem -le 32 ]; then
	n_hugepages_1G=4
	mrzcpd_direct_pktmbuf=262144
fi

if [ $total_mem -gt 32 ] && [ $total_mem -le 64 ]; then
        n_hugepages_1G=8
        mrzcpd_direct_pktmbuf=1048576
fi

if [ $total_mem -gt 64 ]; then
        n_hugepages_1G=16
        mrzcpd_direct_pktmbuf=2097152
fi


sed -i "s/^HUGEPAGE_NUM_1G=.*$/HUGEPAGE_NUM_1G=$n_hugepages_1G/g" /etc/sysconfig/mrzcpd
sed -i "s/^sz_direct_pktmbuf=.*$/sz_direct_pktmbuf=$mrzcpd_direct_pktmbuf/g" /opt/tsg/mrzcpd/etc/mrglobal.conf

if grep -q "hugepages=$n_hugepages_1G" /proc/cmdline
then
	echo "Not set hugepages!"
else
	sed  -i "s/hugepages=[0-9]*/hugepages=$n_hugepages_1G/g" /boot/grub/grub.cfg
	sed  -i "s/hugepages=[0-9]*/hugepages=$n_hugepages_1G/g" /etc/grub.d/40_onie_grub
	echo "Detected that the configuration of hugepages has changed, please run command \"provision-config-apply --reboot\" to reboot the machine that make the configuration take effect!"
fi
