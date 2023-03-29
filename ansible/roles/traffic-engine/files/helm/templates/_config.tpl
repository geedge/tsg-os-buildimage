{{- define "traffic-engine.config.olap-address" -}}
{{- $kafka_brokers := list -}}
{{- $separtor := index . 1  -}}
{{- with index . 0 }}
{{- range .Values.external_resources.olap.kafka_brokers.addresses -}}
{{- $broker_address := ( print .address  ":"  .port ) -}}
{{- $kafka_brokers = append $kafka_brokers $broker_address -}}
{{- end -}}
{{- end }}
{{- join $separtor $kafka_brokers }}
{{- end -}}

{{- define "traffic-engine.coredump" -}}
{{- if eq .Values.coredump.format "none" }}
disable_coredump=1
enable_breakpad=0
enable_breakpad_upload=0
{{ end }}
{{- if eq .Values.coredump.format "core" }}
disable_coredump=0
enable_breakpad=0
enable_breakpad_upload=0
{{ end }}
{{- if eq .Values.coredump.format "minidump" }}
disable_coredump=1
enable_breakpad=1
{{- if eq .Values.coredump.collect "sentry" }}
enable_breakpad_upload=1
breakpad_upload_url={{ .Values.coredump.sentry_url }}
{{ end }}
{{- if eq .Values.coredump.collect "local" }}
enable_breakpad_upload=0
{{ end }}
{{ end }}
{{- end -}}

{{- define "traffic-engine.tfe.workerthread" -}}
{{- if eq (len .Values.tfe_affinity) 1 }}
{{- 1 }}
{{- else }}
{{- sub (len .Values.tfe_affinity) 1 }}
{{- end }}
{{- end -}}

{{- define "traffic-engine.sce.workerthread" -}}
{{- len .Values.sce_affinity }}
{{- end -}}

{{- define "traffic-engine.shaping.workerthread" -}}
{{- len .Values.shaping_affinity }}
{{- end -}}

{{- define "traffic-engine.tfe.cpu-affinity" -}}
{{- if eq (len .Values.tfe_affinity) 1 }}
{{- print (index .Values.tfe_affinity 0) "," (index .Values.tfe_affinity 0) }}
{{- else }}
{{- join "," .Values.tfe_affinity }}
{{- end }}
{{- end -}}

{{- define "traffic-engine.sce.cpu-affinity" -}}
{{- join "," .Values.sce_affinity }}
{{- end -}}

{{- define "traffic-engine.shaping.cpu-affinity" -}}
{{- join "," .Values.shaping_affinity }}
{{- end -}}

{{- define "traffic-engine.device-tag-list" -}}
{{- $tags_list := list -}}
{{- if .Values.device.tags }}
{{- range .Values.device.tags -}}
{{- range $key,$val := . }}
{{- $tag_json := ( print "{\"tag\":\""  $key  "\",\"value\":\""  $val  "\"}") -}}
{{- $tags_list = append $tags_list $tag_json -}}
{{- end }}
{{- end }}
{{- end }}
{{- join "," $tags_list }}
{{- end -}}

{{- define "traffic-engine.sapp.workerthread" -}}
{{ len .Values.sapp_affinity }}
{{- end -}}

{{- define "traffic-engine.sapp.cpu-affinity" -}}
{{ join "," .Values.sapp_affinity }}
{{- end -}}


{{- define "traffic-engine.config.hos-address" -}}
{{- $address_dict := index .Values.external_resources.olap.hos_servers.addresses 0 -}}
{{- $address_dict.address }}
{{- end -}}

{{- define "traffic-engine.config.hos-port" -}}
{{- $address_dict := index .Values.external_resources.olap.hos_servers.addresses 0 -}}
{{- $address_dict.port }}
{{- end -}}

{{- define "traffic-engine.config.identify-proto-name" -}}
{{- $proto_name := "" -}}
{{- $val_yes := .Values.define_enable_val_yes }}
{{- range $key, $val := .Values.decoders }}
{{- if eq $val $val_yes }}
{{- $proto_name = print $proto_name $key ";" }}
{{- end }}
{{- end }}
{{- $proto_name }}
{{- end -}}

{{- define "traffic-engine.merge-exporter.merge-urls" -}}
{{- if and (eq .Values.proxy.enable .Values.define_enable_val_yes) (ge (len .Values.tfe_affinity) 1) }}
{{- print "value: http://localhost:9273/metrics http://localhost:9001/metrics http://localhost:9002/metrics http://localhost:9006/metrics" }}
{{- else }}
{{- print "value: http://localhost:9273/metrics http://localhost:9002/metrics http://localhost:9006/metrics" }}
{{- end }}
{{- end -}}

{{- define "traffic-engine.sce.copy-config-to-dest" -}}
            cp /opt/tsg/config/sce.conf  /opt/tsg/sce/conf
            cp /opt/tsg/config/tsg_device_tag.json  /opt/tsg/etc/tsg_device_tag.json
{{- end -}}

{{- define "traffic-engine.sce.prestart" -}}
            if [ -f "/etc/traffic-engine/hotfix/sce/scripts/prestart.sh" ]; then chmod 0755 /etc/traffic-engine/hotfix/sce/scripts/prestart.sh; /etc/traffic-engine/hotfix/sce/scripts/prestart.sh;fi
{{- end -}}


{{- define "traffic-engine.bfdd.prestart" -}}
            if [ -f "/etc/traffic-engine/hotfix/bfdd/scripts/prestart.sh" ]; then chmod 0755 /etc/traffic-engine/hotfix/bfdd/scripts/prestart.sh; /etc/traffic-engine/hotfix/bfdd/scripts/prestart.sh;fi
{{- end -}}

{{- define "traffic-engine.firewall.copy-config-to-dest" -}}
            cp /opt/tsg/config/conflist.inf            /opt/tsg/sapp/plug/conflist.inf
            cp /opt/tsg/config/gdev.conf               /opt/tsg/sapp/etc/gdev.conf
            cp /opt/tsg/config/main.conf               /opt/tsg/sapp/tsgconf/main.conf
            cp /opt/tsg/config/maat.conf               /opt/tsg/sapp/tsgconf/maat.conf
            cp /opt/tsg/config/sapp.toml               /opt/tsg/sapp/etc/sapp.toml
{{ if eq .Values.proxy.enable .Values.define_enable_val_yes }}
            cp /opt/tsg/config/kni.conf                /opt/tsg/sapp/etc/kni/kni.conf
{{- end }}
            cp /opt/tsg/config/wangw.conf              /opt/tsg/sapp/etc/wannat/wangw.conf
            cp /opt/tsg/config/wire_graft.conf         /opt/tsg/sapp/etc/wire_graft/wire_graft.conf
            cp /opt/tsg/config/tsg_conn_sketch.inf     /opt/tsg/sapp/plug/business/tsg_conn_sketch/tsg_conn_sketch.inf
            cp /opt/tsg/config/send_raw_pkt.conf       /opt/tsg/sapp/etc/send_raw_pkt.conf
            cp /opt/tsg/config/tsg_device_tag.json     /opt/tsg/etc/tsg_device_tag.json
            cp /opt/tsg/config/app_sketch_local.inf    /opt/tsg/sapp/plug/business/app_sketch_local/app_sketch_local.inf
            cp /opt/tsg/config/vlan_flipping_map.conf  /opt/tsg/sapp/etc/vlan_flipping_map.conf
            cp /opt/tsg/config/firewall.inf            /opt/tsg/sapp/plug/business/firewall/firewall.inf
            cp /opt/tsg/config/necessary_plug_list.conf  /opt/tsg/sapp/etc/necessary_plug_list.conf
{{- end -}}

{{- define "traffic-engine.firewall.prestart" -}}
            if [ -f "/etc/traffic-engine/hotfix/firewall/scripts/prestart.sh" ]; then chmod 0755 /etc/traffic-engine/hotfix/firewall/scripts/prestart.sh; /etc/traffic-engine/hotfix/firewall/scripts/prestart.sh;fi
{{- end -}}


{{- define "traffic-engine.proxy.copy-config-to-dest" -}}
            cp /opt/tsg/config/tfe.conf             /opt/tsg/tfe/conf/tfe/tfe.conf
            cp /opt/tsg/config/pangu_pxy.conf       /opt/tsg/tfe/conf/pangu/pangu_pxy.conf
            cp /opt/tsg/config/tsg_device_tag.json  /opt/tsg/etc/tsg_device_tag.json
{{- end -}}


{{- define "traffic-engine.proxy.prestart" -}}
            if [ -f "/etc/traffic-engine/hotfix/proxy/scripts/prestart.sh" ]; then chmod 0755 /etc/traffic-engine/hotfix/proxy/scripts/prestart.sh; /etc/traffic-engine/hotfix/proxy/scripts/prestart.sh;fi
{{- end -}}



{{- define "traffic-engine.certstore.copy-config-to-dest" -}}
            cp /opt/tsg/config/cert_store.ini       /opt/tsg/certstore/conf/cert_store.ini
            cp /opt/tsg/config/tsg_device_tag.json  /opt/tsg/etc/tsg_device_tag.json
{{- end -}}

{{- define "traffic-engine.certstore.prestart" -}}
            if [ -f "/etc/traffic-engine/hotfix/certstore/scripts/prestart.sh" ]; then chmod 0755 /etc/traffic-engine/hotfix/certstore/scripts/prestart.sh; /etc/traffic-engine/hotfix/certstore/scripts/prestart.sh;fi
{{- end -}}


{{- define "traffic-engine.init" -}}
            mkdir -p /target_config/opt/tsg/etc
            mkdir -p /target_config/etc/default
            chmod 0755 /opt/tsg/tsg-os-provision/scripts/obtain_sn.sh
            /opt/tsg/tsg-os-provision/scripts/obtain_sn.sh
{{ if eq .Values.proxy.enable .Values.define_enable_val_yes }}
            ip tuntap add dev tap0 mode tap multi_queue
            /usr/sbin/ip link set tap0 address fe:65:b7:03:50:bd
            /usr/sbin/ip link set tap0 up
            /usr/sbin/ip addr flush dev tap0
            /usr/sbin/ip addr add 172.16.241.2/30 dev tap0
            /usr/sbin/ip neigh flush dev tap0
            /usr/sbin/ip neigh add 172.16.241.1 lladdr 00:0e:c6:d6:72:c1 dev tap0 nud permanent
            /usr/sbin/ip6tables -A INPUT -i tap0 -m bpf --bytecode '17,48 0 0 0,84 0 0 240,21 0 13 96,48 0 0 6,21 0 11 6,40 0 0 4,37 0 9 24,48 0 0 52,84 0 0 240,116 0 0 2,53 0 5 24,48 0 0 60,21 0 3 88,48 0 0 61,21 0 1 4,6 0 0 65535,6 0 0 0' -j NFQUEUE --queue-num 1
            /usr/sbin/iptables -A INPUT -i tap0 -m bpf --bytecode '18,48 0 0 0,84 0 0 240,21 0 14 64,48 0 0 9,21 0 12 6,40 0 0 6,69 10 0 8191,177 0 0 0,80 0 0 12,84 0 0 240,116 0 0 2,53 0 5 24,80 0 0 20,21 0 3 88,80 0 0 21,21 0 1 4,6 0 0 65535,6 0 0 0' -j NFQUEUE --queue-num 1
            /usr/sbin/ip rule add iif tap0 tab 100
            /usr/sbin/ip route add local default dev lo table 100
            /usr/sbin/ip rule add fwmark 0x65 lookup 101
            /usr/sbin/ip route add default dev tap0 via 172.16.241.1 table 101
            /usr/sbin/ip addr add fd00::02/64 dev tap0
            /usr/sbin/ip -6 route add default via fd00::01
            /usr/sbin/ip -6 rule add iif tap0 tab 102
            /usr/sbin/ip -6 route add local default dev lo table 102
            /usr/sbin/ip -6 neigh add fd00::01 lladdr 00:0e:c6:d6:72:c1 dev tap0 nud permanent
{{- end }}
            mount -o remount,rw /sys
{{ if .Values.sce_config.endpoint_nic }}
            ip tuntap add dev {{ .Values.sce_config.endpoint_nic }} mode tap
            ip link set dev {{ .Values.sce_config.endpoint_nic }} up
            ip route add {{ .Values.sce_config.endpoint_netip }}/{{ .Values.sce_config.endpoint_mask }} dev {{ .Values.sce_config.endpoint_nic }} table 10
{{ if .Values.sce_config.endpoint_gateway }}
            ip route add default via {{ .Values.sce_config.endpoint_gateway }} table 10
{{- end }}
            ip a a {{ .Values.sce_config.endpoint_ip }}/{{ .Values.sce_config.endpoint_mask }} dev {{ .Values.sce_config.endpoint_nic }} noprefixroute
            ip rule add dport 3784 table 10
{{- end }}
{{- end -}}

{{/*
#tfe-env-stop.sh
#!/bin/bash -ex
/usr/sbin/ip6tables -D INPUT -i tap0 -m bpf --bytecode '17,48 0 0 0,84 0 0 240,21 0 13 96,48 0 0 6,21 0 11 6,40 0 0 4,37 0 9 24,48 0 0 52,84 0 0 240,116 0 0 2,53 0 5 24,48 0 0 60,21 0 3 88,48 0 0 61,21 0 1 4,6 0 0 65535,6 0 0 0' -j NFQUEUE --queue-num 1
/usr/sbin/iptables -D INPUT -i tap0 -m bpf --bytecode '18,48 0 0 0,84 0 0 240,21 0 14 64,48 0 0 9,21 0 12 6,40 0 0 6,69 10 0 8191,177 0 0 0,80 0 0 12,84 0 0 240,116 0 0 2,53 0 5 24,80 0 0 20,21 0 3 88,80 0 0 21,21 0 1 4,6 0 0 65535,6 0 0 0' -j NFQUEUE --queue-num 1
/usr/sbin/ip rule del iif tap0 tab 100
/usr/sbin/ip route del local default dev lo table 100
/usr/sbin/ip rule del fwmark 0x65 lookup 101
/usr/sbin/ip route del default dev tap0 via 172.16.241.1 table 101
/usr/sbin/ip -6 rule del iif tap0 tab 102
/usr/sbin/ip -6 route del default via fd00::01
/usr/sbin/ip -6 route del local default dev lo table 102
/usr/sbin/ip addr del fd00::02/64 dev tap0
/usr/sbin/ip link set tap0 down
*/}}


{{- define "traffic-engine.shaping.copy-config-to-dest" -}}
            cp /opt/tsg/config/shaping.conf  /opt/tsg/shaping_engine/conf
            cp /opt/tsg/config/tsg_device_tag.json  /opt/tsg/etc/tsg_device_tag.json
{{- end -}}

{{- define "traffic-engine.shaping.prestart" -}}
            if [ -f "/etc/traffic-engine/hotfix/shaping/scripts/prestart.sh" ]; then chmod 0755 /etc/traffic-engine/hotfix/shaping/scripts/prestart.sh; /etc/traffic-engine/hotfix/shaping/scripts/prestart.sh;fi
{{- end -}}

{{- define "traffic-engine.shaping.get-service-node-port" -}}
            export APISERVER=https://kubernetes.default.svc
            export SERVICEACCOUNT=/var/run/secrets/kubernetes.io/serviceaccount
            export NAMESPACE=$(cat ${SERVICEACCOUNT}/namespace)
            export TOKEN=$(cat ${SERVICEACCOUNT}/token)
            export CACERT=${SERVICEACCOUNT}/ca.crt
            curl --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -X GET ${APISERVER}/api/v1/namespaces/${NAMESPACE}/services/${SERVICENAME} -o /tmp/service.txt
            export CLUSTER_ANNOUNCE_PORT=$(cat /tmp/service.txt | jq '.spec.ports[] | select(.name=="cluster-announce-port") | .nodePort')
            export HEALTH_CHECK_ANNOUNCE_PORT=$(cat /tmp/service.txt | jq '.spec.ports[] | select(.name=="healthcheck-announce-port") | .nodePort')
            echo "export CLUSTER_ANNOUNCE_PORT=${CLUSTER_ANNOUNCE_PORT}" > /etc/profile.d/announceinfo.sh
            echo "export HEALTH_CHECK_ANNOUNCE_PORT=${HEALTH_CHECK_ANNOUNCE_PORT}" >> /etc/profile.d/announceinfo.sh
            chmod 0755 /etc/profile.d/announceinfo.sh
{{- end -}}

{{- define "traffic-engine.shaping.set-shaping-config" -}}
            sed -Ei "s|NODE_IP_LOCATION|${NODE_IP?}|g" /opt/tsg/shaping_engine/conf/shaping.conf 
            sed -Ei "s|CLUSTER_ANNOUNCE_PORT_LOCATION|${CLUSTER_ANNOUNCE_PORT?}|g" /opt/tsg/shaping_engine/conf/shaping.conf
            sed -Ei "s|HEALTH_CHECK_ANNOUNCE_PORT_LOCATION|${HEALTH_CHECK_ANNOUNCE_PORT?}|g" /opt/tsg/shaping_engine/conf/shaping.conf
{{- end -}}
