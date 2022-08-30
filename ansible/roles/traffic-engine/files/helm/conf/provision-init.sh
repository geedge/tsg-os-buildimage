#!/bin/bash -ex

mkdir -p /target_config/opt/tsg/etc
mkdir -p /target_config/etc/default
chmod 0755 /opt/tsg/tsg-os-provision/scripts/obtain_sn.sh
/opt/tsg/tsg-os-provision/scripts/obtain_sn.sh
ip tuntap add mode tap ctrl_mock
ifconfig ctrl_mock up
ifconfig ctrl_mock $NODE_IP/32
ifconfig ctrl_mock mtu 2000
{{ if eq .Values.proxy.enable .Values.define_enable_val_yes }}
ip tuntap add dev tap0 mode tap multi_queue
/opt/tsg/tfe/tfe-env-start.sh
{{- end }}
mount -o remount,rw /sys