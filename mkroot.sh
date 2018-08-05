#!/bin/sh

set -x

qemu-debootstrap --arch=arm64 --variant=minbase stretch rootfs
echo $?

chroot rootfs apt-get install -y vim ssh bash-completion net-tools isc-dhcp-client sudo kmod
chroot rootfs useradd -U -m -G sudo pi
echo "pi:1234" | chroot rootfs chpasswd
echo "root:1234" | chroot rootfs chpasswd
