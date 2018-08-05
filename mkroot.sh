#!/bin/sh
set -e

if [ -d rootfs ]; then
    echo Error: rootfs already exists
    exit -1
fi

echo " * running debootstrap"
qemu-debootstrap --arch=arm64 --variant=minbase stretch rootfs >/dev/null || true
# this returns 2 somehow...

echo " * installing software"
chroot rootfs apt-get install -y vim ssh bash-completion net-tools isc-dhcp-client sudo kmod udev

echo " * creating user"
chroot rootfs useradd -U -m -G sudo pi
echo "pi:1234" | chroot rootfs chpasswd
echo "root:1234" | chroot rootfs chpasswd
