#!/bin/sh

PRESTART_FILE="/opt/tsg/scripts/prestart.sh"
TEMPLATES_DIR="/templates"
VALUES_FILE="${TEMPLATES_DIR}/values.yaml"

IS_ENABLE_PRESTART="false"
IS_ENABLE_INTERACTIVE_STARTUP="false"

parse_args() 
{
    if [ $# -eq 0 ]; then
        echo "No arguments provided, using default configs. Skipping..."
        return
    fi

    PARSED_OPTIONS=$(getopt -o "" -l enable_prestart,enable_interactive_startup -- "$@")

    if [ $? -ne 0 ]; then
        echo "Failed to parse arguments."
        exit 1
    fi

    eval set -- "$PARSED_OPTIONS"

    while true; do
        case "$1" in
            --enable_prestart)
                IS_ENABLE_PRESTART="true"
                shift ;;
            --enable_interactive_startup)
                IS_ENABLE_INTERACTIVE_STARTUP="true"
                shift ;;
            --)
                shift
                break ;;
            *)
                echo "Unknown option $1"
                break ;;
        esac
    done
}

enable_prestart()
{
    if test -e ${PRESTART_FILE}; then
        echo WARNING: PRESTART.sh is enable, the commands in PRESTART.sh is:
        cat ${PRESTART_FILE}
        chmod 0755 ${PRESTART_FILE}; source ${PRESTART_FILE}
        echo PRESTART.sh has been exec......
    fi
}

enable_interactive_startup()
{
    while true; do sleep 10; done
}

read_device_sn_from_k8s_node_info() {
    local APISERVER=https://kubernetes.default.svc
    local SERVICEACCOUNT=/var/run/secrets/kubernetes.io/serviceaccount
    local NAMESPACE=$(cat ${SERVICEACCOUNT}/namespace)
    local TOKEN=$(cat ${SERVICEACCOUNT}/token)
    local CACERT=${SERVICEACCOUNT}/ca.crt

    if [[ -z "$NODE_NAME" ]]; then
        >&2 echo "env NODE_NAME is not set or empty!"
        return 1
    fi
    local OUTPUT_FILE="/tmp/node-${NODE_NAME}.json"

    curl --silent --fail --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" \
        -X GET ${APISERVER}/api/v1/nodes/${NODE_NAME} \
        -o ${OUTPUT_FILE}

    if [[ $? -ne 0 ]]; then
        >&2 echo "Failed to retrieve node information!"
        return 1
    fi

    local DEVICE_SN=$(cat ${OUTPUT_FILE} | jq -r '.metadata.annotations."tsg-os/device-sn"')
    if [[ -z "$DEVICE_SN" || "$DEVICE_SN" == "null" ]]; then
        >&2 echo "Device SN not found!"
        return 1
    fi

    echo "$DEVICE_SN"
}


render_template() {
    local template_file=$1
    local output_file=$2
    /usr/local/bin/j2 -f yaml ${TEMPLATES_DIR}/${template_file} ${VALUES_FILE} -o ${output_file}
}

read_nodeport_from_service() {
    local service_name=$1
    local service_namespace=$2
    local service_domain=${service_name}.${service_namespace}.svc

    until nslookup ${service_domain} >&2; do
        >&2 echo "waiting for service: ${service_domain}."
        sleep 2
    done

    local APISERVER=https://kubernetes.default.svc
    local SERVICEACCOUNT=/var/run/secrets/kubernetes.io/serviceaccount
    local NAMESPACE=$(cat ${SERVICEACCOUNT}/namespace)
    local TOKEN=$(cat ${SERVICEACCOUNT}/token)
    local CACERT=${SERVICEACCOUNT}/ca.crt

    curl --silent --fail --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" \
        -X GET ${APISERVER}/api/v1/namespaces/${NAMESPACE}/services/${service_name} \
        -o /tmp/service.txt

    local nodeport=$(cat /tmp/service.txt | jq '.spec.ports[] | .nodePort')
    echo ${nodeport}
}