
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