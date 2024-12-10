#!/bin/bash

bash
sudo apt full-upgrade --yes
sudo dpkg-reconfigure grub-efi-amd64
sudo apt autoremove --yes
sudo zfs snapshot rpool/ROOT/debian@full-install
sudo zfs snapshot bpool/BOOT/debian@full-install
sudo rm /etc/profile.d/first_boot.sh
