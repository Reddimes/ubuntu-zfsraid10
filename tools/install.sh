#!/bin/bash

TEMPDIR=$(mktemp -d)
cd TEMPDIR
git clone --depth 1 https://github.com/Reddimes/ubuntu-zfsraid10.git ./
chmod +x *.sh
sudo ./init.sh