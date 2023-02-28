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
{{- if eq (len .Values.sce.affinity) 1 }}
{{- 1 }}
{{- else }}
{{- sub (len .Values.sce.affinity) 1 }}
{{- end }}
{{- end -}}


{{- define "traffic-engine.tfe.cpu-affinity" -}}
{{- if eq (len .Values.tfe_affinity) 1 }}
{{- print (index .Values.tfe_affinity 0) "," (index .Values.tfe_affinity 0) }}
{{- else }}
{{- join "," .Values.tfe_affinity }}
{{- end }}
{{- end -}}

{{- define "traffic-engine.sce.cpu-affinity" -}}
{{- if eq (len .Values.sce.affinity) 1 }}
{{- print (index .Values.sce.affinity 0) "," (index .Values.sce.affinity 0) }}
{{- else }}
{{- join "," .Values.sce.affinity }}
{{- end }}
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
            cp /opt/tsg/config/kni.conf                /opt/tsg/sapp/etc/kni/kni.conf
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

{{- define "traffic-engine.firewall.get-service-node-port" -}}
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


{{- define "traffic-engine.firewall.set-shaping-config" -}}
            sed -Ei "s|NODE_IP_LOCATION|${NODE_IP?}|g" /opt/tsg/sapp/tsgconf/main.conf
            sed -Ei "s|CLUSTER_ANNOUNCE_PORT_LOCATION|${CLUSTER_ANNOUNCE_PORT?}|g" /opt/tsg/sapp/tsgconf/main.conf
            sed -Ei "s|HEALTH_CHECK_ANNOUNCE_PORT_LOCATION|${HEALTH_CHECK_ANNOUNCE_PORT?}|g" /opt/tsg/sapp/tsgconf/main.conf
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

