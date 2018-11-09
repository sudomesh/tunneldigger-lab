#!/bin/bash

# Run the tunneldigger client
cd || exit
UUID=$(uuidgen)
sudo /opt/tunneldigger/client/tunneldigger -f -b 64.71.176.94:8942 -u "$UUID" -i l2tp0 -s /vagrant/tunnel_hook.sh
