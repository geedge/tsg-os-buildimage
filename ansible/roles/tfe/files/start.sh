#!/bin/bash
prestart_scripts_dir="/etc/traffic-engine/hotfix/proxy/scripts"
prestart=$prestart_scripts_dir/prestart.sh

copyConfigmap2Dest(){
	/usr/bin/cp /opt/tsg/config/tfe.conf             /opt/tsg/tfe/conf/tfe/tfe.conf
	/usr/bin/cp /opt/tsg/config/pangu_pxy.conf       /opt/tsg/tfe/conf/pangu/pangu_pxy.conf
	/usr/bin/cp /opt/tsg/config/tsg_device_tag.json  /opt/tsg/etc/tsg_device_tag.json
}
prestart(){
	if [ -f "$prestart" ]; then
		chmod 0755 $prestart
		$prestart
	fi
}
start(){
	/opt/tsg/tfe/bin/tfe
}

copyConfigmap2Dest
prestart
start

