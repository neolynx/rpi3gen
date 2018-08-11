#!/bin/sh
set -e
if [ `id -u` -eq 0 ]; then
    echo Please do not run as root
    exit 1
fi

. `dirname $0`/common.sh.inc

if [ ! -d u-boot ]; then
    log "cloning u-boot"
    git clone --depth 1 git://git.denx.de/u-boot.git
    cd u-boot
    git am ../u-boot-increate-bootm-size.patch >/dev/null
    cd ..
fi

log "building u-boot"
cd u-boot
make -j`nproc` ARCH=arm CROSS_COMPILE=aarch64-linux-gnu- rpi_3_defconfig >/dev/null
make -j`nproc` ARCH=arm CROSS_COMPILE=aarch64-linux-gnu-
cd ..

if [ ! -d linux ]; then
    log "cloning kernel"
    git clone --depth 1 https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
fi

log "building kernel"
cd linux
cp ../raspi_defconfig arch/arm64/configs/
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- raspi_defconfig >/dev/null
make -j`nproc` ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- Image.gz modules broadcom/bcm2837-rpi-3-b.dtb
cd ..
