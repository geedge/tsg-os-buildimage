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
      <packet_io_engine>
         <pktmbuf_max_size>${MRZCPD_SZ_DATA}</pktmbuf_max_size>
         <pktmbuf_queue_size>${MRZCPD_SZ_TUNNEL}</pktmbuf_queue_size>
         <pktmbuf_pool_create_mode>${MRZCPD_CREATE_MODE}</pktmbuf_pool_create_mode>
         <pktmbuf_pool_max_elements_count>${MRZCPD_DIRECT_PKTMBUF}</pktmbuf_pool_max_elements_count>
         <enable_check_pktmbuf_leak>${MRZCPD_CHECK_BUFFER_LEAK}</enable_check_pktmbuf_leak>
         <enable_poll_wait_throttle>${MRZCPD_POLL_WAIT_THROTTLE}</enable_poll_wait_throttle>
      </packet_io_engine>
   </system>
</config>"
    echo ${resources} | xmlstarlet fo > ${tsg_clixon_default_db_file}
    sed -i '/<?xml version="1.0"?>/d' ${tsg_clixon_default_db_file}
}