#!/bin/bash
set -eufo pipefail

# The absolute path to the containerd socket.
readonly CONTAINERD_SOCK='/run/k3s/containerd/containerd.sock'

# The absolute path to the CoreDNS manifest file.
readonly COREDNS_YAML='/var/lib/rancher/k3s/server/manifests/coredns-custom.yaml'

get_file_mtime() {
    # Get file "$1" mtime in Epoch seconds.
    stat -c '%Y' "$1"
}

wait_for_file() {
    # Wait for file "$1" to exist.
    until [[ -e "$1" ]]; do
        sleep 1
    done
}

get_nameservers() {
    # Get a list of DNS nameservers defined in /etc/resolv.conf.
    if [[ -e /etc/resolv.conf ]]; then
        awk '($1=="nameserver"){print $2}' /etc/resolv.conf
    fi
}

restart_coredns_deployment() {
    # Restart the CoreDNS deployment.
    kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml \
        apply -f $COREDNS_YAML
    kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml --namespace kube-system \
        rollout restart deployment coredns
}

update_coredns_forwarding() {
    # Comment out "forward" line in the CoreDNS manifest (i.e., Corefile) if
    # there are no DNS nameservers configured on the host. If the manifest
    # was updated, restart CoreDNS.
    local nameservers
    mapfile -t nameservers < <(get_nameservers)
    if [[ "${#nameservers[@]}" -eq 0 ]]; then
        echo 'Disabling CoreDNS host forwarding ...'
        sed -i 's/\(^\s\+\)forward \. \/etc\/resolv\.conf/\1#forward \. \/etc\/resolv\.conf/' "$COREDNS_YAML"
        restart_coredns_deployment
    else
        echo 'Enabling CoreDNS host forwarding ...'
        sed -i 's/\(^\s\+\)#forward \. \/etc\/resolv\.conf/\1forward \. \/etc\/resolv\.conf/' "$COREDNS_YAML"
        restart_coredns_deployment
    fi
}

main() {
    wait_for_file "$CONTAINERD_SOCK"
    wait_for_file "$COREDNS_YAML"
    update_coredns_forwarding
}

main