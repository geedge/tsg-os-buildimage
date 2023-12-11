#!/bin/bash -x
DEVICE_TYPE=
SN=

function read_device_type()
{
    product_name=`ipmitool fru list | grep 'Product Name' | awk '{print $4}'`

    case ${product_name} in
        "ACB300-040-00" | "9000-NPB-P01R01")
            DEVICE_TYPE="9000-NPB"
            ;;
        *)
        ;;
    esac
}

function read_sn()
{
    if [ ${DEVICE_TYPE} == "9000-NPB" ]; then
        SN=`ipmitool fru -t 130 | awk 'NR==12' | awk '{ print $4}'`
    else
        SN=`ipmitool fru list | grep 'Product Serial' | awk '{ print $4}'`
    fi

    if [ -z "${SN}" ]; then
        SN="unknown"
    fi
}

function add_sn_env()
{
    env_profile="/etc/profile.d/sn.sh"

    #export SN=${SN}. Not set in present session.
    echo "export SN=${SN}" > ${env_profile}
    chmod 0755 ${env_profile}
}

read_device_type
read_sn
add_sn_env