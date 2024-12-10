#!/bin/bash

git clone -b debian-raidz1 --depth 1 https://github.com/Reddimes/ubuntu-zfsraid10.git &> /dev/null
cd ubuntu-zfsraid10
sudo ./init.sh