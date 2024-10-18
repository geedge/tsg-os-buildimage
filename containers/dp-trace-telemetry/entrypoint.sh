#!/bin/sh -ex
source /usr/local/bin/entrypoint_public.sh

# start
ldconfig

parse_args "$@"


render_template dp_trace.conf.j2 /opt/tsg/dp_trace_telemetry/etc/dp_trace.conf



if [ ${IS_ENABLE_PRESTART} == "true" ]; then
    enable_prestart
fi

if [ ${IS_ENABLE_INTERACTIVE_STARTUP} == "true" ]; then
    enable_interactive_startup
fi

exec /opt/tsg/dp_trace_telemetry/bin/dp_trace_telemetry -c /opt/tsg/dp_trace_telemetry/etc/dp_trace.conf -d /opt/tsg/dp_trace_telemetry/etc/dp_trace_dy.conf