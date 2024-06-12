#!/bin/bash

CPU_AFFINITY=(${CPU_AFFINITY//,/ })
NIC_PCI=$(env | grep '_NIC_PCI' | cut -d'=' -f2 | sed 's/0000://')
arr=($NIC_PCI)
NIC_PCI=""
for interface in "${arr[@]}"; do
  if [ ! -z "$NIC_PCI" ]; then
    NIC_PCI+=","
  fi
  NIC_PCI+="\"$interface\""
done

declare -A NUMA
for cpu in ${CPU_AFFINITY[@]:2}; do
  numa_node=$(lscpu -p=CPU,NODE | grep "^$cpu," | cut -d',' -f2)
  NUMA[$numa_node]+="$cpu,"
done

cat << EOF > /etc/trex_cfg.yaml
- port_limit: 2
  version: 2
  stack: legacy
  interfaces: [${NIC_PCI}]
  port_mtu: 2000
  rx_desc: 4096
  tx_desc: 4096
  new_memory : true
  port_info       :
          - ip         : 17.17.0.1
            default_gw : 17.18.0.1
            dest_mac   : "00:11:22:33:44:55"
            src_mac    : "aa:bb:cc:dd:ee:ff"
          - ip         : 17.18.0.1
            default_gw : 17.17.0.1
            dest_mac   : "aa:bb:cc:dd:ee:ff"
            src_mac    : "00:11:22:33:44:55"
          - ip         : 17.19.0.1
            default_gw : 17.20.0.1
            dest_mac   : "00:11:22:33:44:54"
            src_mac    : "aa:bb:cc:dd:ee:fe"
          - ip         : 17.20.0.1
            default_gw : 17.19.0.1
            dest_mac   : "aa:bb:cc:dd:ee:fe"
            src_mac    : "00:11:22:33:44:54"
  platform:
    master_thread_id: ${CPU_AFFINITY[0]}
    latency_thread_id: ${CPU_AFFINITY[1]}
    dual_if:
EOF

socket_id=0
for numa_node in "${!NUMA[@]}"; do
  threads=${NUMA[$numa_node]%,}
  echo "      - socket: $socket_id" >> /etc/trex_cfg.yaml
  echo "        threads: [${threads// /,}]" >> /etc/trex_cfg.yaml
  ((socket_id++))
done

cat << EOF >> /etc/trex_cfg.yaml
  tw:
    buckets: 2048
    levels: 3
    bucket_time_usec: 40.0
EOF
