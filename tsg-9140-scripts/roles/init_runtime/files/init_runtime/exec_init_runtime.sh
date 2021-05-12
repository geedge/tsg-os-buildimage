#!/bin/bash

config_path=/data/init_runtime/runtime.yml
hosts_path=/opt/tsg/init_runtime/hosts
init_runtime_path=/opt/tsg/init_runtime/tasks/init_runtime.yml
backup_path=/opt/tsg/init_runtime/tasks/backup_conf.yml
rollback_path=/opt/tsg/init_runtime/tasks/rollback_conf.yml


backup_exit_code=0
init_runtime_exit_code=0
rollback_exit_code=0


ansible-playbook -i ${hosts_path} ${backup_path} 2>&1>>/tmp/init_runtime.log
backup_exit_code=$?
if [ $backup_exit_code -ne 0 ]; then
  echo "Error: backup files failed,return code:${backup_exit_code}"
  exit 1
fi

ansible-playbook -i ${hosts_path} ${init_runtime_path} -e "var_files_path=${config_path}" 2>&1>>/tmp/init_runtime.log
init_runtime_exit_code=$?
if [ $init_runtime_exit_code -ne 0 ];then
  echo "Warning: init runtime failed, return code:${init_runtime_exit_code}"
  ansible-playbook -i ${hosts_path} ${rollback_path} 2>&1>>/tmp/init_runtime.log
  rollback_exit_code=$?
  echo "Warning: rollback failed, return code:${rollback_exit_code}"
  exit 1
fi