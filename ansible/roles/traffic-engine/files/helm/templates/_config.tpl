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

{{- define "traffic-engine.inject_adapter.workerthread" -}}
{{- len .Values.inject_adapter_affinity }}
{{- end -}}

{{- define "traffic-engine.pktio.workerthread" -}}
{{- len .Values.pktio_affinity }}
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

{{- define "traffic-engine.inject_adapter.cpu-affinity" -}}
{{- join "," .Values.inject_adapter_affinity }}
{{- end -}}

{{- define "traffic-engine.pktio.cpu-affinity" -}}
{{- join "," .Values.pktio_affinity }}
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

{{- define "traffic-engine.bfdd.prestart" -}}
            if [ -f "/etc/traffic-engine/hotfix/bfdd/scripts/prestart.sh" ]; then chmod 0755 /etc/traffic-engine/hotfix/bfdd/scripts/prestart.sh; /etc/traffic-engine/hotfix/bfdd/scripts/prestart.sh;fi
{{- end -}}

{{- define "traffic-engine.firewall.copy-config-to-dest" -}}
            cp /opt/tsg/config/conflist.inf            /opt/tsg/sapp/plug/conflist.inf
            cp /opt/tsg/config/gdev.conf               /opt/tsg/sapp/etc/gdev.conf
            cp /opt/tsg/config/main.conf               /opt/tsg/sapp/tsgconf/main.conf
            cp /opt/tsg/config/maat.conf               /opt/tsg/sapp/tsgconf/maat.conf
            cp /opt/tsg/config/sapp.toml               /opt/tsg/sapp/etc/sapp.toml
            cp /opt/tsg/config/wangw.conf              /opt/tsg/sapp/etc/wannat/wangw.conf
            cp /opt/tsg/config/wire_graft.conf         /opt/tsg/sapp/etc/wire_graft/wire_graft.conf
            cp /opt/tsg/config/send_raw_pkt.conf       /opt/tsg/sapp/etc/send_raw_pkt.conf
            cp /opt/tsg/config/tsg_device_tag.json     /opt/tsg/etc/tsg_device_tag.json
            cp /opt/tsg/config/app_sketch_local.inf    /opt/tsg/sapp/plug/business/app_sketch_local/app_sketch_local.inf
            cp /opt/tsg/config/vlan_flipping_map.conf  /opt/tsg/sapp/etc/vlan_flipping_map.conf
            cp /opt/tsg/config/firewall.inf            /opt/tsg/sapp/plug/business/firewall/firewall.inf
            cp /opt/tsg/config/necessary_plug_list.conf  /opt/tsg/sapp/etc/necessary_plug_list.conf
            cp /opt/tsg/config/http_main.conf          /opt/tsg/sapp/conf/http/http_main.conf
            cp /opt/tsg/config/mail.conf               /opt/tsg/sapp/conf/mail/mail.conf
            cp /opt/tsg/config/ssl_main.conf           /opt/tsg/sapp/conf/ssl/ssl_main.conf
            cp /opt/tsg/config/spec.toml               /opt/tsg/sapp/stellar_plugin/spec.toml
{{- end -}}

{{- define "traffic-engine.proxy.copy-config-to-dest" -}}
            cp /opt/tsg/config/tfe.conf             /opt/tsg/tfe/conf/tfe/tfe.conf
            cp /opt/tsg/config/pangu_pxy.conf       /opt/tsg/tfe/conf/pangu/pangu_pxy.conf
            cp /opt/tsg/config/tsg_device_tag.json  /opt/tsg/etc/tsg_device_tag.json
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
{{- end -}}

{{- define "traffic-engine.init.sce" -}}
{{ if .Values.sce_config.vxlan_config.endpoint_nic }}
            ip tuntap add dev {{ .Values.sce_config.vxlan_config.endpoint_nic }} mode tap
            ip link set dev {{ .Values.sce_config.vxlan_config.endpoint_nic }} up
            ip route add {{ .Values.sce_config.vxlan_config.endpoint_netip }}/{{ .Values.sce_config.vxlan_config.endpoint_mask }} dev {{ .Values.sce_config.vxlan_config.endpoint_nic }} table 10
{{ if .Values.sce_config.vxlan_config.endpoint_gateway }}
            ip route add default via {{ .Values.sce_config.vxlan_config.endpoint_gateway }} table 10
{{- end }}
            ip a a {{ .Values.sce_config.vxlan_config.endpoint_ip }}/{{ .Values.sce_config.vxlan_config.endpoint_mask }} dev {{ .Values.sce_config.vxlan_config.endpoint_nic }} noprefixroute
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

{{- define "traffic-engine.volume.hostpath" -}}
      - name: host-root
        hostPath:
          path: /
{{- end -}}

{{- define "traffic-engine.firewall.mount.hostpath" -}}
{{- if eq .Values.debug.firewall.enable_mount_host_filesystem .Values.define_enable_val_yes }}
        - name: host-root
          mountPath: /host
{{- end }}
{{- end -}}

{{- define "traffic-engine.firewall.start" -}}
{{- if eq .Values.debug.firewall.enable_interactive_startup .Values.define_enable_val_yes -}}
            while true; do sleep 10;done
{{- else -}}
            exec /opt/tsg/sapp/sapp
{{- end }}
{{- end -}}

{{- define "traffic-engine.firewall.volume.prestart" -}}
{{- if eq .Values.debug.firewall.enable_prestart_script .Values.define_enable_val_yes }}
      - name: firewall-prestart
        hostPath:
{{- if .Values.debug.firewall.prestart_script }}
          path: {{ .Values.debug.firewall.prestart_script }}
{{- else }}
          path: /etc/tsg-os/{{ .Release.Name }}/firewall_prestart_script.sh
{{- end }}
          type: FileOrCreate
{{- end }}
{{- end -}}

{{- define "traffic-engine.firewall.mount.prestart" -}}
{{- if eq .Values.debug.firewall.enable_prestart_script .Values.define_enable_val_yes }}
        - name: prestart-dir
          mountPath: /tmp/prestart
        - name: firewall-prestart
          mountPath: /opt/tsg/scripts/prestart.sh
{{- end }}
{{- end -}}

{{- define "traffic-engine.firewall.prestart" -}}
{{- if eq .Values.debug.firewall.enable_prestart_script .Values.define_enable_val_yes }}
            chmod 0755 /opt/tsg/scripts/prestart.sh
            /opt/tsg/scripts/prestart.sh
{{- end }}
{{- end -}}

{{- define "traffic-engine.proxy.start" -}}
{{- if eq .Values.debug.proxy.enable_interactive_startup .Values.define_enable_val_yes -}}
            while true; do sleep 10;done
{{- else -}}
            exec /opt/tsg/tfe/bin/tfe
{{- end }}
{{- end -}}


{{- define "traffic-engine.proxy.volume.prestart" -}}
{{- if eq .Values.debug.proxy.enable_prestart_script .Values.define_enable_val_yes }}
      - name: proxy-prestart
        hostPath:
{{- if .Values.debug.proxy.prestart_script }}
          path: {{ .Values.debug.proxy.prestart_script }}
{{- else }}
          path: /etc/tsg-os/{{ .Release.Name }}/proxy_prestart_script.sh
{{- end }}
          type: FileOrCreate
{{- end }}
{{- end -}}

{{- define "traffic-engine.proxy.mount.prestart" -}}
{{- if eq .Values.debug.proxy.enable_prestart_script .Values.define_enable_val_yes }}
        - name: prestart-dir
          mountPath: /tmp/prestart
        - name: proxy-prestart
          mountPath: /opt/tsg/scripts/prestart.sh
{{- end }}
{{- end -}}

{{- define "traffic-engine.proxy.prestart" -}}
{{- if eq .Values.debug.proxy.enable_prestart_script .Values.define_enable_val_yes }}
            chmod 0755 /opt/tsg/scripts/prestart.sh
            /opt/tsg/scripts/prestart.sh
{{- end }}
{{- end -}}

{{- define "traffic-engine.proxy.mount.hostpath" -}}
{{- if eq .Values.debug.proxy.enable_mount_host_filesystem .Values.define_enable_val_yes }}
        - name: host-root
          mountPath: /host
{{- end }}
{{- end -}}


{{- define "traffic-engine.service-chaining.start" -}}
{{- if eq .Values.debug.service_chaining.enable_interactive_startup .Values.define_enable_val_yes -}}
            while true; do sleep 10;done
{{- else -}}
            exec /opt/tsg/sce/bin/sce
{{- end }}
{{- end -}}


{{- define "traffic-engine.service-chaining.volume.prestart" -}}
{{- if eq .Values.debug.service_chaining.enable_prestart_script .Values.define_enable_val_yes }}
      - name: service-chaining-prestart
        hostPath:
{{- if .Values.debug.service_chaining.prestart_script }}
          path: {{ .Values.debug.service_chaining.prestart_script }}
{{- else }}
          path: /etc/tsg-os/{{ .Release.Name }}/service_chaining_prestart_script.sh
{{- end }}
          type: FileOrCreate
{{- end }}
{{- end -}}

{{- define "traffic-engine.service-chaining.mount.prestart" -}}
{{- if eq .Values.debug.service_chaining.enable_prestart_script .Values.define_enable_val_yes }}
        - name: prestart-dir
          mountPath: /tmp/prestart
        - name: service-chaining-prestart
          mountPath: /opt/tsg/scripts/prestart.sh
{{- end }}
{{- end -}}

{{- define "traffic-engine.service-chaining.prestart" -}}
{{- if eq .Values.debug.service_chaining.enable_prestart_script .Values.define_enable_val_yes }}
            chmod 0755 /opt/tsg/scripts/prestart.sh
            /opt/tsg/scripts/prestart.sh
{{- end }}
{{- end -}}

{{- define "traffic-engine.service-chaining.mount.hostpath" -}}
{{- if eq .Values.debug.service_chaining.enable_mount_host_filesystem .Values.define_enable_val_yes }}
        - name: host-root
          mountPath: /host
{{- end }}
{{- end -}}

{{- define "traffic-engine.inject_adapter.copy-config-to-dest" -}}
            cp /opt/tsg/config/packet_adapter.conf  /opt/tsg/packet_adapter/conf
{{- end -}}

{{- define "traffic-engine.inject_adapter.mount.hostpath" -}}
{{- if eq .Values.debug.inject_adapter.enable_mount_host_filesystem .Values.define_enable_val_yes }}
        - name: host-root
          mountPath: /host
{{- end }}
{{- end -}}

{{- define "traffic-engine.inject_adapter.start" -}}
{{- if eq .Values.debug.inject_adapter.enable_interactive_startup .Values.define_enable_val_yes -}}
            while true; do sleep 10;done
{{- else -}}
           exec /opt/tsg/packet_adapter/bin/packet_adapter
{{- end }}
{{- end -}}

{{- define "traffic-engine.inject_adapter.volume.prestart" -}}
{{- if eq .Values.debug.inject_adapter.enable_prestart_script .Values.define_enable_val_yes }}
      - name: inject-adapter-prestart
        hostPath:
{{- if .Values.debug.inject_adapter.prestart_script }}
          path: {{ .Values.debug.inject_adapter.prestart_script }}
{{- else }}
          path: /etc/tsg-os/{{ .Release.Name }}/inject_adapter_prestart_script.sh
{{- end }}
          type: FileOrCreate
{{- end }}
{{- end -}}

{{- define "traffic-engine.inject_adapter.mount.prestart" -}}
{{- if eq .Values.debug.inject_adapter.enable_prestart_script .Values.define_enable_val_yes }}
        - name: prestart-dir
          mountPath: /tmp/prestart
        - name: inject-adapter-prestart
          mountPath: /opt/tsg/scripts/prestart.sh
{{- end }}
{{- end -}}

{{- define "traffic-engine.inject_adapter.prestart" -}}
{{- if eq .Values.debug.inject_adapter.enable_prestart_script .Values.define_enable_val_yes }}
            chmod 0755 /opt/tsg/scripts/prestart.sh
            /opt/tsg/scripts/prestart.sh
{{- end }}
{{- end -}}

{{- define "traffic-engine.shaping.start" -}}
{{- if eq .Values.debug.shaping.enable_interactive_startup .Values.define_enable_val_yes -}}
            while true; do sleep 10;done
{{- else -}}
            exec /opt/tsg/shaping_engine/bin/shaping_engine
{{- end }}
{{- end -}}


{{- define "traffic-engine.shaping.volume.prestart" -}}
{{- if eq .Values.debug.shaping.enable_prestart_script .Values.define_enable_val_yes }}
      - name: shaping-prestart
        hostPath:
{{- if .Values.debug.shaping.prestart_script }}
          path: {{ .Values.debug.shaping.prestart_script }}
{{- else }}
          path: /etc/tsg-os/{{ .Release.Name }}/shaping_prestart_script.sh
{{- end }}
          type: FileOrCreate
{{- end }}
{{- end -}}

{{- define "traffic-engine.shaping.mount.prestart" -}}
{{- if eq .Values.debug.shaping.enable_prestart_script .Values.define_enable_val_yes }}
        - name: prestart-dir
          mountPath: /tmp/prestart
        - name: shaping-prestart
          mountPath: /opt/tsg/scripts/prestart.sh
{{- end }}
{{- end -}}

{{- define "traffic-engine.shaping.prestart" -}}
{{- if eq .Values.debug.shaping.enable_prestart_script .Values.define_enable_val_yes }}
            chmod 0755 /opt/tsg/scripts/prestart.sh
            /opt/tsg/scripts/prestart.sh
{{- end }}
{{- end -}}

{{- define "traffic-engine.shaping.mount.hostpath" -}}
{{- if eq .Values.debug.shaping.enable_mount_host_filesystem .Values.define_enable_val_yes }}
        - name: host-root
          mountPath: /host
{{- end }}
{{- end -}}

{{- define "traffic-engine.volume.mrzcpd" -}}
      - name: opt-tsg-mrzcpd
        hostPath:
          path: /opt/tsg/mrzcpd
      - name: var-run-mrzcpd
        hostPath:
          path: /var/run/mrzcpd
      - name: var-run-dpdk
        hostPath:
          path: /var/run/dpdk
      - name: root-sys
        hostPath:
          path: /root/sys
      - name: profile-mrzcpd
        hostPath:
          path: /etc/profile.d/mrzcpd.sh
          type: File
      - name: ldconfig-mrzcpd
        hostPath:
          path: /etc/ld.so.conf.d/mrzcpd.conf
          type: File
      - name: sysconfig-mrzcpd
        hostPath:
          path: /etc/sysconfig/mrzcpd
          type: File
{{- end -}}

{{- define "traffic-engine.mount.mrzcpd" -}}
        - name: opt-tsg-mrzcpd
          mountPath: /opt/tsg/mrzcpd
          mountPropagation: HostToContainer
          readOnly: false
        - name: var-run-mrzcpd
          mountPath: /var/run/mrzcpd
          readOnly: false
        - name: var-run-dpdk
          mountPath: /var/run/dpdk
          readOnly: false
        - name: root-sys
          mountPath: /root/sys
          readOnly: false
        - name: profile-mrzcpd
          mountPath: /etc/profile.d/mrzcpd.sh
          readOnly: true
        - name: ldconfig-mrzcpd
          mountPath: /etc/ld.so.conf.d/mrzcpd.conf
          readOnly: true
        - name: sysconfig-mrzcpd
          mountPath: /etc/sysconfig/mrzcpd
          readOnly: true

{{- end -}}

{{- define "traffic-engine.volume.localtime" -}}
      - name: localtime-node
        hostPath:
          path: /etc/localtime
{{- end -}}

{{- define "traffic-engine.mount.localtime" -}}
        - name: localtime-node
          mountPath: /etc/localtime
          readOnly: true
{{- end -}}

{{- define "traffic-engine.volume.dev-bus-usb" -}}
      - name: dev-bus-usb-node
        hostPath:
          path: /dev/bus/usb
{{- end -}}

{{- define "traffic-engine.mount.dev-bus-usb" -}}
        - name: dev-bus-usb-node
          mountPath: /dev/bus/usb
          readOnly: true
{{- end -}}

{{- define "traffic-engine.global.cm.server-ip" -}}
{{- if eq .Values.external_resources.cm.connectivity "direct" }}
{{- print .Values.external_resources.cm.direct.address }}
{{- else }}
{{- print "CM_POLICY_LOCAL_CACHE_IP_LOCATION" }}
{{- end }}
{{- end -}}

{{- define "traffic-engine.global.cm.server-port" -}}
{{- if eq .Values.external_resources.cm.connectivity "direct" }}
{{- print .Values.external_resources.cm.direct.port }}
{{- else }}
{{- print "6379" }}
{{- end }}
{{- end -}}

{{- define "traffic-engine.global.cm.read-server-ip" -}}
{{- if eq .Values.external_resources.cm.connectivity "local_cache" }}
            export APISERVER=https://kubernetes.default.svc
            export SERVICEACCOUNT=/var/run/secrets/kubernetes.io/serviceaccount
            export TOKEN=$(cat ${SERVICEACCOUNT}/token)
            export CACERT=${SERVICEACCOUNT}/ca.crt
            curl --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -X GET ${APISERVER}/api/v1/namespaces/tsg-os-system/services/${CM_CACHE_SERVICE_NAME} -o /tmp/cm-cache.txt
            export CM_POLICY_LOCAL_CACHE_IP=$(cat /tmp/cm-cache.txt  | jq -r '.spec.clusterIP')
            echo "export CM_POLICY_LOCAL_CACHE_IP=${CM_POLICY_LOCAL_CACHE_IP}" > /etc/profile.d/cm-local-cache.sh
            chmod 0755 /etc/profile.d/cm-local-cache.sh
{{- end }}
{{- end -}}


{{- define "traffic-engine.global.cm.env-service-name" -}}
{{- if eq .Values.external_resources.cm.connectivity "local_cache" }}
        - name: CM_CACHE_SERVICE_NAME
          value: {{ .Values.external_resources.cm.local_cache.cache_name }}-redis-master
{{- end }}
{{- end -}}


{{- define "traffic-engine.firewall.set-redis-ip" -}}
{{- if eq .Values.external_resources.cm.connectivity "local_cache" }}
            sed -Ei "s|CM_POLICY_LOCAL_CACHE_IP_LOCATION|${CM_POLICY_LOCAL_CACHE_IP?}|g" /opt/tsg/sapp/tsgconf/maat.conf
            sed -Ei "s|CM_POLICY_LOCAL_CACHE_IP_LOCATION|${CM_POLICY_LOCAL_CACHE_IP?}|g" /opt/tsg/sapp/etc/wannat/wangw.conf
{{- end }}
{{- end -}}

{{- define "traffic-engine.proxy.certstore.set-redis-ip" -}}
{{- if eq .Values.external_resources.cm.connectivity "local_cache" }}
            sed -Ei "s|CM_POLICY_LOCAL_CACHE_IP_LOCATION|${CM_POLICY_LOCAL_CACHE_IP?}|g" /opt/tsg/certstore/conf/cert_store.ini
{{- end }}
{{- end -}}

{{- define "traffic-engine.proxy.tfe.set-redis-ip" -}}
{{- if eq .Values.external_resources.cm.connectivity "local_cache" }}
            sed -Ei "s|CM_POLICY_LOCAL_CACHE_IP_LOCATION|${CM_POLICY_LOCAL_CACHE_IP?}|g" /opt/tsg/tfe/conf/tfe/tfe.conf
{{- end }}
{{- end -}}

{{- define "traffic-engine.sce.set-redis-ip" -}}
{{- if eq .Values.external_resources.cm.connectivity "local_cache" }}
            sed -Ei "s|CM_POLICY_LOCAL_CACHE_IP_LOCATION|${CM_POLICY_LOCAL_CACHE_IP?}|g" /opt/tsg/sce/conf/sce.conf
{{- end }}
{{- end -}}

{{- define "traffic-engine.shaping.set-redis-ip" -}}
{{- if eq .Values.external_resources.cm.connectivity "local_cache" }}
            sed -Ei "s|CM_POLICY_LOCAL_CACHE_IP_LOCATION|${CM_POLICY_LOCAL_CACHE_IP?}|g" /opt/tsg/shaping_engine/conf/shaping.conf
{{- end }}
{{- end -}}

{{- define "traffic-engine.volume.dev-shm" -}}
      - name: dev-shm
        hostPath:
          path: /dev/shm
{{- end -}}

{{- define "traffic-engine.mount.dev-shm" -}}
        - name: dev-shm
          mountPath: /dev/shm
{{- end -}}

{{- define "traffic-engine.telegraf.read.device-id" -}}
            export device_id=`ipmitool fru list |grep 'Product Serial' | awk '{ print $4}'`
            if [ -z "$device_id" ]; then export device_id="unknown"; fi
            echo "export device_id=${device_id}" > /etc/profile.d/device_id.sh
{{- end -}}

{{- define "traffic-engine.global.sd.server-ip" -}}
{{- if eq .Values.external_resources.sd.enable .Values.define_enable_val_yes }}
{{- if eq .Values.external_resources.sd.connectivity "direct" }}
{{- print .Values.external_resources.sd.direct.address }}
{{- else }}
{{- print "SD_POLICY_LOCAL_CACHE_IP_LOCATION" }}
{{- end }}
{{- end }}
{{- end -}}

{{- define "traffic-engine.global.sd.server-port" -}}
{{- if eq .Values.external_resources.sd.enable .Values.define_enable_val_yes }}
{{- if eq .Values.external_resources.sd.connectivity "direct" }}
{{- print .Values.external_resources.sd.direct.port }}
{{- else }}
{{- print "6379" }}
{{- end }}
{{- end }}
{{- end -}}

{{- define "traffic-engine.global.sd.read-server-ip" -}}
{{- if eq .Values.external_resources.sd.enable .Values.define_enable_val_yes }}
{{- if eq .Values.external_resources.sd.connectivity "local_cache" }}
            export APISERVER=https://kubernetes.default.svc
            export SERVICEACCOUNT=/var/run/secrets/kubernetes.io/serviceaccount
            export TOKEN=$(cat ${SERVICEACCOUNT}/token)
            export CACERT=${SERVICEACCOUNT}/ca.crt
            curl --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -X GET ${APISERVER}/api/v1/namespaces/tsg-os-system/services/${SD_CACHE_SERVICE_NAME} -o /tmp/sd-cache.txt
            export SD_POLICY_LOCAL_CACHE_IP=$(cat /tmp/sd-cache.txt  | jq -r '.spec.clusterIP')
            echo "export SD_POLICY_LOCAL_CACHE_IP=${SD_POLICY_LOCAL_CACHE_IP}" > /etc/profile.d/sd-local-cache.sh
            chmod 0755 /etc/profile.d/sd-local-cache.sh
{{- end }}
{{- end }}
{{- end -}}


{{- define "traffic-engine.global.sd.env-service-name" -}}
{{- if eq .Values.external_resources.sd.enable .Values.define_enable_val_yes }}
{{- if eq .Values.external_resources.sd.connectivity "local_cache" }}
        - name: SD_CACHE_SERVICE_NAME
          value: {{ .Values.external_resources.sd.local_cache.cache_name }}-redis-master
{{- end }}
{{- end }}
{{- end -}}


{{- define "traffic-engine.firewall.sd.set-redis-ip" -}}
{{- if eq .Values.external_resources.sd.enable .Values.define_enable_val_yes }}
{{- if eq .Values.external_resources.sd.connectivity "local_cache" }}
            sed -Ei "s|SD_POLICY_LOCAL_CACHE_IP_LOCATION|${SD_POLICY_LOCAL_CACHE_IP?}|g" /opt/tsg/sapp/tsgconf/maat.conf
{{- end }}
{{- end }}
{{- end -}}
