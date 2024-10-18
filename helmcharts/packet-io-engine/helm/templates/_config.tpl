{{- define "mrzcpd.volume.prestart" -}}
{{- if  .Values.mrzcpd.debug.enable_prestart_script  }}
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
{{- if  .Values.mrzcpd.debug.enable_prestart_script }}
        - name: prestart-dir
          mountPath: /tmp/prestart
        - name: mrzcpd-prestart
          mountPath: /opt/tsg/scripts/prestart.sh
{{- end }}
{{- end -}}