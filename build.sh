#!/bin/sh

set -e

echo " u-boot"
echo "========="
echo

cd u-boot
git clean -dfx
make -j`nproc` ARCH=arm CROSS_COMPILE=aarch64-linux-gnu- rpi_3_defconfig
make -j`nproc` ARCH=arm CROSS_COMPILE=aarch64-linux-gnu-
cd ..

echo
echo " linux"
echo "========="
echo

cd linux
git clean -dfx
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- raspi_defconfig
#cp -f ../rpi23-gen-image/working-rpi3-linux-config.txt .config
make -j`nproc` ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- Image.gz modules broadcom/bcm2837-rpi-3-b.dtb
cd ..
