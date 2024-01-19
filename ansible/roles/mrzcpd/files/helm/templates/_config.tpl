
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
           exec /opt/tsg/mrzcpd/bin/mrzcpd -c /opt/tsg/mrzcpd/etc/mrglobal.conf -s /opt/tsg/mrzcpd/etc/mrglobal.dynamic.conf 2>&1|tee >(systemd-cat -t $DEPLOYMENT_NAME)
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
{{- $ef_adapter_num:= 0}}
{{- $tera_adapter_num:= 0}}
{{- $vwire_num:= 1}}
{{- $mirr_nic_list := "" }}
{{- $ep_nic_l2_list := "" }}
{{- $ep_nic_l3_list := "" }}
{{- $sid_step := 4 }}
{{- $cycle := int .Values.mrzcpd.nf_count }}
{{- $enter := "\n"}}

{{- range $index, $_ := until $cycle }}
{{- if eq $index 0 }}
{{- $nf_nic_list = (printf "nf_%d_fw"  $index) }}
{{- $nf_nic_list = (printf "%s,nf_%d_proxy" $nf_nic_list $index) }}
{{- $nf_nic_list = (printf "%s,nf_%d_sce" $nf_nic_list $index) }}
{{- $nf_nic_list = (printf "%s,nf_%d_shaping_engine" $nf_nic_list $index) }}
{{- $ep_nic_l2_list = (printf "ep_%d_sce_l2"  $index) }}
{{- $ep_nic_l3_list = (printf "ep_%d_sce_l3"  $index) }}
{{- $mirr_nic_list = (printf "mirr_%d_fw"  $index) }}
{{- $mirr_nic_list = (printf "%s,mirr_%d_proxy" $mirr_nic_list $index) }}
{{- else }}
{{- $nf_nic_list = (printf "%s,nf_%d_fw" $nf_nic_list $index) }}
{{- $nf_nic_list = (printf "%s,nf_%d_proxy" $nf_nic_list $index) }}
{{- $nf_nic_list = (printf "%s,nf_%d_sce" $nf_nic_list $index) }}
{{- $nf_nic_list = (printf "%s,nf_%d_shaping_engine" $nf_nic_list $index) }}
{{- $ep_nic_l2_list = (printf "%s,ep_%d_sce_l2" $ep_nic_l2_list $index) }}
{{- $ep_nic_l3_list = (printf "%s,ep_%d_sce_l3" $ep_nic_l3_list $index) }}
{{- $mirr_nic_list = (printf "%s,mirr_%d_fw" $mirr_nic_list $index) }}
{{- $mirr_nic_list = (printf "%s,mirr_%d_proxy" $mirr_nic_list $index) }}
{{- end }}

{{- end -}}

[device]
{{- if .Values.mrzcpd.interfaces }}
device= {{- range $interface := .Values.mrzcpd.interfaces }}{{ $interface.name }},{{- end }}{{- range $interface := .Values.mrzcpd.virtual_interfaces }}{{ $interface.name }},{{- end }}{{ $nf_nic_list }},{{ $ep_nic_l2_list }},{{ $ep_nic_l3_list }},{{ $mirr_nic_list }},nf_inject,virtio_dign_c,virtio_dign_s
{{- else }}
device= {{ $nf_nic_list }},{{ $ep_nic_l2_list}},{{ $ep_nic_l3_list }},{{ $mirr_nic_list}},nf_inject,virtio_dign_c,virtio_dign_s
{{- end }}
sz_tunnel=8192
sz_buffer=0

{{ range $interface := .Values.mrzcpd.interfaces }}
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
{{- if eq $interface.role "5"}}
driver=1
{{- else}}
driver=0
{{- end}}
role={{ $interface.role }}
{{- if $interface.type }}
type={{ $interface.type }}
{{- end }}
{{- if $interface.vlan }}
{{- if ne (len $interface.vlan) 0}}
allow_vlan_ids={{- range $index,$vlan := $interface.vlan }}{{- if ne $index 0 }},{{ end -}}{{ $vlan.vlan_id }}{{- end }}
{{- end }}
{{- end }}
{{- if $interface.en_representor }}
en_representor={{ $interface.en_representor }}
{{- end }}
{{- if $interface.representor_ns }}
representor_ns={{ $interface.representor_ns }}
{{- end }}
{{- if $interface.representor_dev }}
representor_dev={{ $interface.representor_dev }}
{{- end }}
{{$enter}}
{{- if $interface.vlan }}
{{- range $vlan := $interface.vlan }}
[device:{{$interface.name}}:vlan:{{$vlan.vlan_id}}]
{{- if $vlan.ipv4_address }}
in_addr_v4={{ $vlan.ipv4_address }}
{{- end }}
{{- if $vlan.ipv4_mask }}
in_mask_v4={{ $vlan.ipv4_mask }}
{{- end }}
{{- if $vlan.ipv6_address }}
in_addr_v6={{ $vlan.ipv6_address }}
{{- end }}
{{- if $vlan.ipv6_mask }}
in_mask_v6={{ $vlan.ipv6_mask }}
{{- end }}
{{$enter}}
{{- end }}
{{- end }}
{{- end }}

{{- range $interface := .Values.mrzcpd.virtual_interfaces }}
[device:{{ $interface.name }}]
{{- if $interface.promisc }}
promisc={{ $interface.promisc }}
{{- end}}
{{- if $interface.mtu }}
mtu={{ $interface.mtu }}
{{- end}}
{{- if eq $interface.role "5"}}
driver=1
{{- else}}
driver=0
{{- end}}
role={{ $interface.role }}
{{- if $interface.type }}
type={{ $interface.type }}
{{- end }}
{{- if $interface.bond_mode }}
bond_mode={{ $interface.bond_mode }}
{{- end }}
{{- if $interface.bond_xmit_policy }}
bond_xmit_policy={{ $interface.bond_xmit_policy }}
{{- end }}
{{- if $interface.slaves }}
bond_slaves={{- range $index,$slave := $interface.slaves }}{{- if ne $index 0 }},{{ end -}}{{ $slave.interface }}{{- end }}
{{- end }}
{{- if $interface.rxcore }}
rx_cores={{ $interface.rxcore }}
{{- end }}
{{- if $interface.vlan }}
{{- if ne (len $interface.vlan) 0}}
allow_vlan_ids={{- range $index,$vlan := $interface.vlan }}{{- if ne $index 0 }},{{ end -}}{{ $vlan.vlan_id }}{{- end }}
{{- end }}
{{- end }}
{{- if $interface.en_representor }}
en_representor={{ $interface.en_representor }}
{{- end }}
{{- if $interface.representor_ns }}
representor_ns={{ $interface.representor_ns }}
{{- end }}
{{$enter}}
{{- if $interface.vlan }}
{{- range $vlan := $interface.vlan }}
[device:{{$interface.name}}:vlan:{{$vlan.vlan_id}}]
{{- if $vlan.ipv4_address }}
in_addr_v4={{ $vlan.ipv4_address }}
{{- end }}
{{- if $vlan.ipv4_mask }}
in_mask_v4={{ $vlan.ipv4_mask }}
{{- end }}
{{- if $vlan.ipv6_address }}
in_addr_v6={{ $vlan.ipv6_address }}
{{- end }}
{{- if $vlan.ipv6_mask }}
in_mask_v6={{ $vlan.ipv6_mask }}
{{- end }}
{{$enter}}
{{- end }}
{{- end }}
{{- end }}

[device:virtio_dign_c]
driver=1
role=1
{{$enter}}
[device:virtio_dign_s]
driver=1
role=1
{{$enter}}
[device:nf_inject]
driver=3
role=4
{{$enter}}
{{- range $linkdb := .Values.mrzcpd.linkdb }}
[link_db:{{ $linkdb.id }}]
type={{ $linkdb.type }}
traffic_link_id={{ $linkdb.traffic_link_id}}
{{- if $linkdb.vwire_id }}
vwire_id={{ $linkdb.vwire_id }}
{{- end }}
{{- if and $linkdb.ef_ip_addr $linkdb.ef_link_id  }}
ef_ip_addr={{ $linkdb.ef_ip_addr }}
ef_link_id={{ $linkdb.ef_link_id }}
{{- end }}
{{$enter}}
{{- end }}


{{- range $index, $_ := until $cycle }}
[device:nf_{{ $index }}_fw]
driver=3
role=4

[device:nf_{{ $index }}_sce]
driver=3
role=4

[device:ep_{{ $index }}_sce_l2]
driver=3
role=4

[device:ep_{{ $index }}_sce_l3]
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

[limits]
nr_max_ef_adapters={{ .Values.mrzcpd.nr_max_ef_adapters }}
nr_max_vwires={{ .Values.mrzcpd.nr_max_vwires }}
nr_max_tera_adapters={{ .Values.mrzcpd.nr_max_tera_adapters }}
nr_max_link_dbs={{ .Values.mrzcpd.nr_max_link_dbs }}

# sid
[ef_adapters]
sid_start=100
sid_end=200
max_rules=32

[vwires]
sid_start=300
sid_end=400
max_rules=32

[tera_adapters]
sid_start=500
sid_end=600
max_rules=64

[service_lb]
sid_start={{ .Values.mrzcpd.service_lb.sid_range_start }}
sid_end={{ .Values.mrzcpd.service_lb.sid_range_end }}
{{- range $service := .Values.mrzcpd.services }}
{{- if eq $service.type "etherfabric_adapter"}}

[ef_adapter:{{ $ef_adapter_num }}]
ef_adapter_id={{ $service.id }}
mode={{ $service.mode }}
listen_device={{ $service.listen_on_device }}
{{- $ef_adapter_num = ($ef_adapter_num | add 1)}}
{{- else }}

[tera_adapter:{{ $tera_adapter_num }}]
tera_adapter_id={{ $service.id }}
listen_device={{ $service.listen_on_device }}
vlan_int={{ $service.vlan_int }}
vlan_ext={{ $service.vlan_ext }}
mac_flipping={{ $service.mac_flipping }}
{{- $tera_adapter_num = ($tera_adapter_num | add 1)}}
{{- end}}
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
vwire_id=0
interface_int=virtio_dign_c
interface_ext=virtio_dign_s

{{- range $virtual_wire := .Values.mrzcpd.virtual_wires }}
[vwire:{{ $vwire_num }}]
vwire_id={{ $virtual_wire.id }}
interface_int={{ $virtual_wire.internal_interface }}
interface_ext={{ $virtual_wire.external_interface }}
{{- if $virtual_wire.obp_device }}
obp_device={{ $virtual_wire.obp_device }}
{{- end }}
{{- if $virtual_wire.obp_segment }}
obp_segment={{ $virtual_wire.obp_segment }}
{{- end }}
{{- $vwire_num = ($vwire_num | add 1)}}
{{$enter}}
{{- end }}

# bridge
[bridge:0]
{{- if .Values.mrzcpd.service_chaining.vxlan_interface  }}
master_device={{ .Values.mrzcpd.service_chaining.vxlan_interface }}
devices={{ .Values.mrzcpd.service_chaining.vxlan_interface }},{{ $ep_nic_l3_list}}
{{- else }}
devices={{ $ep_nic_l3_list}}
{{- end }}

# bridge
[bridge:1]
{{- if .Values.mrzcpd.traffic_mirror.interface  }}
master_device={{ .Values.mrzcpd.traffic_mirror.interface }}
devices={{ .Values.mrzcpd.traffic_mirror.interface }},{{ $mirr_nic_list}}
{{- else }}
devices={{ $mirr_nic_list}}
{{- end -}}
{{$enter}}

# bridge
[bridge:2]
{{- if .Values.mrzcpd.service_chaining.vlan_interface  }}
master_device={{ .Values.mrzcpd.service_chaining.vlan_interface }}
devices={{ .Values.mrzcpd.service_chaining.vlan_interface }},{{ $ep_nic_l2_list}}
{{- else }}
devices={{ $ep_nic_l2_list}}
{{- end }}

{{- end -}}
