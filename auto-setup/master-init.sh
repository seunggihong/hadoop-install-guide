#!/bin/bash

# Type info
read -p "|       Master IP to use: " master_ip
read -p "|     Master name to use: " master_name

read -p "|     Worker-1 ip to use: " worker_ip_1
read -p "|   Worker-1 name to use: " worker_name_1

read -p "|     Worker-2 ip to use: " worker_ip_2
read -p "|   Worker-2 name to use: " worker_name_2

read -p "|     Worker-3 ip to use: " worker_ip_3
read -p "|   Worker-3 name to use: " worker_name_3

# /ets/hosts file change

hosts_file_path="/etc/hosts"

echo "" > $hosts_file_path

echo "localhost 127.0.0.1

$master_ip $master_name
$worker_ip_1 $worker_name_1
$worker_ip_2 $worker_name_2
$worker_ip_3 $worker_name_3

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters" >> $hosts_file_path

echo "-----------------------------------------------------------------"
echo "-----------------------------Result------------------------------"
echo "-----------------------------------------------------------------"
cat $hosts_file_path
echo "-----------------------------------------------------------------"

