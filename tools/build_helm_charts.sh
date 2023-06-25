#!/bin/sh -e
CODE_PROJECT_DIR=$1
OS_RELEASE_VER=$2
WRITE_HELM_CHART_VER=$3
WRITE_HELM_CHART_DIR=$4

##function define start
function build_helm_charts()
{
    mkdir -p /tmp/helm
    tar -zxvf ${CODE_PROJECT_DIR}/ansible/roles/traffic-engine/files/helm-linux-amd64.tar.gz  -C /tmp/helm
    /tmp/helm/linux-amd64/helm package --app-version ${OS_RELEASE_VER} --version ${WRITE_HELM_CHART_VER} -d ${WRITE_HELM_CHART_DIR} ${CODE_PROJECT_DIR}/ansible/roles/traffic-engine/files/helm
    rm -rf /tmp/helm
}
##function define end

build_helm_charts
