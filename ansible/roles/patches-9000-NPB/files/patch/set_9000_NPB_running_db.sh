#!/bin/sh
RUNNING_DB_FILE="/etc/clixon/running_db"
NETWORK_IN_RUNNING_DB=

SLOT_ID=

read_slot_id()
{
    output=$(ipmitool picmg addrinfo)
    substr=${output:22:1}
    SLOT_ID=$((16#${substr}+16))
}

add_network_into_running_db()
{
    local network="<network xmlns=\"urn:yang:tsg-os-mgnt-srv\">
       <interface>
          <name>eth_pf_smbio</name>
          <type>endpoint</type>
          <address>10.252.${SLOT_ID}.1</address>
       </interface>
       <interface>
          <name>eth_vf_mirr</name>
          <type>endpoint</type>
       </interface>
       <service>
          <name>service_1</name>
          <mode>virtual-wire</mode>
          <listen_on_device>eth_pf_smbio</listen_on_device>
       </service>
       <traffic_mirror>
          <enable>yes</enable>
          <interface>eth_vf_mirr</interface>
       </traffic_mirror>
    </network>"
    #xmlstarlet ed --omit-decl -s "/config" -t text -n '' -v "$(xmlstarlet sel -t -c '/config/*' 2.xml)"   1.xml | xmlstarlet unesc | xmlstarlet fo --omit-decl > 3.xml
    #$network | xmlstarlet sel -t -c '/config/*'
    xml_content=$(xmlstarlet ed --omit-decl -s "/config" -t text -n '' -v "${network}" ${RUNNING_DB_FILE} | xmlstarlet unesc)
    echo ${xml_content} | xmlstarlet fo --omit-decl > ${RUNNING_DB_FILE}
}

is_network_in_running_db()
{
    ret=$(xmlstarlet sel -N ns="urn:yang:tsg-os-mgnt-srv" -t -v "count(/config/ns:network)" ${RUNNING_DB_FILE})
    if [ "${ret}" == "0" ]; then
        NETWORK_IN_RUNNING_DB="false"
    else
        NETWORK_IN_RUNNING_DB="true"
    fi
}

delete_running_db_network()
{
    if [ "${NETWORK_IN_RUNNING_DB}" == "true" ]; then
        xmlstarlet ed --omit-decl -L -N ns="urn:yang:tsg-os-mgnt-srv" -d "/config/ns:network" ${RUNNING_DB_FILE}
    fi
}
read_slot_id
is_network_in_running_db
delete_running_db_network
add_network_into_running_db
