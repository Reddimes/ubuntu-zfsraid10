#!/bin/bash

# Function to handle errors
error_handler() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo -e "\e[31mThe script exited with status ${exit_code}.\e[0m" 1>&2
        exit ${exit_code}
    fi
}

trap error_handler EXIT

# Function to run commands and capture stderr
run_cmd() {
    local cmd="$1"
    local stderr_file=$(mktemp)

    if ! eval "$cmd" > /dev/null 2>$stderr_file; then
        echo -e "\e[31mError\n Command '$cmd' failed with output:\e[0m" 1>&2
        cat $stderr_file | awk '{print " \033[31m" $0 "\033[0m"}' 1>&2
        rm -f $stderr_file
        exit 1
    fi

    rm -f $stderr_file
}

# Function to print OK message in green
print_ok () {
    echo -e "\e[32mOK\e[0m"
}

prerequisites () {
	echo -n "Installing prerequisites..."
	run_cmd "apt install --yes debootstrap gdisk zfsutils-linux"
	print_ok
}

partition () {
	echo -n "Wiping filesystems..."
	run_cmd "wipefs -a /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV58DGK"
	run_cmd "wipefs -a /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV42Y5X"
	run_cmd "wipefs -a /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV4HRM7"
	run_cmd "wipefs -a /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV4Q8GG"
	print_ok

	echo -n "Zapping partitions..."
	run_cmd "sgdisk --zap-all /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV58DGK"
	run_cmd "sgdisk --zap-all /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV42Y5X"
	run_cmd "sgdisk --zap-all /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV4HRM7"
	run_cmd "sgdisk --zap-all /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV4Q8GG"
	print_ok

	echo -n "Creating partitions..."
	run_cmd "sgdisk     -n1:1M:+512M   -t1:EF00 /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV58DGK"
	run_cmd "sgdisk     -n1:1M:+512M   -t1:EF00 /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV42Y5X"
	run_cmd "sgdisk     -n1:1M:+512M   -t1:EF00 /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV4HRM7"
	run_cmd "sgdisk     -n1:1M:+512M   -t1:EF00 /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV4Q8GG"
	run_cmd "sgdisk     -n2:0:+1G      -t2:BE00 /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV58DGK"
	run_cmd "sgdisk     -n2:0:+1G      -t2:BE00 /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV42Y5X"
	run_cmd "sgdisk     -n2:0:+1G      -t2:BE00 /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV4HRM7"
	run_cmd "sgdisk     -n2:0:+1G      -t2:BE00 /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV4Q8GG"
	run_cmd "sgdisk     -n3:0:0        -t3:BF00 /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV58DGK"
	run_cmd "sgdisk     -n3:0:0        -t3:BF00 /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV42Y5X"
	run_cmd "sgdisk     -n3:0:0        -t3:BF00 /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV4HRM7"
	run_cmd "sgdisk     -n3:0:0        -t3:BF00 /dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV4Q8GG"
	print_ok

	# Sleep to allow time for partitions to be detected by zpool
	# Ten seconds is an arbitrary number I used to delay it, it could easily be shorter
	# and it was an arbitrary guess meant to make it work the first time.
	echo -n "Waiting for partitions..."
	sleep 10
	print_ok
}

createzpools () {
	echo -n "Create two zpools, one for /boot, and one for /..."
	run_cmd "
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
					/dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV4HRM7-part2 -f"
	
	run_cmd "
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
					/dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV4HRM7-part3 -f"
	print_ok

	echo -n "Configuring zpools..."

	# zpool configuration
	run_cmd "zfs create -o canmount=off -o mountpoint=none rpool/ROOT"
	run_cmd "zfs create -o canmount=off -o mountpoint=none bpool/BOOT"
	run_cmd "zfs create -o canmount=noauto -o mountpoint=/ rpool/ROOT/ubuntu"

	# Mount pool 
	run_cmd "zfs mount rpool/ROOT/ubuntu"
	run_cmd "zfs create -o mountpoint=/boot bpool/BOOT/ubuntu"

	## This creates a few extra mounts to isolate data from the rest of linux.
	## Take a look at whether you need them or not.
	run_cmd "zfs create                     rpool/home"
	run_cmd "zfs create -o mountpoint=/root rpool/home/root"

	# Set permissions for root to be only intended for root.
	run_cmd "chmod 700 /mnt/root"
	run_cmd "zfs create -o canmount=off     rpool/var"
	run_cmd "zfs create -o canmount=off     rpool/var/lib"
	run_cmd "zfs create                     rpool/var/log"
	run_cmd "zfs create                     rpool/var/spool"
	
	## Disable snapshotting on the cache, nfs, and tmp.
	run_cmd "zfs create -o com.sun:auto-snapshot=false rpool/var/cache"
	run_cmd "zfs create -o com.sun:auto-snapshot=false rpool/var/lib/nfs"
	run_cmd "zfs create -o com.sun:auto-snapshot=false rpool/var/tmp"
	
	## Set permissions for tmp
	run_cmd "chmod 1777 /mnt/var/tmp"
	
	## Unecessary if you do not use spool
	run_cmd "zfs create rpool/srv"
	
	## Create dataset for /usr and /usr/local
	run_cmd "zfs create -o canmount=off rpool/usr"
	run_cmd "zfs create                 rpool/usr/local"
	
	## Create dataset for /tmp and set it to not snapshot.
	run_cmd "zfs create -o com.sun:auto-snapshot=false  rpool/tmp"
	
	## Set /tmp permissions
	run_cmd "chmod 1777 /mnt/tmp"
	
	# I need to read more on why this is a part of the process.
	run_cmd "mkdir /mnt/run"
	run_cmd "mount -t tmpfs tmpfs /mnt/run"
	run_cmd "mkdir /mnt/run/lock"
	print_ok
}

install () {
	echo -n "Installing ubuntu on the hard drive..."
	run_cmd "debootstrap noble /mnt http://archive.ubuntu.com/ubuntu"
	print_ok

	echo -n "Copying over files..."

	# Copy zpool cache to mounted installation.
	run_cmd "mkdir /mnt/etc/zfs"
	run_cmd "cp /etc/zfs/zpool.cache /mnt/etc/zfs/"

	# Networking setup
	run_cmd "echo cloudstack | sudo tee /mnt/etc/hostname"
	run_cmd "cp ./hosts /mnt/etc/hosts"

	# Copy over apt configuration and keyrings.  Remove sources.list if it even exists.  I'm not sure.
	run_cmd "cp ./ubuntu.sources /mnt/etc/apt/sources.list.d/ubuntu.sources"
	run_cmd "cp /usr/share/keyrings/ubuntu-archive-keyring.gpg /mnt/usr/share/keyrings/ubuntu-archive-keyring.gpg"
	run_cmd "rm -f /mnt/etc/apt/sources.list"

	# Copy over zpool import service which accounts for pre and post execution.
	run_cmd "cp ./zfs-import-bpool.service /mnt/etc/systemd/system/zfs-import-bpool.service"
	
	# Copy over script to be run in chroot
	run_cmd "cp ./chroot.sh /mnt/chroot.sh"

	# Copy over debug grub file
	run_cmd "cp ./grub /etc/default/grub"
	
	# Copy over grub configuration.
	########## Needs to be setup
	
	print_ok
}

prepareChroot () {
	# Set disk for chroot. This is temporary.
	DISK=/dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV58DGK
	## This section needs more research.
	run_cmd "mount --make-private --rbind /dev  /mnt/dev"
	run_cmd "mount --make-private --rbind /proc /mnt/proc"
	run_cmd "mount --make-private --rbind /sys  /mnt/sys"
}

runChroot () {
	echo "Running chroot:"
	chroot /mnt /usr/bin/env DISK=$DISK bash -c \"/chroot.sh\" --login
	echo "Done!"
}

# Main Script Execution
prerequisites
partition
createzpools
install
prepareChroot
runChroot