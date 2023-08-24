{{- define "mrzcpd.mount.hostpath" -}}
{{- if eq .Values.mrzcpd.debug.enable_mount_host_filesystem  .Values.define_enable_val_yes }}
        - name: host-root
          mountPath: /host
{{- end }}
{{- end -}}

{{- define "mrzcpd.volume.hostpath" -}}
      - name: host-root
        hostPath:
          path: /
{{- end -}}

{{- define "mrzcpd.mount.localtime" -}}
        - name: localtime-node
          mountPath: /etc/localtime
          readOnly: true
{{- end -}}

{{- define "mrzcpd.volume.localtime" -}}
      - name: localtime-node
        hostPath:
          path: /etc/localtime
{{- end -}}

{{- define "mrzcpd.resources" -}}
{{- if .Values.mrzcpd.interfaces }}
{{- range $interface := .Values.mrzcpd.interfaces }}
            mrzcpd/{{ $interface.name }}: 1
{{- end }}
{{- end }}
{{- end -}}

{{- define "mrzcpd.start" -}}
{{- if eq .Values.mrzcpd.debug.enable_interactive_startup .Values.define_enable_val_yes -}}
            while true; do sleep 10;done
{{- else -}}
           /opt/tsg/mrzcpd/bin/mrzcpd -c /opt/tsg/mrzcpd/etc/mrglobal.conf
{{- end }}
{{- end -}}

{{- define "mrzcpd.volume.prestart" -}}
{{- if eq .Values.mrzcpd.debug.enable_prestart_script  .Values.define_enable_val_yes }}
      - name: mrzcpd-prestart
        hostPath:
{{- if .Values.mrzcpd.debug.prestart_script }}
          path: {{ .Values.mrzcpd.debug.prestart_script }}
{{- else }}
          path: /etc/tsg-os/{{ .Release.Name }}/packet_io_engine_prestart_script.sh
{{- end }}
          type: FileOrCreate
{{- end }}
{{- end -}}

{{- define "mrzcpd.mount.prestart" -}}
{{- if eq .Values.mrzcpd.debug.enable_prestart_script  .Values.define_enable_val_yes }}
        - name: prestart-dir
          mountPath: /tmp/prestart
        - name: mrzcpd-prestart
          mountPath: /opt/tsg/scripts/prestart.sh
{{- end }}
{{- end -}}

{{- define "mrzcpd.prestart" -}}
{{- if eq .Values.mrzcpd.debug.enable_prestart_script  .Values.define_enable_val_yes }}
            chmod 0755 /opt/tsg/scripts/prestart.sh
            /opt/tsg/scripts/prestart.sh
{{- end }}
{{- end -}}



{{- define "mrzcpd.config" -}}
{{- $nf_nic_list := "" }}
{{- $mirr_nic_list := "" }}
{{- $endpoint_nic_list := "" }}
{{- $sid_step := 4 }}
{{- $cycle := 16 }}
{{- $enter := "\n"}}

{{- range $index, $_ := until $cycle }}
{{- if eq $index 0 }}
{{- $nf_nic_list = (printf "nf_%d_fw"  $index) }}
{{- $nf_nic_list = (printf "%s,nf_%d_proxy" $nf_nic_list $index) }}
{{- $nf_nic_list = (printf "%s,nf_%d_sce" $nf_nic_list $index) }}
{{- $nf_nic_list = (printf "%s,nf_%d_shaping_engine" $nf_nic_list $index) }}
{{- $endpoint_nic_list = (printf "endpoint_%d_sce"  $index) }}
{{- $mirr_nic_list = (printf "mirr_%d_fw"  $index) }}
{{- $mirr_nic_list = (printf "%s,mirr_%d_proxy" $mirr_nic_list $index) }}
{{- else }}
{{- $nf_nic_list = (printf "%s,nf_%d_fw" $nf_nic_list $index) }}
{{- $nf_nic_list = (printf "%s,nf_%d_proxy" $nf_nic_list $index) }}
{{- $nf_nic_list = (printf "%s,nf_%d_sce" $nf_nic_list $index) }}
{{- $nf_nic_list = (printf "%s,nf_%d_shaping_engine" $nf_nic_list $index) }}
{{- $endpoint_nic_list = (printf "%s,endpoint_%d_sce" $endpoint_nic_list $index) }}
{{- $mirr_nic_list = (printf "%s,mirr_%d_fw" $mirr_nic_list $index) }}
{{- $mirr_nic_list = (printf "%s,mirr_%d_proxy" $mirr_nic_list $index) }}
{{- end }}

{{- end }}

[device]
{{- if .Values.mrzcpd.interfaces }}
device= {{- range $interface := .Values.mrzcpd.interfaces }}{{ $interface.name }},{{- end }}{{ $nf_nic_list }},{{ $endpoint_nic_list }},{{ $mirr_nic_list }},nf_inject,virtio_dign_c,virtio_dign_s
{{- else }}
device= {{ $nf_nic_list }},{{ $endpoint_nic_list}},{{ $mirr_nic_list}},nf_inject,virtio_dign_c,virtio_dign_s
{{- end }}
sz_tunnel=8192
sz_buffer=0

{{- range $interface := .Values.mrzcpd.interfaces }}
[device:{{ $interface.name }}]
{{- if $interface.address }}
in_addr={{ $interface.address }}
in_mask={{ $interface.mask }}
{{- if $interface.gateway }}
gateway={{ $interface.gateway }}
{{- end }}
{{- end }}
nr_rxdesc=8192
nr_txdesc=8192
allmulticast=1
rssmode=3
promisc={{ $interface.promisc }}
mtu={{ $interface.mtu }}
driver=0
role={{ $interface.role }}
{{- if $interface.type }}
type={{ $interface.type }}
{{- end }}
{{- if $interface.bond_mode }}
mode={{ $interface.bond_mode }}
{{- end }}
{{- if $interface.bond_xmit_policy }}
xmit_policy={{ $interface.bond_xmit_policy }}
{{- end }}
{{- if $interface.slaves }}
slaves={{- range $slave := $interface.slaves }}{{ $slave.interface }}{{- end }}
{{- end }}
{{- if $interface.rxcore }}
rx_cores={{ $interface.rxcore }}
{{- end }}
{{$enter}}
{{- end }}

[device:virtio_dign_c]
driver=1
role=1

[device:virtio_dign_s]
driver=1
role=1

[device:nf_inject]
driver=3
role=4

{{- range $index, $_ := until $cycle }}
[device:nf_{{ $index }}_fw]
driver=3
role=4

[device:nf_{{ $index }}_sce]
driver=3
role=4

[device:endpoint_{{ $index }}_sce]
en_representor=1
representor_ns=1
driver=3
role=4

[device:nf_{{ $index }}_shaping_engine]
driver=3
role=4

[device:nf_{{ $index }}_proxy]
driver=3
role=4

[device:mirr_{{ $index }}_fw]
driver=3
role=4

[device:mirr_{{ $index }}_proxy]
driver=3
role=4
{{$enter}}
{{- end }}

[service]
iocore=1,2,3,4
distmode={{ .Values.mrzcpd.distmode }}
hashmode=0
poll_wait_throttle=512
poll_wait_enable=1

[eal]
virtaddr=0x500000000000
loglevel=7
huge-dir=/run/mrzcpd/hugepages

[keepalive]
check_spinlock=1

[ctrlzone]
ctrlzone0=tunnat,64

[pool]
create_mode=1
sz_direct_pktmbuf=2097152
sz_indirect_pktmbuf=8192
sz_cache=512
sz_data=4096

[buffer_leak_detect]
check_buffer_leak=1

[ctrlmsg]
listen_addr=0.0.0.0
listen_port=46789

[rpc]
addr=127.0.0.1
port=56789

# sid
[etherfabric_adapters]
sid_range_start=100
sid_range_end=200
max_rules=256

[vwires]
sid_range_start=300
sid_range_end=400
max_rules=256

[service_lb]
sid_range_start={{ .Values.mrzcpd.service_lb.sid_range_start }}
sid_range_end={{ .Values.mrzcpd.service_lb.sid_range_end }}

{{- range $service := .Values.mrzcpd.services }}
[etherfabric_adapter:{{ $service.id }}]
mode={{ $service.mode }}
listen_device={{ $service.listen_on_device }}
{{$enter}}

{{- end }}

# health check
{{- range $index, $_ := until $cycle }}
[health_check:{{ $index | mul $sid_step }}]
name=nf{{ $index }}_fw_health_check
device=nf_{{ $index }}_fw
method=private
multiplier=20
interval=10

[health_check:{{ $index | mul $sid_step | add 1 }}]
name=nf{{ $index }}_proxy_health_check
device=nf_{{ $index }}_proxy
method=private
multiplier=20
interval=10

[health_check:{{ $index | mul $sid_step | add 2 }}]
name=nf{{ $index }}_sce_health_check
device=nf_{{ $index }}_sce
method=private
multiplier=20
interval=10

[health_check:{{ $index | mul $sid_step | add 3 }}]
name=nf{{ $index }}_shaping_engine_health_check
device=nf_{{ $index }}_shaping_engine
method=private
multiplier=20
interval=10
{{$enter}}
{{- end }}
[health_check:{{ $cycle | mul $sid_step }}]
name=nf_inject_health_check
device=nf_inject
method=private
multiplier=20
interval=10

# load balance
{{- range $index, $_ := until $cycle }}
[load_balance:{{ $index | mul $sid_step }}]
mode=balance
devices=nf_{{ $index }}_fw,normal
health_check_sessions=nf{{ $index }}_fw_health_check

[load_balance:{{ $index | mul $sid_step | add 1 }}]
mode=balance
devices=nf_{{ $index }}_proxy,normal
health_check_sessions=nf{{ $index }}_proxy_health_check

[load_balance:{{ $index | mul $sid_step | add 2 }}]
mode=balance
devices=nf_{{ $index }}_sce,normal
health_check_sessions=nf{{ $index }}_sce_health_check

[load_balance:{{ $index | mul $sid_step | add 3 }}]
mode=balance
devices=nf_{{ $index }}_shaping_engine,normal
health_check_sessions=nf{{ $index }}_shaping_engine_health_check
{{$enter}}
{{- end }}
[load_balance:{{ $cycle | mul $sid_step }}]
mode=balance
devices=nf_inject,normal
health_check_sessions=nf_inject_health_check

# vwire
[vwire:0]
interface_int=virtio_dign_c
interface_ext=virtio_dign_s

{{- range $virtual_wire := .Values.mrzcpd.virtual_wires }}
[vwire:{{ $virtual_wire.id }}]
interface_int={{ $virtual_wire.internal_interface }}
interface_ext={{ $virtual_wire.external_interface }}
{{$enter}}
{{- end }}
# classifier rule
# dst ip
{{- range $index, $_ := until $cycle }}
[classifier_rule:{{ $index }}]
rule_id={{ $index | add 1 }}
dst_ip_addr_v4=192.0.2.{{ $index | add 101 }}
dst_ip_mask_v4=32
action=nf_steering
priority=1
category=0
sid={{ $index | mul $sid_step | add 1000 }}
vwire_id=0
{{$enter}}
{{- end }}
# src ip
{{- range $index, $_ := until $cycle }}
[classifier_rule:{{ $index | add $cycle }}]
rule_id={{ $index | add $cycle | add 1 }}
src_ip_addr_v4=192.0.2.{{ $index | add 101 }}
src_ip_mask_v4=32
action=nf_steering
priority=1
category=0
sid={{ $index | mul $sid_step | add 1000 }}
vwire_id=0
{{$enter}}
{{- end }}
# bridge
[bridge:0]
{{- if .Values.mrzcpd.service_chaining_vxlan_g.interface  }}
master_device={{ .Values.mrzcpd.service_chaining_vxlan_g.interface }}
devices={{ .Values.mrzcpd.service_chaining_vxlan_g.interface }},{{ $endpoint_nic_list}}
{{- else }}
devices={{ $endpoint_nic_list}}
{{- end }}

# bridge
[bridge:1]
{{- if .Values.mrzcpd.traffic_mirror.interface  }}
master_device={{ .Values.mrzcpd.traffic_mirror.interface }}
devices={{ .Values.mrzcpd.traffic_mirror.interface }},{{ $mirr_nic_list}}
{{- else }}
devices={{ $mirr_nic_list}}

{{- end -}}
{{- end -}}
