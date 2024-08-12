#!/bin/sh -ex
source /usr/local/bin/entrypoint_public.sh

# start
ldconfig

parse_args "$@"

mkdir -p /opt/tsg/etc/

DEVICE_SN=$(read_device_sn_from_k8s_node_info)
echo "{\"sn\": \"$DEVICE_SN\"}" > /opt/tsg/etc/tsg_sn.json

if [ ${IS_ENABLE_PRESTART} == "true" ]; then
    enable_prestart
fi

if [ ${IS_ENABLE_INTERACTIVE_STARTUP} == "true" ]; then
    enable_interactive_startup
fi

exec /opt/tsg/bfdd/bin/bfdd -u root -g root