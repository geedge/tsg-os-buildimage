#!/bin/bash -ex

enable_config_apply=$1
config_path=/data/tsg-os-provision/provision.yml
snapshot_config_path=/data/tsg-os-provision/provision.yml.snapshot
hosts_path=/opt/tsg/tsg-os-provision/hosts
provision_path=/opt/tsg/tsg-os-provision/tasks/provision.yml
version_file_path=/usr/lib/os-release
present_version_file_path=/data/tsg-os-provision/.os-release.present
convertor_script_path=/opt/tsg/tsg-os-provision/convertor.sh

execute_provision_convert_action(){
    /opt/tsg/tsg-os-provision/convertor.sh    
}

execute_provision_action(){
    ansible-playbook -i ${hosts_path} ${provision_path} -e "var_files_path=${config_path} enable_config_apply=${enable_config_apply}"
    cp ${config_path} ${snapshot_config_path} -r
    cp ${version_file_path} ${present_version_file_path} -r   
}

#if [ ! -f "$present_version_file_path" ];then
#    execute_provision_action
#    exit 0
#fi

#md5_version_file=`md5sum $version_file_path | awk '{print $1}'`
#md5_present_version_file=`md5sum $present_version_file_path | awk '{print $1}'`

#if [ "$md5_version_file" != "$md5_present_version_file" ];then
#    execute_provision_action
#    exit 0
#fi
execute_provision_convert_action
execute_provision_action