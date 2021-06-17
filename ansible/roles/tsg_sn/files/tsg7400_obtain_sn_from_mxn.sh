#!/bin/bash

if [ ! -f "/opt/tsg/tsg-os-provision/cmm_api_tst" ];then
    echo "not found cmm_api_tst!"
    exit 1
fi

/opt/tsg/tsg-os-provision/cmm_api_tst 9 1 1 127.0.0.1  | tee chid.id
if [ $? != 0 ]; then
    echo "cmm_api_tst failed!"
    exit 1
fi

CHID=`cat chid.id | sed -n '1p' | awk -F ":" '{print $2}' | sed 's/ //g'`
CHIDL=`echo $CHID | awk '{print length($0)}'`

if [ $CHIDL != 20 ];then
    echo "CHID length is not 20!"
    exit 1
fi

echo "{\"sn\": \"$CHID\"}" > /opt/tsg/etc/tsg_sn.json
