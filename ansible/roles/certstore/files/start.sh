#!/bin/bash -e
prestart_scripts_dir="/etc/traffic-engine/hotfix/certstore/scripts"
prestart=$prestart_scripts_dir/prestart.sh

copyConfigmap2Dest(){
	/usr/bin/cp /opt/tsg/config/cert_store.ini       /opt/tsg/certstore/conf/cert_store.ini
	/usr/bin/cp /opt/tsg/config/tsg_device_tag.json  /opt/tsg/etc/tsg_device_tag.json
}

prestart(){
	if [ -f "$prestart" ]; then
		chmod 0755 $prestart
		$prestart
	fi
}

start(){
	/opt/tsg/certstore/bin/certstore
}

copyConfigmap2Dest
prestart
start
