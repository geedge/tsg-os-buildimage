#!/bin/sh -ex
source /usr/local/bin/entrypoint_public.sh

IS_ENABLE_DOS_PROTECTOR="false"

parse_args()
{
    if [ $# -eq 0 ]; then
        echo "No arguments provided, using default configs. Skipping..."
        return
    fi
    PARSED_OPTIONS=$(getopt -o "" -l enable_prestart,enable_interactive_startup,enable_dos_protector -- "$@")

    if [ $? -ne 0 ]; then
        echo "Failed to parse arguments."
        exit 1
    fi
    eval set -- "$PARSED_OPTIONS"

    while true; do
        case "$1" in
            --enable_prestart)
                IS_ENABLE_PRESTART="true"
                shift ;;
            --enable_interactive_startup)
                IS_ENABLE_INTERACTIVE_STARTUP="true"
                shift ;;
            --enable_dos_protector)
                IS_ENABLE_DOS_PROTECTOR="true"
                shift ;;
            --)
                shift
                break ;;
            *)
                echo "Unknown option: $1"
                break ;;
        esac
    done
}

enable_dos_protector()
{
    local podname=${HOSTNAME}
    local CLUSTER_ANNOUNCE_PORT=$(read_nodeport_from_service ${podname}-8551 default)
    local HEALTH_CHECK_ANNOUNCE_PORT=$(read_nodeport_from_service ${podname}-8552 default)

    sed -Ei -c "s|NODE_IP_LOCATION|${NODE_IP?}|g" /opt/tsg/sapp/tsgconf/main.conf
    sed -Ei -c "s|CLUSTER_ANNOUNCE_PORT_LOCATION|${CLUSTER_ANNOUNCE_PORT?}|g" /opt/tsg/sapp/tsgconf/main.conf
    sed -Ei -c "s|HEALTH_CHECK_ANNOUNCE_PORT_LOCATION|${HEALTH_CHECK_ANNOUNCE_PORT?}|g" /opt/tsg/sapp/tsgconf/main.conf
}

# start
ldconfig

parse_args "$@"

mkdir -p /opt/tsg/etc/

render_template asymmetric_addr_layer.conf.j2 /opt/tsg/sapp/etc/asymmetric_addr_layer.conf
render_template conflist.inf.j2 /opt/tsg/sapp/plug/conflist.inf
render_template firewall_logger_transmitter_schema.json.j2 /opt/tsg/sapp/tsgconf/firewall_logger_transmitter_schema.json
render_template firewall.inf.j2 /opt/tsg/sapp/plug/business/firewall/firewall.inf
render_template gdev.conf.j2 /opt/tsg/sapp/etc/gdev.conf
render_template http_main.conf.j2 /opt/tsg/sapp/conf/http/http_main.conf
render_template maat.conf.j2 /opt/tsg/sapp/tsgconf/maat.conf
render_template mail.conf.j2 /opt/tsg/sapp/conf/mail/mail.conf
render_template main.conf.j2 /opt/tsg/sapp/tsgconf/main.conf
render_template sapp.toml.j2 /opt/tsg/sapp/etc/sapp.toml
render_template send_raw_pkt.conf.j2 /opt/tsg/sapp/etc/send_raw_pkt.conf
render_template spec.toml.j2 /opt/tsg/sapp/stellar_plugin/spec.toml
render_template ssl_main.conf.j2 /opt/tsg/sapp/conf/ssl/ssl_main.conf
render_template tsg_device_tag.json.j2 /opt/tsg/etc/tsg_device_tag.json

DEVICE_SN=$(read_device_sn_from_k8s_node_info)
echo "{\"sn\": \"$DEVICE_SN\"}" > /opt/tsg/etc/tsg_sn.json

if [ ${IS_ENABLE_DOS_PROTECTOR} == "true" ]; then
    enable_dos_protector
fi

if [ ${IS_ENABLE_PRESTART} == "true" ]; then
    enable_prestart
fi

if [ ${IS_ENABLE_INTERACTIVE_STARTUP} == "true" ]; then
    enable_interactive_startup
fi

exec /opt/tsg/sapp/sapp