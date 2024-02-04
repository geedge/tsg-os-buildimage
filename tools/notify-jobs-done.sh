#!/bin/sh -x
ls -halt $CI_PROJECT_DIR/images/
TSG_OS_VERSION_FILE="$CI_PROJECT_DIR/images/tsg-os-version.txt"


TSG_OS_VERSION=
if [ -f $TSG_OS_VERSION_FILE ]; then TSG_OS_VERSION=$(cat $TSG_OS_VERSION_FILE); fi
echo $TSG_OS_VERSION

NOTIFY_CONTENT="{\"msgtype\": \"text\",\"text\": {\"content\": \"TSG-OS version: $TSG_OS_VERSION has been released.\",\"mentioned_list\":[\"@all\"]}}"
echo $NOTIFY_CONTENT

if [ -z "$TSG_OS_VERSION" ]; then echo "TSG_OS version: $TSG_OS_VERSION is NULL."; exit 1; fi
if [ -n "$ENABLE_NOTIFY_TESTING_JOBS_DONE" ] && [ "$ENABLE_NOTIFY_TESTING_JOBS_DONE" == "1" ]; then curl "$NOTIFY_TESTING_JOBS_DONE_WEBHOOK" -H "Content-Type: application/json" -d "$NOTIFY_CONTENT"; fi
if [ -n "$ENABLE_NOTIFY_RC_JOBS_DONE"      ] && [ "$ENABLE_NOTIFY_RC_JOBS_DONE"      == "1" ]; then curl "$NOTIFY_RC_JOBS_DONE_WEBHOOK"      -H "Content-Type: application/json" -d "$NOTIFY_CONTENT"; fi
if [ -n "$ENABLE_NOTIFY_RELEASE_JOBS_DONE" ] && [ "$ENABLE_NOTIFY_RELEASE_JOBS_DONE" == "1" ]; then curl "$NOTIFY_RELEASE_JOBS_DONE_WEBHOOK" -H "Content-Type: application/json" -d "$NOTIFY_CONTENT"; fi

rm -rf $TSG_OS_VERSION_FILE