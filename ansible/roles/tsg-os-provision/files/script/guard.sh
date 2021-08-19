#!/bin/bash -x

config_path=/data/tsg-os-provision/provision.yml
version_file_path=/usr/lib/os-release
present_version_file_path=/data/tsg-os-provision/.os-release.present


if [ ! -f "$config_path" ];then
    echo "$config_path is not exists, $config_path need to add and config"
    exit 1
fi

if [ ! -f "$present_version_file_path" ];then
    echo "Error: tsg-os-provision excute failed, Please checkout file $config_path and retry"
    exit 1
fi

md5_version_file=`md5sum $version_file_path | awk '{print $1}'`
md5_present_version_file=`md5sum $present_version_file_path | awk '{print $1}'`

if [ "$md5_version_file" != "$md5_present_version_file" ];then
    echo "Error: tsg-os-provision excute failed, Please checkout file $config_path and retry"
    exit 1
fi
