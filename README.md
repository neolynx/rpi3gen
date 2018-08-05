# rpi3gen - Create raspberry pi 3 images

* minimal Debian/stretch
* mainline u-boot built form source
* mainline Linux kernel built form source


## Create image

Run `mkimg.sh` as root:

```
$ sudo ./mkimg.sh
Creating image for raspberry pi 3
 * installing dependencies
Building mainline kernel and u-boot
 * cloning u-boot
 * building u-boot
scripts/kconfig/conf  --syncconfig Kconfig
  CHK     include/config.h
  UPD     include/config.h
  CFG     u-boot.cfg
[...]
  COPY    u-boot.bin
  CFGCHK  u-boot.cfg
 * cloning kernel
 * building kernel
scripts/kconfig/conf  --syncconfig Kconfig
  WRAP    arch/arm64/include/generated/uapi/asm/errno.h
  WRAP    arch/arm64/include/generated/uapi/asm/ioctl.h
[...]
  LD [M]  net/rfkill/rfkill.ko
  LD [M]  net/wireless/cfg80211.ko
Creating rootfs (Debian/stretch)
 * running debootstrap
I: Running command: debootstrap --arch arm64 --foreign --variant=minbase stretch rootfs
I: Running command: chroot rootfs /debootstrap/debootstrap --second-stage
 * installing software
Reading package lists... Done
[...]
 * creating user
 * creating image
 * copying rootfs
 * reducing image size
 * creating fstab
 * installing kernel, modules and dtb
 * downloading raspberry firmware
 * copying u-boot and config
 * compressing image and cleanup
Image is ready: raspi.img.xz
```

## Requirements

* Ubuntu >= 17.10 (cross gcc arm64 7.2)

