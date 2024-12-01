# ubuntu-zfsraid10
The purpose of this repository is to automatically setup a booting zfs ubuntu host.

## Starting Point
It is best to run these scripts from an Ubuntu Live Instance, preferably ubuntu-server as it is all that I have tested thus far.  It may work with other Ubuntu Distributions as well.
I Personally used the instance from this link: https://ubuntu.com/download/server

## Architecture
This particular script is designed to create two seperate zpools: /boot and /.  This is because the grub requirements limit the other features of ZFS and I would rather that we are able to utilize them.  This is designed specifically for a ZFS RAID 10, but you can customize it to whatever works best for you.  You should also note that it is designed to be UEFI, not legacy.

### Configuration files
There are a few config files that I've used.

I provide my grub config file because it is already set up to allow for easy debugging.

I also provide a zfs-import-bpool service to properly account for Pre and Post execution.

Beyond that, I copy over the live netplan to be used in the new installation.  This means the server will automatically get dhcp on each network that it is connected to.

Currently, it sets the hostname as cloudstack, but I will have this asking for a hostname eventually.

It also copies over the `/etc/apt/sources.list.d/ubuntu.sources` and `/usr/share/keyrings/ubuntu-archive-keyring.gpg` from the live instance as well.

### Scripts
There are four total scripts.
The first one is designed to run the installation with the following command:

`bash <(wget -qO- https://raw.githubusercontent.com/Reddimes/ubuntu-zfsraid10/refs/heads/main/tools/install.sh)`

`init.sh` is meant to be our entrypoint and in fact the command above runs it as sudo.  This script wipes the filesystems, removes all partitions, and uses debootrap to install Ubuntu, it copies over as many config files as it can as well.  Then it launches the `chroot.sh` script.  The `chroot.sh` script sets up the defaults for the environment and it has a few hands on sections where you need to configure it just a little.

After the `chroot` script finishes running, We copy over the `first_boot.sh` script into the `/etc/profile.d/` folder.  In order to run this script, you need to login.  Once you login, It performs a few hands on actions as well.  Then it self deletes.
