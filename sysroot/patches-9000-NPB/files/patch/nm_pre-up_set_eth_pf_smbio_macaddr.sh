#!/bin/sh
INTERFACE="$1"
ACTION="$2"
MAC_6TH_OCTET=

read_mac_6th_octet()
{
    output=$(ipmitool picmg addrinfo)
    MAC_6TH_OCTET=${output:21:2}
}

if [[ $INTERFACE == "eth_pf_smbio" ]] && [[ $ACTION == "pre-up" ]]
then
    logger "NetworkManager Dispather Scripts: $0, Interface: $INTERFACE, action: $ACTION"
    read_mac_6th_octet
    macaddr="90:00:00:91:40:$MAC_6TH_OCTET"
    ip link set eth_pf_smbio address $macaddr
fi
