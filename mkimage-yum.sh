#!/usr/bin/env bash
#
# Create a base CentOS Docker image.
#
# This script is useful on systems with yum installed (e.g., building
# a CentOS image on CentOS).  See contrib/mkimage-rinse.sh for a way
# to build CentOS images on other systems.

usage() {
    cat <<EOOPTS
$(basename $0) [OPTIONS] <name>
OPTIONS:
  -y <yumconf>  The path to the yum config to install packages from. The
                default is /etc/yum.conf.
EOOPTS
    exit 1
}

# option defaults
yum_config=/etc/yum.conf
while getopts ":y:h" opt; do
    case $opt in
        y)
            yum_config=$OPTARG
            ;;
        h)
            usage
            ;;
        \?)
            echo "Invalid option: -$OPTARG"
            usage
            ;;
    esac
done
shift $((OPTIND - 1))
name=$1

if [[ -z $name ]]; then
    usage
fi

#--------------------

#target=$(mktemp -d --tmpdir $(basename $0).XXXXXX)
target=$PWD/centos_mkroot

set -x

for dev in console null zero urandom; do
    /sbin/MAKEDEV -d "$target"/dev -x $dev
done

package_to_install="@base @core @debugging @directory-client @guest-agents
                    @hardware-monitoring @network-file-system-client @performance @remote-system-management
                    grub2 kernel kernel-devel epel-release ansible"

setopt="group_package_types=mandatory,default,optional"

enabled_repos="base,extras,updates"

yum -c "$yum_config" --installroot="$target" -y --setopt=$setopt install $package_to_install

cat > "$target"/etc/sysconfig/network <<EOF
NETWORKING=yes
HOSTNAME=localhost.localdomain
EOF

# effectively: febootstrap-minimize --keep-zoneinfo --keep-rpmdb
# --keep-services "$target".  Stolen from mkimage-rinse.sh
#  locales
# rm -rf "$target"/usr/{{lib,share}/locale,{lib,lib64}/gconv,bin/localedef,sbin/build-locale-archive}
#  docs
# rm -rf "$target"/usr/share/{man,doc,info,gnome/help}
#  cracklib
# rm -rf "$target"/usr/share/cracklib
#  i18n
# rm -rf "$target"/usr/share/i18n
#  sln
# rm -rf "$target"/sbin/sln

#  ldconfig
rm -rf "$target"/etc/ld.so.cache
rm -rf "$target"/var/cache/ldconfig/*

cd $target/boot
ln -sf $(ls -1 vmlinuz-* | tail -1) vmlinuz
ln -sf $(ls -1 initramfs-* | tail -1) initrd.img
cd -

version=
if [ -r "$target"/etc/redhat-release ]; then
    version="$(sed 's/^[^0-9\]*\([0-9.]\+\).*$/\1/' /etc/redhat-release)"
fi

if [ -z "$version" ]; then
    echo >&2 "warning: cannot autodetect OS version, using '$name' as tag"
    version=$name
fi

#tar --numeric-owner -c -C "$target" . | docker import - $name:$version
#docker run -i -t $name:$version echo success
cp -a /dev/urandom centos_mkroot/dev/
cp -a /dev/random centos_mkroot/dev/
#tar zcvf centos_mkroot.tar.gz centos_mkroot/
ansible-playbook -i tsg-9140-scripts/install_config/tsg_9140_host tsg-9140-scripts/tsg_9140_deploy.yml
yum -c "$yum_config" --installroot="$target" -y --setopt=$setopt clean all
rm -rf centos_mkroot/tmp/*
tar --numeric-owner -c -C centos_mkroot/ . | pbzip2 -p9 > input/centos-7-chroot.tar.bz2

#rm -rf "$target"
