#!/bin/bash

PCI_ADDRESS=$1

# Find network interface name associated with the given PCI address
NET_INTERFACE=$(basename /sys/bus/pci/devices/${PCI_ADDRESS}/net/*)

# Enable dropless_rq feature
/sbin/ethtool --set-priv-flags ${NET_INTERFACE} dropless_rq on
