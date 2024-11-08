#!/bin/sh
INTERFACE="$1"
ACTION="$2"
SLOT_ID=

read_slot_id()
{
    output=$(ipmitool picmg addrinfo)
    echo $output
    substr=${output:22:1}
    echo $substr
    SLOT_ID=$((16#${substr}+16))
}

if [[ $INTERFACE == "eth_pf_mgmt0" ]] && [[ $ACTION == "pre-up" ]]
then
    logger "NetworkManager Dispather Scripts: $0, Interface: $INTERFACE, action: $ACTION"
    read_slot_id
    ipaddr='10.254.'$SLOT_ID'.1'
    ifconfig eth_pf_mgmt0 $ipaddr netmask 255.255.0.0
fi

if [[ $INTERFACE == "eth_pf_mgmt1" ]] && [[ $ACTION == "pre-up" ]]
then
    logger "NetworkManager Dispather Scripts: $0, Interface: $INTERFACE, action: $ACTION"
    read_slot_id
    ipaddr='10.253.'$SLOT_ID'.1'
    ifconfig eth_pf_mgmt1 $ipaddr netmask 255.255.0.0
fi