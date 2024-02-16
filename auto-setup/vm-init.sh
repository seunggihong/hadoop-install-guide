#!/bin/bash

# Type info
read -p "|       Static IP to use: " ip_address
read -p "|               NIC name: " nic_name

sudo apt-get update
sudo apt-get upgrade

# Install openjdk, python
sudo apt install openjdk-8-jdk
sudo apt install python3-pip

# Install hadoop
wget https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz
tar -xvf hadoop-3.3.6.tar.gz
mv hadoop-3.3.6 hadoop

# Change /etc/netplan/00-installer-config.yaml file
new_ip=$(echo "$ip_address" | sed 's/\.[0-9]*$/\.1/')

echo "# This is the network config written by 'subiquity'
network:
  ethernets:
    $nic_name:
        addresses:
            - $ip_address/24
        nameservers: [8.8.8.8, 8.8.4,4]
        routes
            - to: default
              via: $new_ip
  version: 2
EOF" | sudo tee /etc/netplan/00-installer-config.yaml > /dev/null

echo "-----------------------------------------------------------------"
echo "-----------------------------Result------------------------------"
echo "-----------------------------------------------------------------"
cat /etc/netplan/00-installer-config.yaml
echo "-----------------------------------------------------------------"

sudo netplan apply

# Delete the comment 'PubkeyAuthentication'.
file="/etc/ssh/sshd_config"
pattern="s/^#\(PubkeyAuthentication yes\)/\1/"
sudo sed -i "$pattern" "$file"