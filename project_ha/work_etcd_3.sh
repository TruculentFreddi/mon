#!/bin/bash
. /home/postgres/project_ha/env/vars.txt

set $(cat $ETCD_HOSTS_FCL);
export ETCD_1=$1;
export ETCD_2=$2;
export ETCD_3=$3;

ssh -T $ETCD_1 << EOF
sudo systemctl stop etcd.service;
sudo systemctl start etcd.service;
etcdctl member add $ETCD_3 http://${ETCD_3}:2380;
echo "new member $ETCD_3 added to etcd_cluster";
EOF
