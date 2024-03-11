#!/bin/bash

core_site_path=""

yarn_site_path=""

hdfs_site_path=""

echo "
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
" >> $core_site_path

echo "
<configuration>
    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>master-node</value>
    </property>
</configration>
" >> $yarn_site_path

echo "
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
" >> $hdfs_site_path