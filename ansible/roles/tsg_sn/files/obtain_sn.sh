#!/bin/bash -ex

ip_of_obtain_sn=$1

if [ $ip_of_obtain_sn == '127.0.0.1' ];then
    echo "{\"sn\": \"CBT22021250000020625\"}" > /opt/tsg/etc/tsg_sn.json
    exit 0
fi

if [ ! -f "/opt/tsg/tsg-os-provision/cmm_api_tst" ];then
    echo "not found cmm_api_tst!"
    exit 1
fi

/opt/tsg/tsg-os-provision/cmm_api_tst 9 1 1 $ip_of_obtain_sn  | tee chid.id
if [ $? != 0 ]; then
    echo "cmm_api_tst failed!"
    exit 1
fi

CHID=`cat chid.id | sed -n '1p' | awk -F ":" '{print $2}' | sed 's/ //g'`
CHIDL=`echo $CHID | awk '{print length($0)}'`

if [ $CHIDL != 20 ];then
    echo "CHID length is not 20!"
    echo "{\"sn\": \"CBT00000000000000000\"}" > /opt/tsg/etc/tsg_sn.json
    exit 0
fi

echo "{\"sn\": \"$CHID\"}" > /opt/tsg/etc/tsg_sn.json
