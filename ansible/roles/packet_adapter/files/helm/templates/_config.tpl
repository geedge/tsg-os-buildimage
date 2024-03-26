{{- define "traffic-engine.mount.mrzcpd" -}}
        - name: opt-tsg-mrzcpd
          mountPath: /opt/tsg/mrzcpd
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

{{- end -}}

{{- define "traffic-engine.mount.localtime" -}}
        - name: localtime-node
          mountPath: /etc/localtime
          readOnly: true
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
{{- end -}}

{{- define "traffic-engine.volume.hostpath" -}}
      - name: host-root
        hostPath:
          path: /
{{- end -}}

{{- define "traffic-engine.volume.localtime" -}}
      - name: localtime-node
        hostPath:
          path: /etc/localtime
{{- end -}}

{{- define "traffic-engine.inject_adapter.workerthread" -}}
{{- len .Values.inject_adapter_affinity }}
{{- end -}}

{{- define "traffic-engine.inject_adapter.cpu-affinity" -}}
{{- join "," .Values.inject_adapter_affinity }}
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
           exec /opt/tsg/packet_adapter/bin/packet_adapter 2>&1 | tee >(systemd-cat -t $DEPLOYMENT_NAME)
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
            echo WARNING: PRESTART.sh is enable, the commands in PRESTART.sh is:
            cat /opt/tsg/scripts/prestart.sh
            
            chmod 0755 /opt/tsg/scripts/prestart.sh
            source /opt/tsg/scripts/prestart.sh

            echo PRESTART.sh has been exec......
{{- end }}
{{- end -}}
