{{- define "traffic-engine.config.addresses.converter" -}}
{{- $addresses := list -}}
{{- $source := index . 0  -}}
{{- $separator := index . 1  -}}
{{- if $source }}
{{- range $source -}}
{{- $address := ( print .address  ":"  .port ) -}}
{{- $addresses = append $addresses $address -}}
{{- end -}}
{{- join $separator $addresses }}
{{- end }}
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

{{/*
Set up the environment to enable API access. 
The template should be invoked in command line.
*/}}
{{- define "public.prepare-access-API" -}}
export APISERVER=https://kubernetes.default.svc
export SERVICEACCOUNT=/var/run/secrets/kubernetes.io/serviceaccount
export NAMESPACE=$(cat ${SERVICEACCOUNT}/namespace)
export TOKEN=$(cat ${SERVICEACCOUNT}/token)
export CACERT=${SERVICEACCOUNT}/ca.crt
{{- end -}}

{{/*
Read the node annotations information and serialize it into a file.
The template should be invoked from the command line.
The template requires "public.prepare-access-API".
*/}}
{{- define "public.serialize-node-annotations" -}}
curl --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -X GET ${APISERVER}/api/v1/nodes/${NODE_NAME} -o /tmp/node-${NODE_NAME}.json
export DEVICE_SN=$(cat /tmp/node-${NODE_NAME}.json | jq -r '.metadata.annotations."tsg-os/device-sn"')
echo "{\"sn\": \"$DEVICE_SN\"}" >      /opt/tsg/shared-configs/tsg_sn.json
echo "export device_id=${DEVICE_SN}" > /opt/tsg/shared-configs/device_id.sh
{{- end -}}

{{/*
The volumes related to "mrzcpd". 
The volumes will be mounted by "traffic-engine.mount.mrzcpd".
*/}}
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
- name: profile-mrzcpd
  hostPath:
    path: /etc/profile.d/mrzcpd.sh
    type: File
- name: ldconfig-mrzcpd
  hostPath:
    path: /etc/ld.so.conf.d/mrzcpd.conf
    type: File
{{- end -}}

{{/*
The volumeMounts related to "mrzcpd".  
Requires "traffic-engine.volume.mrzcpd"
*/}}
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
- name: profile-mrzcpd
  mountPath: /etc/profile.d/mrzcpd.sh
  readOnly: true
- name: ldconfig-mrzcpd
  mountPath: /etc/ld.so.conf.d/mrzcpd.conf
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

{{/*
Read cm service ip and set it up as an environment variable.
Requires "public.prepare-access-API"
*/}}
{{- define "traffic-engine.global.cm.read-server-ip" -}}
curl --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -X GET ${APISERVER}/api/v1/namespaces/tsg-os-system/services/{{ .Values.external_resources.cm.local_cache.cache_name }}-redis-master -o /tmp/cm-cache.txt
export CM_POLICY_LOCAL_CACHE_IP=$(cat /tmp/cm-cache.txt  | jq -r '.spec.clusterIP')
echo "export CM_POLICY_LOCAL_CACHE_IP=${CM_POLICY_LOCAL_CACHE_IP}" > /etc/profile.d/cm-local-cache.sh
chmod 0755 /etc/profile.d/cm-local-cache.sh
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

{{/*
Read sd service ip and set it up as an environment variable.
Requires "public.prepare-access-API"
*/}}
{{- define "traffic-engine.global.sd.read-server-ip" -}}
curl --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -X GET ${APISERVER}/api/v1/namespaces/tsg-os-system/services/{{ .Values.external_resources.sd.local_cache.cache_name }}-redis-master -o /tmp/sd-cache.txt
export SD_POLICY_LOCAL_CACHE_IP=$(cat /tmp/sd-cache.txt  | jq -r '.spec.clusterIP')
echo "export SD_POLICY_LOCAL_CACHE_IP=${SD_POLICY_LOCAL_CACHE_IP}" > /etc/profile.d/sd-local-cache.sh
chmod 0755 /etc/profile.d/sd-local-cache.sh
{{- end -}}

{{- define "public.sync-host-timezone.volume" -}}
- name: localtime-volume
  hostPath:
    path: /etc/localtime
{{- end -}}

{{- define "public.sync-host-timezone.volume-mount" -}}
- name: localtime-volume
  mountPath: /etc/localtime
  readOnly: true
{{- end -}}

{{- define "public.license-support.dev-shm-volume" -}}
- name: dev-shm-volume
  hostPath:
    path: /dev/shm
{{- end -}}

{{- define "public.license-support.dev-shm-volume-mount" -}}
- name: dev-shm-volume
  mountPath: /dev/shm
{{- end -}}

{{- define "public.license-support.dev-bus-usb-volume" -}}
- name: dev-bus-usb-node
  hostPath:
    path: /dev/bus/usb
{{- end -}}

{{- define "public.license-support.dev-bus-usb-volume-mount" -}}
- name: dev-bus-usb-node
  mountPath: /dev/bus/usb
  readOnly: true
{{- end -}}