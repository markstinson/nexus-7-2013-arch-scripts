#!/system/xbin/env ash

CHROOT="/data/arch"

echo "Downloading ArchLinuxARM-trimslice-latest.tar.gz..."
busybox wget -c http://tw.mirror.archlinuxarm.org/os/ArchLinuxARM-trimslice-latest.tar.gz

echo "Making 10GB image..."
busybox dd if=/dev/zero of=${CHROOT}.img bs=1M seek=10000 count=1

echo "Formating image..."
busybox mke2fs -L arch-image -F ${CHROOT}.img
busybox mkdir ${CHROOT}

echo "Making devices..."
busybox mknod /dev/loop256 b 7 256
busybox losetup /dev/loop256 ${CHROOT}.img || exit 1

echo "Mounting file systems..."
busybox mount -t ext4 -o rw,noatime /dev/block/loop256 ${CHROOT} || exit 1

echo "Extracting Arch system into image..."
busybox gunzip ArchLinuxARM-trimslice-latest.tar.gz -c | busybox tar x -f - -C ${CHROOT}

echo "Adding directories..."
busybox mkdir -p ${CHROOT}/media/sdcard
busybox mkdir -p ${CHROOT}/media/system
busybox mkdir -p ${CHROOT}/dev/pts
busybox mkdir ${CHROOT}/dev/ptmx

echo "Mounting extra file systems..."
busybox mount -o bind /dev/ ${CHROOT}/dev || exit 1
busybox mount -t proc proc ${CHROOT}/proc || exit 1
busybox mount -t sysfs sysfs ${CHROOT}/sys || exit 1
busybox mount -t devpts devpts ${CHROOT}/dev/pts || exit 1
busybox mount -o bind /sdcard ${CHROOT}/media/sdcard || exit 1

echo "Installing packages and upgrading system..."
echo "nameserver 8.8.8.8" > ${CHROOT}/etc/resolv.conf
echo "nexus7" > ${CHROOT}/etc/hostname
busybox chroot ${CHROOT} /usr/bin/env HOME=/root TERM="$TERM" PATH=/bin:/usr/bin:/sbin:/usr/sbin /bin/bash -c "source /etc/profile; groupadd -g 3003 aid_inet; groupadd -g 3004 inet; groupadd -g 3005 inetadmin; usermod -aG inet root; usermod -aG inetadmin root; pacman -Syyu --noconfirm; pacman -S --noconfirm xorg-server xorg-xrdb tightvnc xterm xorg-xsetroot xorg-xmodmap rxvt-unicode dwm pkg-config dmenu fakeroot zsh emacs vim git tmux mosh ruby python3 python2 sudo wget rsync base-devel; pacman -Rdd --noconfirm linux-firmware"

echo "Exiting chroot, unmounting..."
umount ${CHROOT}/media/sdcard || exit 1
umount ${CHROOT}/dev/pts || exit 1
umount ${CHROOT}/proc || exit 1
umount ${CHROOT}/sys || exit 1

echo "Killing existing processes in chroot..."
busybox fuser -mk ${CHROOT}
umount ${CHROOT}/dev || exit 1
umount ${CHROOT} || exit 1

echo "Deactivating loop..."
busybox losetup -d /dev/loop256

#echo "Deleting ArchLinuxARM-trimslice-latest.tar.gz..."
#rm ArchLinuxARM-trimslice-latest.tar.gz
