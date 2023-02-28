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

ip tuntap add dev {{ .Values.sce.endpoint_nic }} mode tap
ip link set dev {{ .Values.sce.endpoint_nic }} up
ip route add {{ .Values.sce.endpoint_netip }}/{{ .Values.sce.endpoint_mask }} dev {{ .Values.sce.endpoint_nic }} table 10
{{ if .Values.sce.endpoint_gateway }}
ip route add default via {{ .Values.sce.endpoint_gateway }} table 10
{{- end }}
ip a a {{ .Values.sce.endpoint_ip }}/{{ .Values.sce.endpoint_mask }} dev {{ .Values.sce.endpoint_nic }} noprefixroute
ip rule add dport 3784 table 10
