#!/bin/sh
set -e
if [ `id -u` -ne 0 ]; then
    echo Please run as root
    exit 1
fi

unpriv_cmd()
{
    if [ -n "$SUDO_USER" ]; then
        sudo -u $SUDO_USER -- "$@"
    else
        $@
    fi
}

cleanup()
{
    if [ -d target ]; then
        umount -R target
        unpriv_cmd rmdir target
    fi
    if [ -n "$disk" ]; then
        losetup -d $disk
        disk=""
    fi
}

finish()
{
    set +e
    cleanup
}
trap finish EXIT

echo "Creating image for raspberry pi 3"
echo " * installing dependencies"
apt-get install -q -y u-boot-tools pxz crossbuild-essential-arm64 debootstrap qemu-user-static >/dev/null

if [ ! -f linux/arch/arm64/boot/Image.gz -o ! -f u-boot/u-boot.bin ]; then
    echo "Building mainline kernel and u-boot"
    unpriv_cmd ./build.sh
fi
if [ ! -d rootfs ]; then
    echo "Creating rootfs (Debian/stretch)"
    ./mkroot.sh
fi

echo " * creating image"
unpriv_cmd rm -f raspi.img
unpriv_cmd fallocate -l 1200M raspi.img
unpriv_cmd sfdisk -q raspi.img << EOF
unit: sectors
raspi.img1 : start=2048, size=131072, type=c
raspi.img2 : start=133120, type=83
EOF
disk=`losetup -P -f --show raspi.img`
mkfs.vfat ${disk}p1 >/dev/null
mkfs.ext4 -q -F ${disk}p2 2>/dev/null
unpriv_cmd mkdir target
mount ${disk}p2 target
mkdir -p target/boot/firmware
mount ${disk}p1 target/boot/firmware
mkdir target/boot/firmware/broadcom/

echo " * copying rootfs"
chroot rootfs apt-get clean
rsync -a rootfs/ target/
echo " * reducing image size"
rm -f target/var/lib/apt/lists/* 2>/dev/null || true

echo " * creating fstab"
cat > target/etc/fstab << EOF
/dev/mmcblk0p2 / ext4 errors=remount-ro 0 1
/dev/mmcblk0p1 /boot/firmware vfat defaults 0 2
EOF

echo " * installing kernel, modules and dtb"
mkimage -A arm64 -O linux -T kernel -C gzip -a 0x80000 -e 0x80000 -d linux/arch/arm64/boot/Image.gz target/boot/firmware/uImage >/dev/null
cd linux
make -j`nproc` ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- INSTALL_MOD_STRIP=1 INSTALL_MOD_PATH=../target/ modules_install >/dev/null
kernelversion=`make -s ARCH=arm64 kernelversion`
cd ..
cp linux/arch/arm64/boot/dts/broadcom/bcm2837-rpi-3-b.dtb target/boot/firmware/broadcom/
cp linux/.config target/boot/config-$kernelversion

echo " * downloading raspberry firmware"
wget -q https://github.com/raspberrypi/firmware/raw/master/boot/bootcode.bin -P target/boot/firmware/
wget -q https://github.com/raspberrypi/firmware/raw/master/boot/fixup.dat    -P target/boot/firmware/
wget -q https://github.com/raspberrypi/firmware/raw/master/boot/start.elf    -P target/boot/firmware/
cp config.txt target/boot/firmware/

echo " * copying u-boot and config"
cp u-boot/u-boot.bin target/boot/firmware/
mkenvimage -s 16384 u-boot.env.txt -o target/boot/firmware/uboot.env

echo " * compressing image and cleanup"
pxz raspi.img
cleanup
echo Image is ready: raspi.img.xz
