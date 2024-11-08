#!/bin/bash

UNARCHIVE_DIR="/tmp/9000_NPB_patches"


function unarchive_patch_tgz()
{
    mkdir -p $UNARCHIVE_DIR
    PAYLOAD_LINE=`awk '/^__PAYLOAD_BELOW__/ {print NR + 1; exit 0; }' $0`
    tail -n+$PAYLOAD_LINE $0 | tar xzv -C $UNARCHIVE_DIR 
}

function install_patch_files()
{
    cp $UNARCHIVE_DIR/90-9000NPBP01R01.rules /usr/lib/udev/rules.d/90-9000NPBP01R01.rules

    cp $UNARCHIVE_DIR/ifcfg-eth_pf_smbio     /etc/sysconfig/network-scripts/ifcfg-eth_pf_smbio
    cp $UNARCHIVE_DIR/nm_pre-up_set_eth_pf_smbio_macaddr.sh /usr/lib/NetworkManager/dispatcher.d/pre-up.d/01-set_eth_pf_smbio_macaddr.sh
    chmod 0755 /usr/lib/NetworkManager/dispatcher.d/pre-up.d/01-set_eth_pf_smbio_macaddr.sh

    cp $UNARCHIVE_DIR/ifcfg-eth_pf_smbcx     /etc/sysconfig/network-scripts/ifcfg-eth_pf_smbcx
    cp $UNARCHIVE_DIR/ifcfg-eth_vf_mirr      /etc/sysconfig/network-scripts/ifcfg-eth_vf_mirr
    cp $UNARCHIVE_DIR/ifcfg-eth_vf_ctl       /etc/sysconfig/network-scripts/ifcfg-eth_vf_ctl

    #Network Manager dispatcher shell
    cp $UNARCHIVE_DIR/nm_pre-up_set_mgmt_ipaddr.sh /usr/lib/NetworkManager/dispatcher.d/pre-up.d/00-set_mgmt_ipaddr.sh
    chmod 0755 /usr/lib/NetworkManager/dispatcher.d/pre-up.d/00-set_mgmt_ipaddr.sh

    cp $UNARCHIVE_DIR/ifcfg-eth_pf_xe0       /etc/sysconfig/network-scripts/ifcfg-eth_pf_xe0
    cp $UNARCHIVE_DIR/ifcfg-eth_pf_xe1       /etc/sysconfig/network-scripts/ifcfg-eth_pf_xe1
    cp $UNARCHIVE_DIR/ifcfg-eth_pf_mgmt0     /etc/sysconfig/network-scripts/ifcfg-eth_pf_mgmt0
    cp $UNARCHIVE_DIR/ifcfg-eth_pf_mgmt1     /etc/sysconfig/network-scripts/ifcfg-eth_pf_mgmt1
    cp $UNARCHIVE_DIR/ifcfg-eth_pf_ge0       /etc/sysconfig/network-scripts/ifcfg-eth_pf_ge0
    cp $UNARCHIVE_DIR/ifcfg-eth_pf_ge1       /etc/sysconfig/network-scripts/ifcfg-eth_pf_ge1

    cp $UNARCHIVE_DIR/90-9000-dracut.rules   /usr/lib/dracut/dracut.conf.d/90-9000-dracut.rules

    cp $UNARCHIVE_DIR/poweroff-guard.service /usr/lib/systemd/system/poweroff-guard.service
    systemctl enable poweroff-guard.service   
    cp $UNARCHIVE_DIR/start-poweroff-guard.service /usr/lib/systemd/system/start-poweroff-guard.service
    systemctl enable start-poweroff-guard.service

    mkdir -p /usr/lib/systemd/system/tsg-clixon-backend.service.d
    cp $UNARCHIVE_DIR/service_add_prestart.conf /usr/lib/systemd/system/tsg-clixon-backend.service.d/service_add_prestart.conf

    mkdir -p /opt/tsg/clixon/yang
    cp /opt/tsg/clixon/deviation/tsg-os-mgnt-augment-9000-NPB.yang /opt/tsg/clixon/yang/tsg-os-mgnt-augment-9000-NPB.yang
}

function set_HAL_config()
{
    HAL_config="/etc/sysconfig/tsg-os-HAL.conf"

    # mrzcpd affinity cpu core
    sed -i '/IOCORE=/c\IOCORE=1-4' $HAL_config
    # vsys   affinity cpu core
    sed -i '/WORKLOAD_CORE=/c\WORKLOAD_CORE=5-55' $HAL_config
    # deafault memory hugepages number.
    sed -i '/HUGEPAGES=/c\HUGEPAGES=16' $HAL_config
    # sz_direct_pktmbuf=1048575
    sed -i '/MRZCPD_DIRECT_PKTMBUF=/c\MRZCPD_DIRECT_PKTMBUF=1048575' $HAL_config
    # sz_data=12800
    sed -i '/MRZCPD_SZ_DATA=/c\MRZCPD_SZ_DATA=12800' $HAL_config
    # create_mode=3
    sed -i '/MRZCPD_CREATE_MODE=/c\MRZCPD_CREATE_MODE=3' $HAL_config
}

function clean_unarchive_dir()
{
    rm -rf $UNARCHIVE_DIR
}

unarchive_patch_tgz
install_patch_files
set_HAL_config
clean_unarchive_dir

exit 0

__PAYLOAD_BELOW__
