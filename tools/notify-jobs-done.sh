#!/bin/sh -x
ls -halt $CI_PROJECT_DIR/images/
HAS_BUILT_FILES="$CI_PROJECT_DIR/images/has-built-files.txt"

################################################function define start###################################################
read_tsg_os_version()
{
    local has_built_files=$1
    local tsg_os_version=
    if [ -f $has_built_files ]; then
        tsg_os_version=$(cat $has_built_files | grep 'ONIE.bin' | grep -v 'sha256sum.txt' | awk -F '-x86_64' '{print $1}')
    fi
    echo $tsg_os_version
}

#https://repo.geedge.net/filerepo/install/release/tsg-os-images/tsg-os-v24.01.4-57dbca0-x86_64_COTS-ONIE-kvm.img
build_download_urls()
{
    local scheme=$1
    local domain=$2
    local subpath=$3
    local has_build_files=$4

    local base_url="$scheme://$domain/$subpath/"
    local urls=""
    while IFS= read -r line; do
        urls="$urls$base_url$line\n"
    done < $has_build_files
    echo $urls
}

build_notify_content()
{
    local aliyun_url_subpath=$1
    local bj_office_url_subpath=$2
    local tsg_os_version=$3
    local has_built_files=$4

    bj_download_urls=$(build_download_urls https repo.geedge.net        $aliyun_url_subpath    $has_built_files)
    de_download_urls=$(build_download_urls https de.repo.gdnt-cloud.com $aliyun_url_subpath    $has_built_files)
    sg_download_urls=$(build_download_urls https sg.repo.gdnt-cloud.com $aliyun_url_subpath    $has_built_files)
    bj_office_download_urls=$(build_download_urls http 192.168.44.24    $bj_office_url_subpath $has_built_files)

    title_content="$tsg_os_version has been built. You can download it from the nearest mirror site.\n"
    bj_content="Beijing:\n$bj_download_urls"
    de_content="Berlin:\n$de_download_urls"
    sg_content="Singapore:\n$sg_download_urls"
    bj_office_content="Beijing Office (accessible only from the Beijing Office):\n$bj_office_download_urls"

    #echo "$notify_content_title$notify_content_bj$notify_content_de$notify_content_sg$notify_content_xxg"
    echo "{\"msgtype\": \"text\",\"text\": {\"content\": \"$title_content$bj_content$de_content$sg_content$bj_office_content\"}}"
}

#################################################function define end####################################################

TSG_OS_VERSION=$(read_tsg_os_version $HAS_BUILT_FILES)
if [ -z "$TSG_OS_VERSION" ]; then 
    echo "TSG_OS version: $TSG_OS_VERSION is NULL."
    exit 1
fi

if [ -n "$ENABLE_NOTIFY_TESTING_JOBS_DONE" ] && [ "$ENABLE_NOTIFY_TESTING_JOBS_DONE" == "1" ]; then
    notify_content=$(build_notify_content filerepo/install/testing/tsg-os-images tsg-os/testing $TSG_OS_VERSION $HAS_BUILT_FILES)
    curl "$NOTIFY_TESTING_JOBS_DONE_WEBHOOK" -H "Content-Type: application/json" -d "$notify_content"
fi

if [ -n "$ENABLE_NOTIFY_RC_JOBS_DONE"      ] && [ "$ENABLE_NOTIFY_RC_JOBS_DONE"      == "1" ]; then
    notify_content=$(build_notify_content filerepo/install/rc/tsg-os-images      tsg-os/rc      $TSG_OS_VERSION $HAS_BUILT_FILES)
    curl "$NOTIFY_RC_JOBS_DONE_WEBHOOK"      -H "Content-Type: application/json" -d "$notify_content"
fi

if [ -n "$ENABLE_NOTIFY_RELEASE_JOBS_DONE" ] && [ "$ENABLE_NOTIFY_RELEASE_JOBS_DONE" == "1" ]; then
    notify_content=$(build_notify_content filerepo/install/release/tsg-os-images tsg-os/release $TSG_OS_VERSION $HAS_BUILT_FILES)
    curl "$NOTIFY_RELEASE_JOBS_DONE_WEBHOOK" -H "Content-Type: application/json" -d "$notify_content"
fi

rm -rf $HAS_BUILT_FILES