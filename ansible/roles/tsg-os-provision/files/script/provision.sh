#!/bin/bash -ex

enable_config_apply=$1
config_path=/data/tsg-os-provision/provision.yml
config_d_path=/data/tsg-os-provision/provision.yml.d
snapshot_config_path=/data/tsg-os-provision/provision.yml.snapshot
snapshot_config_d_path=/data/tsg-os-provision/provision.yml.d.snapshot
hosts_path=/opt/tsg/tsg-os-provision/hosts
provision_path=/opt/tsg/tsg-os-provision/tasks/provision.yml
convertor_script_path=/opt/tsg/tsg-os-provision/scripts/convertor.sh

succ_sign_file=/data/tsg-os-provision/.provision_succeeded

#execute_provision_del_succ_sign(){
#    rm -rf ${succ_sign_file}
#}

execute_provision_convert_action(){
    /opt/tsg/tsg-os-provision/scripts/convertor.sh    
}

execute_provision_action(){
    ansible-playbook -i ${hosts_path} ${provision_path} -e "enable_config_apply=${enable_config_apply}"
    cp ${config_path} ${snapshot_config_path} -r 
    rm ${snapshot_config_d_path}
    cp -r ${config_d_path} ${snapshot_config_d_path}
}

#execute_provision_add_succ_sign(){
#    touch ${succ_sign_file}
#}

#execute_provision_del_succ_sign
execute_provision_convert_action
execute_provision_action
#execute_provision_add_succ_sign