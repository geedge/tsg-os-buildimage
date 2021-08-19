#!/bin/bash -x

config_path=/data/tsg-os-provision/provision.yml

if [ ! -f "$config_path" ];then
    echo "$config_path is not exists"
    exit 1
else
    echo "$config_path is exists"
    exit 0    
fi
#exit 1
