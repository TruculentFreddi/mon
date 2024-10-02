#!/bin/bash
. /home/postgres/project_ha/env/vars.txt

#main vars
set $ETCD_HOSTS_FCL;
export ETCD_1=$1;
export ETCD_2=$2;
export ETCD_3=$3;

# check last_work
for H in $(cat $ETCD_HOSTS_FCL); do
scp -r $ETCD_RPM $H:/home/postgres/ >/dev/null;
ssh -T $H << EOF
sudo yum -y install /home/postgres/etcd_rpm/* >/dev/null;
sudo firewall-cmd --add-port={80,2379,2380}/tcp --permanent;
sudo setenforce 0;
sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config;
sudo firewall-cmd --reload;
sudo systemctl daemon-reload;
sudo mv /etc/etcd/etcd.conf /etc/etcd/etcd.conf_;
EOF
done
