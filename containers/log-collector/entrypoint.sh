#!/bin/sh -ex


sysctl -w fs.inotify.max_user_instances=8192
exec /opt/tsg/log-collector/bin/log-collector