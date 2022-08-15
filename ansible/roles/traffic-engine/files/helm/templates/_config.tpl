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
{{ len .Values.tfe_affinity }}
{{- end -}}

{{- define "traffic-engine.tfe.cpu-affinity" -}}
{{ join "," .Values.tfe_affinity }}
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