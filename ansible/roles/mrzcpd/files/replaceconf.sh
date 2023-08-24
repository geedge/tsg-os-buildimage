#!/bin/bash

source_conf="/var/run/share/container_mrzcpd.conf"
target_file="/opt/tsg/mrzcpd/etc/mrglobal.conf"

IFS="="
while read -r key value
do
    if [[ $key =~ ^[[:space:]]*# || -z $key ]]; then
        continue
    fi

    sed -i "s/^$key=.*/$key=$value/g" $target_file
done < "$source_conf"