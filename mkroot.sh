#!/bin/sh

if [ -d rootfs ]; then
    echo Error: rootfs already exists
    exit 1
fi
if [ `id -u` -ne 0 ]; then
    echo Please run as root
    exit 2
fi

. `dirname $0`/common.sh.inc

MIRROR=http://httpredir.debian.org/debian
KEY=EF0F382A1A7B6500

set -e

log "downloading Debian/stretch gpg keys"
gpg --keyserver pgpkeys.mit.edu --no-default-keyring --keyring=raspikeys.gpg --recv-key $KEY

log "running debootstrap"

debootstrap --arch arm64 --foreign --variant=minbase --components=main,non-free --include=gnupg1 --keyring=raspikeys.gpg stretch rootfs $MIRROR

mkdir -p rootfs/usr/share/keyrings/
cp /usr/share/keyrings/debian-archive-keyring.gpg rootfs/usr/share/keyrings/

cp /usr/bin/qemu-aarch64-static rootfs/usr/bin/

chroot rootfs /debootstrap/debootstrap --second-stage || true # this return 2 somehow

log "installing software"
cat rootfs/etc/apt/sources.list
echo "deb $MIRROR stretch main non-free" > rootfs/etc/apt/sources.list
gpg --keyring=raspikeys.gpg --armor --export $KEY | chroot rootfs apt-key add -

chroot rootfs apt-get -o Acquire::Languages=none update || true # this fails the first time
chroot rootfs apt-get -o Acquire::Languages=none update
DEBIAN_FRONTEND=non-interactive chroot rootfs apt-get install --no-install-recommends --yes vim ssh bash-completion net-tools isc-dhcp-client sudo kmod udev firmware-brcm80211 \
    xorg xfonts-base slim i3 i3status suckless-tools

log "creating user"
chroot rootfs useradd -U -m -G sudo pi
echo "pi:1234" | chroot rootfs chpasswd
echo "root:1234" | chroot rootfs chpasswd

#rm -f rootfs/usr/bin/qemu-aarch64-static

