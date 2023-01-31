#!/bin/bash
prestart_scripts_dir="/etc/traffic-engine/hotfix/firewall/scripts"
prestart=$prestart_scripts_dir/prestart.sh

copyConfigmap2Dest(){
	/usr/bin/cp /opt/tsg/config/conflist.inf            /opt/tsg/sapp/plug/conflist.inf
	/usr/bin/cp /opt/tsg/config/gdev.conf               /opt/tsg/sapp/etc/gdev.conf
	/usr/bin/cp /opt/tsg/config/main.conf               /opt/tsg/sapp/tsgconf/main.conf
	/usr/bin/cp /opt/tsg/config/maat.conf               /opt/tsg/sapp/tsgconf/maat.conf
	/usr/bin/cp /opt/tsg/config/sapp.toml               /opt/tsg/sapp/etc/sapp.toml
	/usr/bin/cp /opt/tsg/config/kni.conf                /opt/tsg/sapp/etc/kni/kni.conf
	/usr/bin/cp /opt/tsg/config/wangw.conf              /opt/tsg/sapp/etc/wannat/wangw.conf
	/usr/bin/cp /opt/tsg/config/wire_graft.conf         /opt/tsg/sapp/etc/wire_graft/wire_graft.conf
	/usr/bin/cp /opt/tsg/config/tsg_conn_sketch.inf     /opt/tsg/sapp/plug/business/tsg_conn_sketch/tsg_conn_sketch.inf
	/usr/bin/cp /opt/tsg/config/send_raw_pkt.conf       /opt/tsg/sapp/etc/send_raw_pkt.conf
	/usr/bin/cp /opt/tsg/config/tsg_device_tag.json     /opt/tsg/etc/tsg_device_tag.json
	/usr/bin/cp /opt/tsg/config/app_sketch_local.inf    /opt/tsg/sapp/plug/business/app_sketch_local/app_sketch_local.inf
	/usr/bin/cp /opt/tsg/config/vlan_flipping_map.conf  /opt/tsg/sapp/etc/vlan_flipping_map.conf
	/usr/bin/cp /opt/tsg/config/firewall.inf            /opt/tsg/sapp/plug/business/firewall/firewall.inf
}

prestart(){
	if [ -f "$prestart" ]; then
		chmod 0755 $prestart
		$prestart
	fi
}
start(){
	/opt/tsg/sapp/sapp
}

getServiceNodeport(){
	export APISERVER=https://kubernetes.default.svc
	export SERVICEACCOUNT=/var/run/secrets/kubernetes.io/serviceaccount
	export NAMESPACE=$(cat ${SERVICEACCOUNT}/namespace)
	export TOKEN=$(cat ${SERVICEACCOUNT}/token)
	export CACERT=${SERVICEACCOUNT}/ca.crt
	curl --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -X GET ${APISERVER}/api/v1/namespaces/${NAMESPACE}/services/${SERVICENAME} -o /tmp/service.txt
	export CLUSTERANNOUNCEPORT=$(cat /tmp/service.txt | jq '.spec.ports[] | select(.name=="cluster-announce-port") | .nodePort')
	export HEALTHCHECKANNOUNCEPORT=$(cat /tmp/service.txt | jq '.spec.ports[] | select(.name=="healthcheck-announce-port") | .nodePort')
	echo "export CLUSTERANNOUNCEPORT=${CLUSTERANNOUNCEPORT}" > /etc/profile.d/announceinfo.sh
	echo "export HEALTHCHECKANNOUNCEPORT=${HEALTHCHECKANNOUNCEPORT}" >> /etc/profile.d/announceinfo.sh
	chmod 0755 /etc/profile.d/announceinfo.sh
}

copyConfigmap2Dest
getServiceNodeport
prestart
start
