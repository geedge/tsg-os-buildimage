set -ex
dp_adapter_ether_addr=$(ifconfig ens1f2 | grep ether | awk '{print $2}')
bpf_rule="ether dst $dp_adapter_ether_addr or ether dst 02:42:c0:a8:fd:03 or ether dst 02:42:c0:a8:fd:83 or ether dst 02:42:c0:a8:fd:82"
sed -i "/BSD_packet_filter=/s/=.*/=\"$bpf_rule\"/" etc/sapp.toml
