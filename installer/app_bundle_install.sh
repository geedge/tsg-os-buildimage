#!/bin/sh

CONTAINER_IMAGES_TAR="%%CONTAINER_IMAGES_TAR%%"
TRAFFIC_ENGINE_HELM_CHART_TAR="%%TRAFFIC_ENGINE_HELM_CHART_TAR%%"
INJECT_HELM_CHART_TAR="%%INJECT_HELM_CHART_TAR%%"
MRZCPD_HELM_CHART_TAR="%%MRZCPD_HELM_CHART_TAR%%"
TREX_HELM_CHART_TAR="%%TREX_HELM_CHART_TAR%%"
DP_TRACE_HELM_CHART_TAR="%%DP_TRACE_HELM_CHART_TAR%%"

charts_dest_dir="/var/lib/rancher/k3s/server/static/charts"
images_dest_dir="/var/lib/rancher/k3s/agent/images"
clixon_conf_path="/opt/tsg/clixon/etc/mgnt-srv.conf"
load_images_switch="on"

src_dir=$(dirname $0)

#function define start
function read_charts_dest_dir_from_env()
{
    if [ ! -z "${APP_BUNDLE_CHARTS_DEST_DIR}" ]; then
        charts_dest_dir="${APP_BUNDLE_CHARTS_DEST_DIR}"
    fi
}

function read_images_dest_dir_from_env()
{
    if [ ! -z "${APP_BUNDLE_IMAGES_DEST_DIR}" ]; then
        images_dest_dir="${APP_BUNDLE_IMAGES_DEST_DIR}"
    fi
}

function read_clixon_conf_path_from_env()
{
    if [ ! -z "${APP_BUNDLE_CLIXON_CONF_PATH}" ]; then
        clixon_conf_path="${APP_BUNDLE_CLIXON_CONF_PATH}"
    fi
}

function read_load_images_switch_from_env()
{
    if [ ! -z "${APP_BUNDLE_LOAD_IMAGES_SWITCH}" ]; then
        load_images_switch="${APP_BUNDLE_LOAD_IMAGES_SWITCH}"
    fi
}

function copy_charts_to_dest()
{
    if [ -d "${charts_dest_dir}" ]; then
        mkdir -p "${charts_dest_dir}"
    fi

    cp -r ${src_dir}/${TRAFFIC_ENGINE_HELM_CHART_TAR} ${charts_dest_dir}
    cp -r ${src_dir}/${INJECT_HELM_CHART_TAR} ${charts_dest_dir}
    cp -r ${src_dir}/${MRZCPD_HELM_CHART_TAR} ${charts_dest_dir}
    cp -r ${src_dir}/${TREX_HELM_CHART_TAR} ${charts_dest_dir}
    cp -r ${src_dir}/${DP_TRACE_HELM_CHART_TAR} ${charts_dest_dir}

}

function copy_images_to_dest()
{
    if [ -d "${images_dest_dir}" ]; then
        mkdir -p "${images_dest_dir}"
    fi

    cp -r ${src_dir}/${CONTAINER_IMAGES_TAR} ${images_dest_dir}
}


function replace_clixon_chart_name()
{
    if [ ! -f "${clixon_conf_path}" ]; then
        echo "Error: ${clixon_conf_path} is not exist!"
        exit 1
    fi

    sed -ie "s/^chart_name=.*/chart_name=${TRAFFIC_ENGINE_HELM_CHART_TAR}/g" ${clixon_conf_path}
    sed -ie "s/^inject_adapter_chart_name=.*/inject_adapter_chart_name=${INJECT_HELM_CHART_TAR}/g" ${clixon_conf_path}
    sed -ie "s/^mrzcpd_chart_name=.*/mrzcpd_chart_name=${MRZCPD_HELM_CHART_TAR}/g" ${clixon_conf_path}
    sed -ie "s/^trex_chart_name=.*/trex_chart_name=${TREX_HELM_CHART_TAR}/g" ${clixon_conf_path}
    sed -ie "s/^datapath_trace_chart_name=.*/datapath_trace_chart_name=${DP_TRACE_HELM_CHART_TAR}/g" ${clixon_conf_path}
}

function load_images()
{
    if [ "${load_images_switch}" = "on" ]; then
        /usr/bin/k3s ctr image import ${images_dest_dir}/${CONTAINER_IMAGES_TAR}
    fi
}

#function define end

#function exec start
read_charts_dest_dir_from_env
read_images_dest_dir_from_env
read_clixon_conf_path_from_env
read_load_images_switch_from_env

copy_charts_to_dest
copy_images_to_dest
replace_clixon_chart_name
load_images
#function exec end
