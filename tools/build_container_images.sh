#!/bin/sh -e
CODE_PROJECT_DIR=$1
CODE_CONF_DIR=$2
CODE_TOOTS_DIR=$3

OS_RELEASE_VER=$4
PROFILE_ID=$5
IMAGE_CACHE_DIR=$6

EXPORT_IMAGES_DIR=$7
EXPORT_IMAGES_NAME=$8


IMAGE_REPO_PREFIX="registry.gdnt-cloud.website"

BASE_IMAGE_NAME="${IMAGE_REPO_PREFIX}/tsg-base:${OS_RELEASE_VER}"

##function define start
function load_rockylinux_image()
{
    podman load < ${CODE_PROJECT_DIR}/package/rockylinux8.tar
}

function build_image()
{
    local component_name=$1
    local source_image_name=$2
    local target_image_name=$3

    local container_name="tsg-${component_name}-install-${OS_RELEASE_VER}"
    #create container
    buildah from --name ${container_name} ${source_image_name}

    #copy /etc/hosts into container
    buildah copy ${container_name} ${CODE_CONF_DIR}/yum-RockyLinux-8.conf /tmp/
    buildah copy ${container_name} /etc/hosts /tmp/
    buildah run  ${container_name} -- bash -c "cp /etc/hosts /tmp/hosts.bak;cp /tmp/hosts /etc/hosts"

    #deploy the traffic engine into container
	${CODE_TOOTS_DIR}/ansible-HAL-CONTAINER ${PROFILE_ID}-${component_name}  ${CODE_PROJECT_DIR} /tmp/empty/container /tmp/yum-RockyLinux-8.conf ${OS_RELEASE_VER} ${container_name}

    #clean install fine in container    
    buildah run  ${container_name} -- bash -c "yum clean all -y; yum -c /tmp/yum-RockyLinux-8.conf clean all -y" 
    buildah run  ${container_name} -- bash -c "cp /tmp/ks-script-* /; cp /tmp/hosts.bak /etc/hosts; rm -rf /tmp/*; mv /ks-script-* /tmp"   
    
    ##
    if [ "proxy" == "${component_name}" ]; then
        buildah run ${container_name} -- bash -c "cat /etc/sysctl.d/80-tfe.conf" > ${IMAGE_CACHE_DIR}/80-tfe.conf
    fi

    #commit container
    buildah commit ${container_name} ${target_image_name}

    #delete container
    buildah rm ${container_name}
}

function export_images()
{
    podman save -o ${EXPORT_IMAGES_DIR}/${EXPORT_IMAGES_NAME}  -m \
            ${IMAGE_REPO_PREFIX}/tsg-firewall:${OS_RELEASE_VER} \
            ${IMAGE_REPO_PREFIX}/tsg-proxy:${OS_RELEASE_VER} \
            ${IMAGE_REPO_PREFIX}/tsg-certstore:${OS_RELEASE_VER} \
            ${IMAGE_REPO_PREFIX}/tsg-telegraf:${OS_RELEASE_VER} \
            ${IMAGE_REPO_PREFIX}/tsg-init:${OS_RELEASE_VER} \
            ${IMAGE_REPO_PREFIX}/tsg-sce:${OS_RELEASE_VER} \
            ${IMAGE_REPO_PREFIX}/tsg-bfdd:${OS_RELEASE_VER} \
            ${IMAGE_REPO_PREFIX}/tsg-inject:${OS_RELEASE_VER} \
            ${IMAGE_REPO_PREFIX}/tsg-packet-io-engine:${OS_RELEASE_VER} \
            ${IMAGE_REPO_PREFIX}/tsg-shaping:${OS_RELEASE_VER} \
            ${IMAGE_REPO_PREFIX}/tsg-packet-io-engine-deviceplugin:${OS_RELEASE_VER}
}
##function define end


load_rockylinux_image

build_image "base" "rockylinux:8" "${BASE_IMAGE_NAME}"

build_image "firewall"  "${BASE_IMAGE_NAME}" "${IMAGE_REPO_PREFIX}/tsg-firewall:${OS_RELEASE_VER}"
build_image "proxy"     "${BASE_IMAGE_NAME}" "${IMAGE_REPO_PREFIX}/tsg-proxy:${OS_RELEASE_VER}"
build_image "certstore" "${BASE_IMAGE_NAME}" "${IMAGE_REPO_PREFIX}/tsg-certstore:${OS_RELEASE_VER}"
build_image "telegraf"  "${BASE_IMAGE_NAME}" "${IMAGE_REPO_PREFIX}/tsg-telegraf:${OS_RELEASE_VER}"
build_image "init"      "${BASE_IMAGE_NAME}" "${IMAGE_REPO_PREFIX}/tsg-init:${OS_RELEASE_VER}"
build_image "sce"       "${BASE_IMAGE_NAME}" "${IMAGE_REPO_PREFIX}/tsg-sce:${OS_RELEASE_VER}"
build_image "bfdd"      "${BASE_IMAGE_NAME}" "${IMAGE_REPO_PREFIX}/tsg-bfdd:${OS_RELEASE_VER}"
build_image "shaping"   "${BASE_IMAGE_NAME}" "${IMAGE_REPO_PREFIX}/tsg-shaping:${OS_RELEASE_VER}"
build_image "inject"    "${BASE_IMAGE_NAME}" "${IMAGE_REPO_PREFIX}/tsg-inject:${OS_RELEASE_VER}"
build_image "packet-io-engine"    "${BASE_IMAGE_NAME}" "${IMAGE_REPO_PREFIX}/tsg-packet-io-engine:${OS_RELEASE_VER}"
build_image "packet-io-engine-deviceplugin"    "${BASE_IMAGE_NAME}" "${IMAGE_REPO_PREFIX}/tsg-packet-io-engine-deviceplugin:${OS_RELEASE_VER}"

export_images

