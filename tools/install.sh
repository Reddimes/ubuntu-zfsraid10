#!/bin/bash

TDIR=$(mktemp -d)
cd $TDIR
git clone --depth 1 https://github.com/Reddimes/ubuntu-zfsraid10.git ./ &> /dev/null
chmod +x *.sh
sudo ./init.sh"