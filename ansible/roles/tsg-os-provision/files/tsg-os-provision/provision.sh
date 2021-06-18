#!/bin/bash -ex

config_path=/data/tsg-os-provision/provision.yml
backup_config_path=/data/tsg-os-provision/provision.yml.bak
hosts_path=/opt/tsg/tsg-os-provision/hosts
provision_path=/opt/tsg/tsg-os-provision/tasks/provision.yml

ansible-playbook -i ${hosts_path} ${provision_path} -e "var_files_path=${config_path}"
cp /data/tsg-os-provision/provision.yml /data/tsg-os-provision/provision.yml.bak -r