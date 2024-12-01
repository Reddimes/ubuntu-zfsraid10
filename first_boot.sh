#!/bin/bash

sudo apt full-upgrade
sudo dpkg-reconfigure grub-efi-amd64
sudo rm /etc/profile.d/first_boot.sh