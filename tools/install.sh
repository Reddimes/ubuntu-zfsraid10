#!/bin/bash

git clone --depth 1 https://github.com/Reddimes/ubuntu-zfsraid10.git &> /dev/null
cd ubuntu-zfsraid10
chmod +x *.sh
sudo ./init.sh