#!/bin/bash -ex

mkdir -p /target_config/opt/tsg/etc
mkdir -p /target_config/etc/default
chmod 0755 /opt/tsg/tsg-os-provision/scripts/obtain_sn.sh
/opt/tsg/tsg-os-provision/scripts/obtain_sn.sh
{{ if eq .Values.proxy.enable .Values.define_enable_val_yes }}
ip tuntap add dev tap0 mode tap multi_queue
/opt/tsg/tfe/tfe-env-start.sh
{{- end }}
mount -o remount,rw /sys