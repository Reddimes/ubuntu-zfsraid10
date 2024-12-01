#!/bin/bash

TDIR=$(mktemp -d)
echo $TDIR
echo $(pwd)
cd $TDIR
echo $(pwd)
git clone --depth 1 https://github.com/Reddimes/ubuntu-zfsraid10.git ./
chmod +x *.sh
sudo ./init.sh