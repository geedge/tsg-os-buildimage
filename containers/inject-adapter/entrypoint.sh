#!/bin/sh -ex
source /usr/local/bin/entrypoint_public.sh

# start
ldconfig

parse_args "$@"


render_template packet_adapter.conf.j2 /opt/tsg/packet_adapter/conf/packet_adapter.conf



if [ ${IS_ENABLE_PRESTART} == "true" ]; then
    enable_prestart
fi

if [ ${IS_ENABLE_INTERACTIVE_STARTUP} == "true" ]; then
    enable_interactive_startup
fi

exec /opt/tsg/packet_adapter/bin/packet_adapter 