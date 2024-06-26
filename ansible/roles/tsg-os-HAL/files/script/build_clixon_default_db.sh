#!/bin/sh

build_default_db()
{
    local resources="<config>
   <system xmlns=\"urn:yang:tsg-os-mgnt-srv\">
      <resources>
         <packet_io_engine_hugepages>${HUGEPAGES}</packet_io_engine_hugepages>
         <packet_io_engine_cores>${IOCORE}</packet_io_engine_cores>
         <workload_cores>${WORKLOAD_CORE}</workload_cores>
      </resources>
   </system>
</config>"
    echo ${resources} | xmlstarlet fo > ${tsg_clixon_default_db_file}
    sed -i '/<?xml version="1.0"?>/d' ${tsg_clixon_default_db_file}
}