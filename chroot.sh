#!/bin/bash

# Function to handle errors
error_handler() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo -e "\e[31mThe script exited with status ${exit_code}.\e[0m" 1>&2
        cleanup
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

prequisites () {
   # Update chroot apt and install required packages.
   # Also purge os-prober as it is not needed for my environment.
   # Need to test doing a full-upgrade as well as some additional setup.
   echo -ne "\tInstalling isntallation prerequisites..."
   
   run_cmd "apt update"
   run_cmd "apt install --yes console-setup locales vim systemd-timesyncd dosfstools dpkg-dev linux-headers-generic linux-image-generic zfs-initramfs openssh-server"
   run_cmd "apt purge --yes os-prober"

   ## Configure distribution settings.
   run_cmd "dpkg-reconfigure locales tzdata keyboard-configuration console-setup"

   # Need to research exactly what this does, but was part of the tutorial I used to put this together.
   run_cmd "echo REMAKE_INITRD=yes > /etc/dkms/zfs.conf"
   print_ok
}

bigboot () {
   echo -ne "\tSetup boot device integration..."

   # Temporary disk to use for boot
   DISK=/dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV58DGK

   # Create Boot partition
   run_cmd "mkdosfs -F 32 -s 1 -n EFI ${DISK}-part1"
   run_cmd "mkdir /boot/efi"
   
   # Add to fstab
   run_cmd "echo /dev/disk/by-uuid/$(blkid -s UUID -o value ${DISK}-part1) \
      /boot/efi vfat defaults 0 0 >> /etc/fstab"

   # Wait for fstab to write
   sleep 2

   # Mount /boot/efi to install grub
   run_cmd "mount /boot/efi"
   run_cmd "apt install --yes grub-efi-amd64 shim-signed"

   # Add service for zfs import of the bpool
   run_cmd "systemctl enable zfs-import-bpool.service"

   # Change to allow root to login to the server over ssh for server setup.
   run_cmd "sed -i '/#PermitRootLogin/a PermitRootLogin yes' /etc/ssh/sshd_config"

   # Reset initramfs to use the added boot partition.
   run_cmd "update-initramfs -c -k all"

   # Grub setup
   run_cmd "update-grub"
   run_cmd "grub-install --target=x86_64-efi --efi-directory=/boot/efi \
      --bootloader-id=ubuntu --recheck --no-floppy"
   print_ok
}

fixfs () {
   echo -ne "\tFix Filesystem mounting order..."
   run_cmd "mkdir /etc/zfs/zfs-list.cache"
   run_cmd "touch /etc/zfs/zfs-list.cache/bpool"
   run_cmd "touch /etc/zfs/zfs-list.cache/rpool"
   print_ok
}

prerequisites
bigboot
fixfs
bash

# Check the cache and make sure that it is updating
# zed -F &
# ZEDPID=$!

#This is for testing


# Need to copy DISK-part1 to other disks-part1
