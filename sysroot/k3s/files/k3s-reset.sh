#!/bin/sh

#stop k3s.
k3s-killall.sh
systemctl stop tsg-clixon-backend
systemctl stop k3s

sleep 60

##Backup default config.
#
#
k3s_backup_path="/data/k3s-backup"

mkdir -p ${k3s_backup_path}/mainfest
cp -a /var/lib/rancher/k3s/server/manifests/* ${k3s_backup_path}/mainfest

mkdir -p ${k3s_backup_path}/charts
cp -a /var/lib/rancher/k3s/server/static/charts/* ${k3s_backup_path}/charts

mkdir -p ${k3s_backup_path}/images
cp -a /var/lib/rancher/k3s/agent/images/* ${k3s_backup_path}/images

#Delete persistent data.
rm -rf /var/lib/rancher
rm -rf /data/var/lib/kubelet

#recovery config.
mkdir -p /var/lib/rancher/k3s/server/manifests/
cp -a ${k3s_backup_path}/mainfest/* /var/lib/rancher/k3s/server/manifests/

mkdir -p /var/lib/rancher/k3s/server/static/charts/
cp -a ${k3s_backup_path}/charts/*  /var/lib/rancher/k3s/server/static/charts/

mkdir -p /var/lib/rancher/k3s/agent/images/
cp -a ${k3s_backup_path}/images/*  /var/lib/rancher/k3s/agent/images/


systemctl start k3s
systemctl start tsg-clixon-backend
systemctl start tsg-clixon-restconf