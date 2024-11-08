#!/bin/bash

KUBELET_HOME=/var/lib
for ((i=1; i<=5; i++));
do
	for podid in $(grep -a "orphaned pod" /var/log/messages | tail -1 | awk '{print $23}' | sed 's/\\\"//g');
	do
		echo $podid
		if [ ! -d ${KUBELET_HOME}/kubelet/pods/$podid ]; then
			break
		fi

		rm -rf ${KUBELET_HOME}/kubelet/pods/$podid/
		#echo ${KUBELET_HOME}/kubelet/pods/$podid/
	done
	sleep 2
done
