#!/bin/sh -ex
source /usr/local/bin/entrypoint_public.sh

# start
ldconfig

parse_args "$@"

mkdir -p /opt/tsg/etc/

render_template sce.conf.j2 /opt/tsg/sce/conf/sce.conf
render_template tsg_device_tag.json.j2 /opt/tsg/etc/tsg_device_tag.json

DEVICE_SN=$(read_device_sn_from_k8s_node_info)
echo "{\"sn\": \"$DEVICE_SN\"}" > /opt/tsg/etc/tsg_sn.json

if [ ${IS_ENABLE_PRESTART} == "true" ]; then
    enable_prestart
fi

if [ ${IS_ENABLE_INTERACTIVE_STARTUP} == "true" ]; then
    enable_interactive_startup
fi


exec /opt/tsg/sce/bin/sce
