#!/bin/bash

# Update chroot apt and install required packages.
# Also purge os-prober as it is not needed for my environment.
# Need to test doing a full-upgrade as well as some additional setup.
apt update
apt install --yes console-setup locales vim systemd-timesyncd dosfstools dpkg-dev linux-headers-generic linux-image-generic zfs-initramfs openssh-server
apt purge --yes os-prober
## Configure distribution settings.
dpkg-reconfigure locales tzdata keyboard-configuration console-setup

# Need to research exactly what this does, but was part of the tutorial I used to put this together.
echo REMAKE_INITRD=yes > /etc/dkms/zfs.conf

# Setup boot device and create /boot/efi
DISK=/dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV58DGK
mkdosfs -F 32 -s 1 -n EFI ${DISK}-part1
mkdir /boot/efi
## Add to fstab
echo /dev/disk/by-uuid/$(blkid -s UUID -o value ${DISK}-part1) \
   /boot/efi vfat defaults 0 0 >> /etc/fstab
sleep 2
## Mount /boot/efi to install grub
mount /boot/efi
apt install --yes grub-efi-amd64 shim-signed

# Add service for zfs import of the bpool
systemctl enable zfs-import-bpool.service

# Change to allow root to login to the server over ssh for server setup.
sed -i '/#PermitRootLogin/a PermitRootLogin yes' /etc/ssh/sshd_config

# Reset initramfs to use the added boot partition.
update-initramfs -c -k all

# Grub setup
cp ./grub /etc/default/grub
update-grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi \
    --bootloader-id=ubuntu --recheck --no-floppy

# Fix Filesystem mounting order
mkdir /etc/zfs/zfs-list.cache
touch /etc/zfs/zfs-list.cache/bpool
touch /etc/zfs/zfs-list.cache/rpool

# Check the cache and make sure that it is updating
# zed -F &
# ZEDPID=$!

#This is for testing


# Need to copy DISK-part1 to other disks-part1
