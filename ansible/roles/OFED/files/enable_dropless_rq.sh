#!/bin/bash

PCI_ADDRESS=$1

# Find network interface name associated with the given PCI address
NET_INTERFACE=$(basename /sys/bus/pci/devices/${PCI_ADDRESS}/net/*)

# Enable dropless_rq feature
# /sbin/ethtool --set-priv-flags ${NET_INTERFACE} dropless_rq on

# Disable flow control
/sbin/ethtool -A ${NET_INTERFACE} rx off tx off

# Change PCI MaxReadReq to 1024B 
current_value=$(/usr/sbin/setpci -s ${PCI_ADDRESS} 68.w)

# Modify the last three characters while preserving the first one
new_value="3${current_value:1}"

# Set the new value
/usr/sbin/setpci -s ${PCI_ADDRESS} 68.w=$new_value

echo "Updated ${PCI_ADDRESS} to $new_value"
