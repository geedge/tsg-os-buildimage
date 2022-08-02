#!/bin/bash
IMAGES_RELEASE_VAR="default"
DOCKER_IMAGES_VER="default"
IMAGES_REPO_LIST=("tsg-firewall" "tsg-proxy" "tsg-certstore" "tsg-telegraf" "tsg-init")
CONFIGMAP_NAME="vsys1-provision"
COMMAND_K3S="/usr/local/bin/k3s"
WR_PATH="/opt/tsg/vsys1/workload_resource/tsg_workload_resource.yml"
PROVISION_PATH="/data/tsg-os-provision/provision.yml"
APPEND_PROVISION_PATH="/opt/tsg/tsg-os-provision/.policy_and_log_nic_ip.yaml"

TRAFFIC_ENGINE_ACTION=$1


os_release_var_obtain(){
    HOST_OS_RELEASE_VAR=$(awk -F= '$1=="VERSION" { print $2 ;}' /etc/os-release  | sed 's/\"//g' | cut -d ' ' -f1)
    if [ "${DOCKER_IMAGES_VER}" == "default" ]; then
        IMAGES_RELEASE_VAR=${HOST_OS_RELEASE_VAR}
    else
        IMAGES_RELEASE_VAR=${DOCKER_IMAGES_VER}
    fi
    echo "Need to import container images version:${IMAGES_RELEASE_VAR}"
}

image_check_loaded_and_load(){
    IMAGES_REF=$(${COMMAND_K3S} ctr image list |  awk '{print $1}')
    for IMAGE_REPO in ${IMAGES_REPO_LIST[@]}; do
        if [[ "${IMAGES_REF}" =~ "${IMAGE_REPO}:${IMAGES_RELEASE_VAR}" ]]; then
            echo "Contaimer iamage loaded,  repo name:${IMAGE_REPO}, tag:${IMAGES_RELEASE_VAR}"
        else
            IMAGE_PATH="/opt/tsg/images/${IMAGE_REPO}-${IMAGES_RELEASE_VAR}-docker.tar"
            echo "Container images not load, repo name:${IMAGE_REPO}, tag:${IMAGES_RELEASE_VAR}"
            if [ ! -f ${IMAGE_PATH} ]; then
                echo "Containers images ${IMAGE_PATH} is not exsit! exit now"
                exit 1
            fi
            ${COMMAND_K3S} ctr image import ${IMAGE_PATH}
        fi
    done
}

configmap_delete(){
    ${COMMAND_K3S} kubectl delete configmap ${CONFIGMAP_NAME}
}

configmap_check_running_and_create(){
    QUERY_CONFIGMAP_RESULT=$(${COMMAND_K3S} kubectl get configmap | awk '{print $1}')
    if [[ "${QUERY_CONFIGMAP_RESULT}" =~ "${CONFIGMAP_NAME}" ]]; then
        echo "configmap:${CONFIGMAP_NAME} is running"
        configmap_delete
    else
        echo "configmap:${CONFIGMAP_NAME} is not running"
    fi
    ${COMMAND_K3S} kubectl create configmap ${CONFIGMAP_NAME} --from-file=${PROVISION_PATH} --from-file=${APPEND_PROVISION_PATH}
}

wr_create(){
    ${COMMAND_K3S} kubectl apply -f ${WR_PATH}
}

wr_delete(){
    ${COMMAND_K3S} kubectl delete -f ${WR_PATH}
}

traffic_engine_start(){
    os_release_var_obtain
    image_check_loaded_and_load
    configmap_check_running_and_create
    wr_create
}

traffic_engine_stop(){
    wr_delete
    configmap_delete
}

traffic_engine_status(){
    echo "Configmap list:"
    ${COMMAND_K3S} kubectl get configmap
    echo -e "\n"
    echo "Daemonset list:"
    ${COMMAND_K3S} kubectl get daemonset
    echo -e "\n"
    echo "Pod list:"
    ${COMMAND_K3S} kubectl get pod
    echo -e "\n"
}

if [ "${TRAFFIC_ENGINE_ACTION}" == "start" ]; then
    traffic_engine_start
fi

if [ "${TRAFFIC_ENGINE_ACTION}" == "stop" ]; then
    traffic_engine_stop
fi

if [ "${TRAFFIC_ENGINE_ACTION}" == "status" ]; then
    traffic_engine_status
fi