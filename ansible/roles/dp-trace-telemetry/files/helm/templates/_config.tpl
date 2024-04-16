{{- define "dp_trace_telemetry.start" -}}
{{- if eq .Values.dp_trace_telemetry.debug.enable_interactive_startup .Values.define_enable_val_yes -}}
            while true; do sleep 10;done
{{- else -}}
           exec /opt/tsg/dp_trace_telemetry/bin/dp_trace_telemetry -c /opt/tsg/dp_trace_telemetry/etc/dp_trace.conf -d /opt/tsg/dp_trace_telemetry/etc/dp_trace_dy.conf 2>&1|tee >(systemd-cat -t $DEPLOYMENT_NAME)
{{- end }}
{{- end -}}

{{- define "dp_trace_telemetry.volume.prestart" -}}
{{- if eq .Values.dp_trace_telemetry.debug.enable_prestart_script  .Values.define_enable_val_yes }}
      - name: dp_trace_telemetry-prestart
        hostPath:
{{- if .Values.dp_trace_telemetry.debug.prestart_script }}
          path: {{ .Values.dp_trace_telemetry.debug.prestart_script }}
{{- else }}
          path: /etc/tsg-os/{{ .Release.Name }}/dp_trace_telemetry_prestart_script.sh
{{- end }}
          type: FileOrCreate
{{- end }}
{{- end -}}

{{- define "dp_trace_telemetry.mount.prestart" -}}
{{- if eq .Values.dp_trace_telemetry.debug.enable_prestart_script  .Values.define_enable_val_yes }}
        - name: prestart-dir
          mountPath: /tmp/prestart
        - name: dp_trace_telemetry-prestart
          mountPath: /opt/tsg/scripts/prestart.sh
{{- end }}
{{- end -}}

{{- define "dp_trace_telemetry.prestart" -}}
{{- if eq .Values.dp_trace_telemetry.debug.enable_prestart_script  .Values.define_enable_val_yes }}
            echo WARNING: PRESTART.sh is enable, the commands in PRESTART.sh is:
            cat /opt/tsg/scripts/prestart.sh
            
            chmod 0755 /opt/tsg/scripts/prestart.sh
            source /opt/tsg/scripts/prestart.sh

            echo PRESTART.sh has been exec......
{{- end }}
{{- end -}}
