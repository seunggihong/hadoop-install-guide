![Static Badge](https://img.shields.io/badge/hadoop-3.3.6-%2366CCFF?style=flat-square&logo=apachehadoop&labelColor=white)
![Static Badge](https://img.shields.io/badge/OpenJDK-1.8.0-%23437291?style=flat-square&logo=openjdk&labelColor=white)
![Static Badge](https://img.shields.io/badge/VirtualBox-7.0.10-%23183A61?style=flat-square&logo=virtualbox&logoColor=%23183A61&labelColor=white)
![Static Badge](https://img.shields.io/badge/Ubuntu-22.04-%23E95420?style=flat-square&logo=ubuntu&labelColor=white)

# ***하둡 설치 가이드***
이 레포지토리는 `하둡 에코 시스템`을 오라클 버츄어 머신에 설치하는 방법을 기술해 놓은 것 입니다.

## __목차__
### 1. ***[VM 설정](#setting)***
### 2. ***[하둡 다운로드 및 설정](#install)***
### 3. ***[하둡 실행 및 테스트](#test)***
### 4. ***[스파크 다운로드 및 설정](#spark)***



<a name='setting'></a>

## 1. VM 설정

저희는 4개의 버츄얼 머신을 만들것 입니다.

```yml
VM 스팩.

master-node
    - Processor : 2
    - System memory : 4096 MB
    - Vedio memory : 16 MB

worker-node1~3
    - Processor : 2
    - System memory : 4096 MB
    - Vedio memory : 16 MB
```

프로세스를 2코어로 설정해서 사용하는 이유는 나중에 쿠버네티스를 사용하기 위해서 입니다.

기본값으로 설정 하셔도 문제 없습니다.

이제 고정 IP를 각 가상머신에 설정해 줍니다.

다음과 같은 고정 IP를 사용했습니다.
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

네트워크 설정 파일을 수정하기 위한 경로입니다.

```bash
$ sudo vi /etc/netplan/00-installer-config.yaml
```

구성 파일을 열고 각 노드의 IP 값을 입력하십시오. 다음은 마스터 노드 설정 예시입니다.

```yaml
# This is the network config written by 'subiquity'
network:
    ethernets:
        enp0s3:
            addresses:
                - 192.168.1.10/24
            nameservers: 
                addresses: [8.8.8.8, 8.8.4.4]
            routes:
                - to: default
                  via: 192.168.1.1
    version: 2
```

```bash
$ sudo netplan apply
```
나머지 가상 머신에 대한 설정을 완료하고 변경 사항을 적용합니다.

`ifconfig` 명령어를 통해 변경된 IP를 확인할 수 있습니다.

모든 노드들의 호스트를 설정해 줍니다.
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

다음으로, Open JDK와 Python3를 다운로드 해줍니다.

```bash
$ sudo apt-get update
$ sudo apt-get install openjdk-8-jdk
$ sudo apt install python3-pip
```

워커 노드들의 이름을 바꾸고 적용해 줍니다. ( worker-node1~3 )
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

`sshd_config` 파일의 PubkeyAuthentication 부분 주석을 제거해 줍니다.

```bash
$ sudo vi /etc/ssh/sshd_config
```

```bash
...
PubkeyAuthentication yes
...
```

하둡 마스터 노드는 모든 워커 노드에 대해 비밀번호 없이 SSH를 접속할 수 있도록 활성화합니다.

```bash
$ chmod 700 ~/.ssh
$ ssh-keygen -t rsa -P ""
# Enter
```

마스터 노드의 ssh key를 워커노드들에 복사해 줍니다.

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

## 2. 하둡 다운로드 및 설정

모든 노드에 하둡을 다운로드 해줍니다.

```bash
$ wget https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz
$ tar -xvf hadoop-3.3.6.tar.gz
$ mv hadoop-3.3.6 hadoop
```

압축을 푼 하둡 파일안에 있는 workers파일에 다음과 같이 적어줍니다.

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

이제 하둡을 운영하기 위한 기본적인 프레임을 생성해 줍니다.

`주의 : namenode는 오직 마스터 노드에만 생성해 줘야 합니다.`

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

`~/.bashrc` 파일 끝에 경로를 지정하세요.

```bash
$ sudo vi ~/.bashrc

# .bashrc
...
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export HADOOP_HOME=/home/master-node/hadoop
export PATH=$PATH:$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
export HADOOP_CLASSPATH=${JAVA_HOME}/lib/tools.jar
# :wq!

$ source ~/.bashrc
```

`hadoop-env.sh` 파일에 다음과 같은 내용을 추가해 주세요.

```bash
$ vi hadoop/etc/hadoop/hadoop-env.sh

# hadoop-env.sh
...
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
# :wq!
```
`core-site.xml`, `yarn-site.xml`, `hdfs-site.xml` 파일들을 설정해 주세요.

- core-site.xml
```xml
<!-- all node are the same -->
...
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://master-node:9000</value>
    </property>
    <property>
        <name>hadoop.tmp.dir</name>
        <value>/home/master-node/data/tmp</value>
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
        <value>master-node</value>
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
        <value>/home/master-node/data/namenode</value>
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
        <value>/home/master-node/data/datanode</value>
    </property>
</configration>
```


<a name='test'></a>

## 3. 하둡 실행 및 테스트

드디어 마지막 스텝입니다!!

namenode를 초기화 해줍니다.

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

### ***드디어 우리는 하둡을 사용할 수 있습니다!!*** 🔥🔥🔥🔥🔥 
```bash
$ hdfs dfs -mkdir /test
$ hdfs dfs -ls /
# Check your COMMEND!!!
```

Next Step is install `SPARK`!


## Not Yet
<a name='spark'></a>

## 4. Install SPARK

```bash
$ wget https://dlcdn.apache.org/spark/spark-3.5.0/spark-3.5.0-bin-hadoop3.tgz
$ tar -xvf spark-3.5.0-bin-hadoop3.tgz
$ mv spark-3.5.0-bin-hadoop3 spark
```

`~/.bashrc` file.
```bash
...
export SPARK_HOME=/home/master-node/spark
export PYTHONPATH=$SPARK_HOME/python/lib/pyspark.zip:$SPARK_HOME/python/lib/py4j-0.10.9.7-src.zip
export YARN_CONF_DIR=$HADOOP_HOME/etc/hadoop
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export LD_LIBRARY_PATH=$HADOOP_HOME/lib/native:$LD_LIBRARY_PATH
```

```bash
# master-node
$ cp spark/conf/spark-defaults.conf.template spark/conf/spark-defaults.conf
$ vi spark/conf/spark-defaults.conf
```
```bash
# master-node
...
spark.master                     yarn
spark.eventLog.enabled           true
spark.eventLog.dir               file://home/master-node/spark/sparkeventlog
spark.serializer                 org.apache.spark.serializer.KryoSerializer
spark.driver.memory              512m
spark.yarn.am.memory             256m
```

```bash
# master-node
$ mkdir spark/sparkeventlog
$ sudo ln -s /usr/bin/python3 /usr/bin/python
```
