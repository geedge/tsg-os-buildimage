#!/bin/sh -ex
source /usr/local/bin/entrypoint_public.sh
# start

parse_args "$@"


render_template mrglobal.conf.j2 /opt/tsg/mrzcpd/etc/mrglobal.conf



if [ ${IS_ENABLE_PRESTART} == "true" ]; then
    enable_prestart
fi

if [ ${IS_ENABLE_INTERACTIVE_STARTUP} == "true" ]; then
    enable_interactive_startup
fi

exec /opt/tsg/mrzcpd/bin/mrzcpd -c /opt/tsg/mrzcpd/etc/mrglobal.conf -s /opt/tsg/mrzcpd/etc/mrglobal.dynamic.conf