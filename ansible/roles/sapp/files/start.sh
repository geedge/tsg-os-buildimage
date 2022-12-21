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

copyConfigmap2Dest
prestart
start
