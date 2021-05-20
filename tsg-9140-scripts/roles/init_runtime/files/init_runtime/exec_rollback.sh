#!/bin/bash

backup_config_path=/data/init_runtime/backup/runtime.yml
hosts_path=/opt/tsg/init_runtime/hosts
rollback_path=/opt/tsg/init_runtime/tasks/init_runtime.yml

rollback_exit_code=0


ansible-playbook -i ${hosts_path} ${rollback_path} -e "var_files_path=${backup_config_path}"
if [ $rollback_exit_code -ne 0 ];then
  exit 1
fi