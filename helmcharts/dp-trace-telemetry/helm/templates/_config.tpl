{{- define "dp_trace_telemetry.volume.prestart" -}}
{{- if eq .Values.datapath_trace.debug.enable_prestart_script  .Values.define_enable_val_yes }}
      - name: dp_trace_telemetry-prestart
        hostPath:
{{- if .Values.datapath_trace.debug.prestart_script }}
          path: {{ .Values.dp_trace_telemetry.debug.prestart_script }}
{{- else }}
          path: /etc/tsg-os/{{ .Release.Name }}/dp_trace_telemetry_prestart_script.sh
{{- end }}
          type: FileOrCreate
{{- end }}
{{- end -}}

{{- define "dp_trace_telemetry.mount.prestart" -}}
{{- if eq .Values.datapath_trace.debug.enable_prestart_script  .Values.define_enable_val_yes }}
        - name: prestart-dir
          mountPath: /tmp/prestart
        - name: dp_trace_telemetry-prestart
          mountPath: /opt/tsg/scripts/prestart.sh
{{- end }}
{{- end -}}
