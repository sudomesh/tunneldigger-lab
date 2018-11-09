#!/bin/bash

sudo DEBIAN_FRONTEND=noninteractive apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
	tmux cmake libnl-3-dev libnl-genl-3-dev build-essential pkg-config
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "linux-image-extra-$(uname -r)"
sudo modprobe l2tp_netlink
sudo modprobe l2tp_eth
sudo modprobe l2tp_core

echo 'set -g default-terminal "screen-256color"' > ~/.tmux.conf

# Build tunneldigger in /opt/tunneldigger
mkdir -p /opt
cd /opt || exit
rm -rf tunneldigger
git clone https://github.com/wlanslovenija/tunneldigger.git
cd tunneldigger/client || exit
cmake .
make
#ip addr
#netstat -u
#sudo cat /var/log/syslog | grep td-client

# All that's left is to run the client!
