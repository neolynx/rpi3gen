#!/bin/sh

set -e

if [ ! -d u-boot ]; then
    echo " * cloning u-boot"
    git clone --depth 1 git://git.denx.de/u-boot.git
    cd u-boot
    git am ../u-boot-increate-bootm-size.patch >/dev/null
    cd ..
fi

echo " * building u-boot"
cd u-boot
make -j`nproc` ARCH=arm CROSS_COMPILE=aarch64-linux-gnu- rpi_3_defconfig >/dev/null
make -j`nproc` ARCH=arm CROSS_COMPILE=aarch64-linux-gnu-
cd ..

if [ ! -d linux ]; then
    echo " * cloning kernel"
    git clone --depth 1 https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
fi

echo " * building kernel"
cd linux
cp ../raspi_defconfig arch/arm64/configs/
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- raspi_defconfig >/dev/null
make -j`nproc` ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- Image.gz modules broadcom/bcm2837-rpi-3-b.dtb
cd ..
