#!/bin/sh
# Find the process PID
pid=$(pidof mrzcpd)
if [ -z "$pid" ]; then
  echo "No process found that matches the criteria"
  exit 0
fi
# Send SIGHUP signal
kill -HUP "$pid"
echo "SIGHUP signal sent to process with PID: $pid"