#!/bin/bash

# Function to handle errors
error_handler () {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo -e "\e[31mThe script exited with status ${exit_code}.\e[0m" 1>&2
        exit ${exit_code}
    fi
}

trap error_handler EXIT

# Function to run commands and capture stderr
run_cmd () {
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
   # Update chroot apt and install required packages.
   # Also purge os-prober as it is not needed for my environment.
   # Need to test doing a full-upgrade as well as some additional setup.
   echo -n "Installing chroot prerequisites..."
   run_cmd "apt update"
   run_cmd "apt install --yes console-setup locales vim systemd-timesyncd dosfstools \
dpkg-dev linux-headers-generic linux-image-generic zfs-initramfs openssh-server \
tmux"
   run_cmd "apt purge --yes os-prober"
   print_ok

   echo "Configuring distribution settings:"
   dpkg-reconfigure locales tzdata keyboard-configuration console-setup

   # Need to research exactly what this does, but was part of the tutorial I used to put this together.
   # It doesn't seem to work with Ubuntu
   # echo REMAKE_INITRD=yes > /etc/dkms/zfs.conf
   print_ok
}

bigboot () {
   echo -n "Formatting Boot Partition..."

   # Create Boot partition
   run_cmd "mkdosfs -F 32 -s 1 -n EFI ${DISK}-part1"
   run_cmd "mkdir /boot/efi"
   print_ok
   
   # Add to fstab
   echo -n "Adding to fstab..."
   run_cmd "echo /dev/disk/by-uuid/$(blkid -s UUID -o value ${DISK}-part1) \
      /boot/efi vfat defaults 0 0 >> /etc/fstab"

   # Wait for fstab to write
   sleep 5
   print_ok

   # Mount /boot/efi to install grub
   echo -n "Mounting and Installing grub-efi..."
   run_cmd "mount /boot/efi"
   sleep 5
   run_cmd "apt install --yes grub-efi-amd64 shim-signed"
   print_ok

   # Add service for zfs import of the bpool
   run_cmd "systemctl enable zfs-import-bpool.service"

   # Reset initramfs to use the added boot partition.
   run_cmd "update-initramfs -c -k all"

   # Grub setup
   echo -n "Updating grub and installing grub-efi..."
   run_cmd "update-grub"
   run_cmd "grub-install --target=x86_64-efi --efi-directory=/boot/efi \
      --bootloader-id=Ubuntu --recheck --no-floppy"
   print_ok
}

additionalPrep () {
   echo -n "Fix Filesystem mounting order..."
   run_cmd "mkdir /etc/zfs/zfs-list.cache"
   run_cmd "touch /etc/zfs/zfs-list.cache/bpool"
   run_cmd "touch /etc/zfs/zfs-list.cache/rpool"
   print_ok

   # Check the cache and make sure that it is updating
   zed -F &> /dev/null &
   ZEDPID=$!

   sleep 1
   while [[ ! -s /etc/zfs/zfs-list.cache/bpool || ! -s /etc/zfs/zfs-list.cache/rpool ]]
   do
      if [ $LOOP -lt 1 ]
      then
         zfs set canmount=on bpool/BOOT/ubuntu
         zfs set canmount=noauto rpool/ROOT/ubuntu
      else
         kill $ZEDPID
         sleep 1
         zed -F &> /dev/null &
         ZEDPID=$!
         sleep 1
      fi
      ((LOOP++))
   done

   if [ $ADMINUSER != "root" ]
   then
      adduser $ADMINUSER
      sleep 2
      run_cmd "cp -a /etc/skel/. /home/$ADMINUSER"
      run_cmd "chown -R $ADMINUSER:$ADMINUSER /home/$ADMINUSER"
      run_cmd "usermod -a -G audio,cdrom,dip,floppy,plugdev,sudo,video $ADMINUSER"
   else
      passwd
   fi

   kill $ZEDPID

   # Fix Mount paths supposedly
   sed -Ei "s|/mnt/?|/|" /etc/zfs/zfs-list.cache/*
}

# Main Script Execution
prerequisites
bigboot
additionalPrep