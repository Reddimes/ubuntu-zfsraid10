# ZFS RAID 10
The purpose of this repository is to automatically setup a booting zfs ubuntu host.  The fastest way to get it running is as follows:

## Generic Install
It is best to run these scripts from an Ubuntu Live Instance, preferably ubuntu-server as it is all that I have tested thus far.  It may work with other Ubuntu Distributions as well.
I Personally used the instance from this link: https://ubuntu.com/download/server/.

Here is the command you need to get this started.
```
bash <(wget -qO- https://raw.githubusercontent.com/Reddimes/ubuntu-zfsraid10/refs/heads/main/tools/install.sh)
```

## Custom Install
If you need to customize the installation.  You need to do the following:
```
git clone --depth 1 https://github.com/Reddimes/ubuntu-zfsraid10.git
cd ./ubuntu-zfsraid10
```
Once you have cloned the git repository, you can make changes as you see fit.  You can changed the files that get copied over by editing the `./Plan/` folder.  This folder gets copied to the root of your installation.  So `./Plan/etc/apt/sources.list.d/ubuntu.sources` gets copied to `/etc/apt/sources.list.d/ubuntu.sources`.

### Config Files
You'll notice some other default files which you can either edit or delete:
- `./Plan/etc/apt/sources.list`
  - This is meant for if you want to customize what apt sources are available to you.  It's currently empty, but I wanted to provide a file in it's place in case it is needed for your installation.
- `./Plan/etc/apt/sources.list.d/ubuntu.sources`
  - This is the default sources that are provided by the Live CD, I've just broken it out so you can either use it or customize it.
- `./Plan/etc/apt/trusted.gpg.d/`
  - In case you are adding any additional sources and also need to have the gpg keys installed.
- `./Plan/etc/default/grub`
  - This file is a customized grub config to account for the ZFS installation and also set grub to use debug mode by default.
- `./Plan/etc/netplan/50-cloud-init.yaml`
  - The default netplan ripped straight out of the Live CD.  If you need to use your own netplan(for a static ip or vlans), go ahead and edit it.
- `./Plan/etc/systemd/system/zfs-import-bpool.service`
  - This service is meant to properly import the bpool(/boot) and is kind of necessary.
- `./Plan/chroot.sh`
  - This particular script is temporary.  It is meant to be run inside of the chroot into the ZFS installation before the first boot.  Once it has run, it gets deleted.

## Architecture
This particular script is designed to create two seperate zpools: /boot and /.  This is because the grub requirements limit the other features of ZFS and I would rather that we are able to utilize them.  This is designed specifically for a ZFS RAID 10, but you can customize it to whatever works best for you.  You should also note that it is designed to be UEFI, **not legacy**.  For a legacy install, you need to change `./init.sh` to partition the drive properly and a whole bunch of other stuff that I'm happy to answer questions on, but too lazy to look up at the moment.

### Scripts
There are four total scripts.

**The first Script**

`./tools/install.sh` is designed to run the generic installation with the following command:
```
bash <(wget -qO- https://raw.githubusercontent.com/Reddimes/ubuntu-zfsraid10/refs/heads/main/tools/install.sh)
```

**The Second Script**

`./init.sh` is meant to be our entrypoint and in fact the command above runs it as sudo.  This script wipes the filesystems, removes all partitions, and uses debootrap to install Ubuntu.  Then it copies over all the config files and launches the `chroot.sh` script.

**The Third Script**

The `./Plan/chroot.sh` script sets up the defaults for the environment and it has a few hands on sections where you need to configure it.

**The Fourth Script**

Finally, `./first_boot.sh` gets copied to `/etc/profile.d/first_boot.sh` after the `./Plan/chroot.sh` script finishes.  We technically login to bash with that script and we don't want those commands to run until after the first boot.  This doesn't actually run the script immediately upon reboot, it runs whenever the first user logs in.

Once you login, It performs the following:
```
sudo apt update
sudo apt full-upgrade --yes
sudo dpkg-reconfigure grub-efi-amd64
sudo apt autoremove --yes
sudo rm /etc/profile.d/first_boot.sh
```
First, it complete the installation.  Then it reconfigures grub with some interaction required.  I personally set all the drives in my ZFS RAID 10 to have grub installed, though only one is in fstab.  Perhaps this is a design flaw, but I need to understand more before I make a more appropriate setup.  The autoremove command gets rid of grub-pc since it is unused in this installation.  Finally, you'll notice that it self deletes to prevent it from running again.
