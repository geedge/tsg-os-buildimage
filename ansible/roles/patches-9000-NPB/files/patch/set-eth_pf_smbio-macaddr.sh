#!/bin/sh
NIC_NAME="eth_pf_smbio"
echo --------------------  set $NIC_NAME macaddr  --------------------

output=$(ipmitool picmg addrinfo)
echo $output
substr=${output:21:2}
echo deviceid:$substr
macaddr='90:00:00:91:40:'$substr
echo $NIC_NAME macaddr:$macaddr
ip link set dev $NIC_NAME address $macaddr