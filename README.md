# Hadoop install Guide
This repo is, describes how to build a `Hadoop` eco system using the `Oracle virtual machine`.

## Contents
1. [Setting VM](#setting)
2. [Install Hadoop](#install)
3. [Test HDFS](#test)


<a name='setting'></a>

## 1. Setting VM

We will create 4 VMs.

```
VM Spec.

master-node
    - Processor : 2
    - System memory : 4096 MB
    - Vedio memory : 16 MB

worker-node1~3
    - Processor : 2
    - System memory : 4096 MB
    - Vedio memory : 16 MB
```

The reason for using two processors is so that we can use Kubernetes later.
It doesn’t matter if you set it to default.

Now let's assign a static IP to each virtual machine.

I used a static IP like this:
```
master 
    - IP : 192.168.0.10
    - Port : 10
worker node 1 
    - IP : 192.168.0.11
    - Port : 11
worker node 2 
    - IP : 192.168.0.12
    - Port : 12
worker node 3
    - IP : 192.168.0.13
    - Port : 13
```

This is the network config file path.

```bash
$ sudo vi /etc/netplan/00-installer-config.yaml
```

Open the configuration file and enter the IP values ​​for each node. The following is an example master node setup.

```yaml
# This is the network config written by 'subiquity'
network:
    ethernets:
        enp0s3:
            addresses:
                - 192.168.0.10/24
            routes:
                - to: default
                  via: 192.168.0.1
            nameservers:
                addresses:
                    - 8.8.8.8
                search:
                    - 8.8.4.4
    version: 2
```

```bash
$ sudo netplan apply
```
Complete the setup for the remaining virtual machines and apply your changes.

You can check the changed IP using the `ifconfig` command.

And Setting Hosts. (All node)
```bash
$ sudo vi /etc/hosts
```
```vim
127.0.0.1 localhost
192.168.0.10 master-node
192.168.0.11 worker-node1
192.168.0.12 worker-node2
192.168.0.13 worker-node3
...
```

Next, download Open JDK and Python3.
```bash
$ sudo apt-get update
$ sudo apt-get install openjdk-8-jdk
$ sudo apt install python3.10
```


<a name='install'></a>

## 2. Install Hadoop

<a name='test'></a>

## 3. Test HDFS