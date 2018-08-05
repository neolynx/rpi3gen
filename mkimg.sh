#!/bin/sh

set -e

finish()
{
    if [ -n "$disk" ]; then
        losetup -d $disk
    fi

    if [ -d target ]; then
        umount -R target
        rmdir target
    fi
}

trap finish EXIT

echo creating image ...

rm -f raspi.img
fallocate -l 1200M raspi.img

sfdisk -q raspi.img << EOF
unit: sectors
raspi.img1 : start=2048, size=131072, type=c
raspi.img2 : start=133120, type=83
EOF

disk=`losetup -P -f --show raspi.img`

mkfs.vfat ${disk}p1 >/dev/null
mkfs.ext4 -q -F ${disk}p2 2>/dev/null

mkdir target
mount ${disk}p2 target
mkdir -p target/boot/firmware
mount ${disk}p1 target/boot/firmware

echo copying rootfs ...
rsync -a rootfs/ target/
echo installing kernel modules ...

cd linux
make -j`nproc` ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- INSTALL_MOD_STRIP=1 INSTALL_MOD_PATH=../target/ modules_install >/dev/null
cd ..

echo creating fstab ...
cat > target/etc/fstab << EOF
/dev/mmcblk0p2 / ext4 errors=remount-ro 0 1
/dev/mmcblk0p1 /boot/firmware vfat defaults 0 2
EOF

echo reducing image size ...
rm -f target/var/lib/apt/lists/* 2>/dev/null || true

echo copying raspberry firmware ...
cp raspberry-firmware/boot/* target/boot/firmware/

echo copying u-boot ...
cp u-boot/u-boot.bin target/boot/firmware/

echo installing kernel ...
mkimage -A arm64 -O linux -T kernel -C gzip -a 0x80000 -e 0x80000 -d linux/arch/arm64/boot/Image.gz target/boot/firmware/uImage >/dev/null

echo creating u-boot config ...
mkenvimage -s 16384 u-boot.env.txt -o target/boot/firmware/uboot.env

echo installing dtb ...
cp linux/arch/arm64/boot/dts/broadcom/bcm2837-rpi-3-b.dtb target/boot/firmware/

echo copying config.txt ...
cp config.txt target/boot/firmware/

echo disk usage:
echo "Filesystem                    Size  Used Avail Use% Mounted on"
df -h | grep $disk

echo cleanup ...
umount -R target
rmdir target

losetup -d $disk
disk=""

