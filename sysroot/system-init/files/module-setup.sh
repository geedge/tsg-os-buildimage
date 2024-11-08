#!/bin/bash

# Called by dracut
check() {
    return 0
}

# Called by dracut
depends() {
    echo rootfs-block
    return 0
}

# Called by dracut
install() {
    inst_hook pre-mount 99 "$moddir/overlaymount.sh"
}

