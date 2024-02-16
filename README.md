![Static Badge](https://img.shields.io/badge/hadoop-3.3.6-%2366CCFF?style=flat-square&logo=apachehadoop&labelColor=white)
![Static Badge](https://img.shields.io/badge/OpenJDK-1.8.0-%23437291?style=flat-square&logo=openjdk&labelColor=white)
![Static Badge](https://img.shields.io/badge/VirtualBox-7.0.10-%23183A61?style=flat-square&logo=virtualbox&logoColor=%23183A61&labelColor=white)
![Static Badge](https://img.shields.io/badge/Ubuntu-22.04-%23E95420?style=flat-square&logo=ubuntu&labelColor=white)

# ***Hadoop install Guide***
This repo is, describes how to build a `Hadoop` eco system using the `Oracle virtual machine`.

## __Contents__
### 1. ***[Setting VM](#setting)***
### 2. ***[Install Hadoop](#install)***
### 3. ***[Test HDFS](#test)***
### 4. ***[Install SPARK](#spark)***



<a name='setting'></a>

## 1. Setting VM

We will create 4 VMs.

```yml
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
```yml
master-node
    - IP : 192.168.1.10
    - Port : 10
worker-node1 
    - IP : 192.168.1.11
    - Port : 11
worker-node2 
    - IP : 192.168.1.12
    - Port : 12
worker-node3
    - IP : 192.168.1.13
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
                - 192.168.1.10/24
            nameservers: [8.8.8.8, 8.8.4.4]
            routes:
                - to: default
                  via: 192.168.1.1
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
$ sudo apt install python3-pip
```

Change worker node name. ( worker-node1, 2, 3 )
```bash
$ sudo vi /etc/hostname
```

```vim
worker-node1
```

```bash
$ sudo hostname -F /etc/hostname # all-node
$ sudo hostname apply
$ sudo reboot
```

Remove comment.
```bash
$ sudo vi /etc/ssh/sshd_config
```

```bash
...
PubkeyAuthentication yes
...
```

The Hadoop master node enables ssh without a password for all worker nodes. `ALL NODE!`
```bash
$ chmod 700 ~/.ssh
$ ssh-keygen -t rsa -P ""
# Enter
```

Copy the master node's ssh key to the worker nodes.
```bash
# master node only
$ ssh-copy-id -i ~/.ssh/id_rsa.pub master-node
$ ssh-copy-id -i ~/.ssh/id_rsa.pub worker-node1
$ ssh-copy-id -i ~/.ssh/id_rsa.pub worker-node2
$ ssh-copy-id -i ~/.ssh/id_rsa.pub worker-node3

# Check if ssh is connected properly
$ ssh worker-node1
```

<a name='install'></a>

## 2. Install Hadoop

Install hadoop `ALL NODE!`
```bash
$ wget https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz
$ tar -xvf hadoop-3.3.6.tar.gz
$ mv hadoop-3.3.6 hadoop
```

Write down the worker and master.
```bash
$ vi hadoop/etc/hadoop/workers
# Workers File
worker-node1
worker-node2
worker-node3
# :wq!

$ vi hadoop/etc/hadoop/masters
# Masters File
master-node
# :wq!
```

Creates a basic frame.

`Caution: You must create a namenode only on the master node`.
```bash
# master node
$ mkdir data
$ cd data
$ mkdir namenode datanode tmp userlogs

# worker nodes
$ mkdir data
$ cd data
$ mkdir datanode tmp userlogs
```

Specify the path at the end of the `~/.bashrc` file.
```bash
$ sudo vi ~/.bashrc

# .bashrc
...
export JAVA_HOME=/usr/lib/jvm/default-java/
export HADOOP_HOME=/home/master/hadoop
export PATH=$PATH:$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
export HADOOP_CLASSPATH=${JAVA_HOME}/lib/tools.jar
# :wq!

$ source ~/.bashrc
```

Add `hadoop-env.sh`
```bash
$ vi hadoop/etc/hadoop/hadoop-env.sh

# hadoop-env.sh
...
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
# :wq!
```
Setting `core-site.xml`, `yarn-site.xml`, `hdfs-site.xml`
- core-site.xml
```xml
<!-- all node are the same -->
...
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://master:9000</value>
    </property>
    <property>
        <name>hadoop.tmp.dir</name>
        <value>/home/master/data/tmp</value>
    </property>
</configration>
```

- yarn-site.xml 

```xml
<!-- master node -->
...
<configuration>
    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>master</value>
    </property>
</configration>
```

```xml
<!-- worker nodes -->
...
<configuration>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
</configration>
```

- hdfs-site.xml
```xml
<!-- master node -->
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>3</value>
    </property>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>/home/master/data/namenode</value>
    </property>
</configration>
```

```xml
<!-- worker nodes -->
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>3</value>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>/home/master/data/datanode</value>
    </property>
</configration>
```


<a name='test'></a>

## 3. Test HDFS

Finally the last step!!!

Initializes the namenode.
```bash
# master node
$ hdfs namenode -format
$ start-all.sh

# Check if this works!
$ jps

# If it works correctly, you will see the following command line:
1380 SecondaryNameNode
2391 Jps
1480 ResourceManager
1840 NameNode

# The same behavior can be seen on worker nodes.
4801 DataNode
4248 Jps
3059 NodeManager
```

### ***Finally we can use it. Hadoop!!*** 🔥🔥🔥🔥🔥 
```bash
$ hdfs dfs -mkdir /test
$ hdfs dfs -ls /
# Check your COMMEND!!!
```

Next Step is install `SPARK`!

<a name='spark'></a>

## 4. Install SPARK

__COMMING SOON__