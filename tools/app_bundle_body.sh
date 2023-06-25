#!/bin/sh
PAYLOAD_SHA1=%%IMAGE_SHA1%%
tmp_dir=
extract=no

args=$(getopt -a -o hx -l extract,help -- "$@")
eval set -- "${args}"

#function define start
function usage()
{
    echo 'Usage:'
    echo '      -x, --extract          Extract files from app-bundle bin to tmp file and exit'
    echo '      -h, --help             Give this help'
    echo '      Using ENV [$APP_BUNDLE_CHARTS_DEST_DIR] to change the helm charts dest directory'
    echo '      Using ENV [$APP_BUNDLE_IMAGES_DEST_DIR] to change the container images dest directory'
    echo '      Using ENV [$APP_BUNDLE_CLIXON_CONF_PATH] to set the clixon mgnt-srv.conf path'
    echo '      Using ENV [$APP_BUNDLE_LOAD_IMAGES_SWITCH] to set the load images switch'
    echo 'example: '$0' -x'
    echo 'example: '$0' -h'
    exit 0
}

#[ $? -ne 0 ] && usage
function read_option()
{
    while true
    do
        case "$1" in
        -x|--extract)
            extract=yes
            shift
            ;;
        -h|--help)
            usage
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            usage
            shift
            ;;
        esac
    done
}


function verify_checksum()
{
    echo -n "Verifying app-bundle bin checksum ..."

    sha1=$(sed -e '1,/^exit_marker$/d' "$0" | sha1sum | awk '{ print $1 }')

    if [ "$sha1" != "$PAYLOAD_SHA1" ] ; then
        echo
        echo "ERROR: Unable to verify archive checksum"
        echo "Expected: $PAYLOAD_SHA1"
        echo "Found   : $sha1"
        exit 1
    fi

    echo " OK."
}

function clean_up()
{
    if [ "$(id -u)" = "0" ] ; then
        umount $tmp_dir > /dev/null 2>&1
    fi
    rm -rf $tmp_dir
    exit $1
}

function extract_file()
{
    cur_wd=$(pwd)
    archive_path=$(realpath "$0")
    tmp_dir=$(mktemp -d)
    if [ "$(id -u)" = "0" ] ; then
        mount -t tmpfs tmpfs-installer $tmp_dir || clean_up 1
    fi
    cd $tmp_dir
    echo -n "Preparing image archive ..."
    sed -e '1,/^exit_marker$/d' $archive_path | tar jxf - || clean_up 1
    echo " OK."
    cd $cur_wd
}

function is_extract_and_exit()
{
    if [ "$extract" = "yes" ] ; then
        # stop here
        echo "Image extracted to: $tmp_dir"
        if [ "$(id -u)" = "0" ] ; then
            echo "To un-mount the tmpfs when finished type:  umount $tmp_dir"
        fi
        exit 0
    fi
}

read_option $@
verify_checksum
extract_file
is_extract_and_exit

$tmp_dir/installer/install.sh $@
rc="$?"

clean_up $rc

exit_marker
