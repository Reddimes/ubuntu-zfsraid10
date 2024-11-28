#!/bin/bash

# Install what is necessary to run our configuration on the live cd.
apt install debootstrap gdisk zfsutils-linux -y

# Wipe disk and repartition the HDDs
wipefs -a /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV58DGK
wipefs -a /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV42Y5X
wipefs -a /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV4HRM7
wipefs -a /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV4Q8GG
sgdisk --zap-all /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV58DGK
sgdisk --zap-all /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV42Y5X
sgdisk --zap-all /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV4HRM7
sgdisk --zap-all /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV4Q8GG
sgdisk     -n1:1M:+512M   -t1:EF00 /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV58DGK
sgdisk     -n1:1M:+512M   -t1:EF00 /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV42Y5X
sgdisk     -n1:1M:+512M   -t1:EF00 /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV4HRM7
sgdisk     -n1:1M:+512M   -t1:EF00 /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV4Q8GG
sgdisk     -n2:0:+1G      -t2:BE00 /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV58DGK
sgdisk     -n2:0:+1G      -t2:BE00 /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV42Y5X
sgdisk     -n2:0:+1G      -t2:BE00 /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV4HRM7
sgdisk     -n2:0:+1G      -t2:BE00 /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV4Q8GG
sgdisk     -n3:0:0        -t3:BF00 /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV58DGK
sgdisk     -n3:0:0        -t3:BF00 /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV42Y5X
sgdisk     -n3:0:0        -t3:BF00 /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV4HRM7
sgdisk     -n3:0:0        -t3:BF00 /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV4Q8GG

# Sleep to allow time for partitions to be detected by zpool
# Ten seconds is an arbitrary number I used to delay it, it could easily be shorter
# and it was an arbitrary guess meant to make it work the first time.
echo "Sleeping..."
sleep 10

# Create two zpools, one for /boot, and one for the root directory(/)
zpool create \
-o ashift=12 \
-o autotrim=on \
-o compatibility=grub2 \
-o cachefile=/etc/zfs/zpool.cache \
-O devices=off \
-O acltype=posixacl -O xattr=sa \
-O compression=lz4 \
-O normalization=formD \
-O relatime=on \
-O canmount=off -O mountpoint=/boot -R /mnt \
bpool \
mirror \
/dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV58DGK-part2 \
/dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV42Y5X-part2 \
mirror \
/dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV4Q8GG-part2 \
/dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV4HRM7-part2 -f
zpool create \
-o ashift=12 \
-o autotrim=on \
-O acltype=posixacl -O xattr=sa -O dnodesize=auto \
-O compression=lz4 \
-O normalization=formD \
-O relatime=on \
-O canmount=off -O mountpoint=/ -R /mnt \
rpool \
mirror \
/dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV58DGK-part3 \
/dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV42Y5X-part3 \
mirror \
/dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV4Q8GG-part3 \
/dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV4HRM7-part3 -f

# zpool configuration
zfs create -o canmount=off -o mountpoint=none rpool/ROOT
zfs create -o canmount=off -o mountpoint=none bpool/BOOT
zfs create -o canmount=noauto -o mountpoint=/ rpool/ROOT/ubuntu
# Mount pool 
zfs mount rpool/ROOT/ubuntu
zfs create -o mountpoint=/boot bpool/BOOT/ubuntu
## This creates a few extra mounts to isolate data from the rest of linux.
## Take a look at whether you need them or not.
zfs create                     rpool/home
zfs create -o mountpoint=/root rpool/home/root
# Set permissions for root to be only intended for root.
chmod 700 /mnt/root
zfs create -o canmount=off     rpool/var
zfs create -o canmount=off     rpool/var/lib
zfs create                     rpool/var/log
zfs create                     rpool/var/spool
## Disable snapshotting on the cache, nfs, and tmp.
zfs create -o com.sun:auto-snapshot=false rpool/var/cache
zfs create -o com.sun:auto-snapshot=false rpool/var/lib/nfs
zfs create -o com.sun:auto-snapshot=false rpool/var/tmp
## Set permissions for tmp
chmod 1777 /mnt/var/tmp
## Unecessary if you do not use spool
zfs create rpool/srv
## Create dataset for /usr and /usr/local
zfs create -o canmount=off rpool/usr
zfs create                 rpool/usr/local
## Create dataset for /tmp and set it to not snapshot.
zfs create -o com.sun:auto-snapshot=false  rpool/tmp
## Set /tmp ppermissions
chmod 1777 /mnt/tmp

# I need to read more on why this is a part of the process.
mkdir /mnt/run
mount -t tmpfs tmpfs /mnt/run
mkdir /mnt/run/lock

# Use debootstrap to install ubuntu on the hard drive,
debootstrap noble /mnt http://archive.ubuntu.com/ubuntu

# Copy zpool cache to mounted installation.
mkdir /mnt/etc/zfs
cp /etc/zfs/zpool.cache /mnt/etc/zfs/

# Networking setup
hostname cloudstack
hostname | sudo tee /mnt/etc/hostname
cp ./hosts /mnt/etc/hosts

# Copy over apt configuration and keyrings.  Remove sources.list if it even exists.  I'm not sure.
cp ./ubuntu.sources /mnt/etc/apt/sources.list.d/ubuntu.sources
cp /usr/share/keyrings/ubuntu-archive-keyring.gpg /mnt/usr/share/keyrings/ubuntu-archive-keyring.gpg
rm -f /mnt/etc/apt/sources.list

# Set disk for chroot.
DISK=/dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV58DGK
## This section needs more research.
mount --make-private --rbind /dev  /mnt/dev
mount --make-private --rbind /proc /mnt/proc
mount --make-private --rbind /sys  /mnt/sys

# Copy over chroot.sh and run it in the chroot environment.
cp ./chroot.sh /mnt/chroot.sh
chroot /mnt /usr/bin/env DISK=$DISK bash --login  #-c "/chroot.sh" --login
