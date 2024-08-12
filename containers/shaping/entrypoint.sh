#!/bin/sh -ex
source /usr/local/bin/entrypoint_public.sh

set_configs_in_runtime()
{
    local podname=${HOSTNAME}
    local CLUSTER_ANNOUNCE_PORT=$(read_nodeport_from_service ${podname}-8551 default)
    local HEALTH_CHECK_ANNOUNCE_PORT=$(read_nodeport_from_service ${podname}-8552 default)

    sed -Ei -c "s|NODE_IP_LOCATION|${NODE_IP?}|g" /opt/tsg/shaping_engine/conf/shaping.conf
    sed -Ei -c "s|CLUSTER_ANNOUNCE_PORT_LOCATION|${CLUSTER_ANNOUNCE_PORT?}|g" /opt/tsg/shaping_engine/conf/shaping.conf
    sed -Ei -c "s|HEALTH_CHECK_ANNOUNCE_PORT_LOCATION|${HEALTH_CHECK_ANNOUNCE_PORT?}|g" /opt/tsg/shaping_engine/conf/shaping.conf
}

# start
ldconfig

parse_args "$@"

mkdir -p /opt/tsg/etc/

render_template shaping.conf.j2 /opt/tsg/shaping_engine/conf/shaping.conf
render_template tsg_device_tag.json.j2 /opt/tsg/etc/tsg_device_tag.json

DEVICE_SN=$(read_device_sn_from_k8s_node_info)
echo "{\"sn\": \"$DEVICE_SN\"}" > /opt/tsg/etc/tsg_sn.json

set_configs_in_runtime

if [ ${IS_ENABLE_PRESTART} == "true" ]; then
    enable_prestart
fi

if [ ${IS_ENABLE_INTERACTIVE_STARTUP} == "true" ]; then
    enable_interactive_startup
fi

exec /opt/tsg/shaping_engine/bin/shaping_engine