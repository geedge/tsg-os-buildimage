#!/bin/sh

set -x

OS_PATH_NAME=$1
GNS3_TEMPLATE_FILE=$2

OS_NAME=$(basename ${OS_PATH_NAME})
OS_MD5=$(md5sum ${OS_PATH_NAME} | awk '{print $1}')
OS_SIZE=$(wc -c < ${OS_PATH_NAME})
OS_VERSION=$(echo ${OS_NAME} | grep -Eo "[0-9]+\.[0-9]+")

if [ -z "${OS_VERSION}" ]; then
    OS_VERSION=1.1
fi

cat <<EOF > ${GNS3_TEMPLATE_FILE}
{
    "name": "TSG-X",
    "category": "guest",
    "description": "TSG-X 0906",
    "vendor_name": "",
    "vendor_url": "",
    "documentation_url": "",
    "product_name": "TSG-X",
    "registry_version": 3,
    "status": "stable",
    "maintainer": "GNS3 Team",
    "maintainer_email": "developers@gns3.net",
    "qemu": {
        "adapter_type": "virtio-net-pci",
        "adapters": 4,
        "ram": 32768,
        "cpus": 4,
        "hda_disk_interface": "virtio",
        "arch": "x86_64",
        "console_type": "vnc",
        "kvm": "require",
        "options": "-nographic -cpu host"
    },
    "images": [
        {
            "filename": "${OS_NAME}",
            "version": "${OS_VERSION}",
            "md5sum": "${OS_MD5}",
            "filesize": ${OS_SIZE}
        }
    ],
    "versions": [
        {
            "name": "${OS_VERSION}",
            "images": {
                "hda_disk_image": "${OS_NAME}"
            }
        }
    ]
}
EOF

