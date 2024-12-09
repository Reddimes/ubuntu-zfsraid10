#!/bin/bash

bash
sudo apt full-upgrade --yes
sudo dpkg-reconfigure grub-efi-amd64
sudo apt autoremove --yes
sudo rm /etc/profile.d/first_boot.sh
