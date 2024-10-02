#!/bin/bash
. /home/postgres/project_ha/env/vars.txt

#main vars
set $(cat $ETCD_HOSTS_FCL);
export ETCD_1=$1;
export ETCD_2=$2;
export ETCD_3=$3;

# check last_work
if [ $(ssh $ETCD_1 "ls /home/postgres/work_done.txt" &>/dev/null; echo $?) -gt 0 ]; then
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
echo "prep_work end for $H"
done

# ETCD_NODE 1

set $(cat $ETCD_HOSTS_FCL);
export ETCD_1=$1;
export ETCD_2=$2;
export ETCD_3=$3;

cat << EOF | ssh $ETCD_1 "cat > /home/postgres/etcd.conf"
#[Member]
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
ETCD_NAME="$ETCD_1"
ETCD_HEARTBEAT_INTERVAL="1000"
ETCD_ELECTION_TIMEOUT="5000"
#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://${ETCD_1}:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://${ETCD_1}:2379"
ETCD_INITIAL_CLUSTER="${ETCD_1}=http://${ETCD_1}:2380"
ETCD_INITIAL_CLUSTER_TOKEN="dba"
ETCD_INITIAL_CLUSTER_STATE="new"
\
EOF
ssh -T $ETCD_1 << EOF
sudo cp /home/postgres/etcd.conf /etc/etcd/etcd.conf;
sudo systemctl stop etcd.service;
sudo systemctl start etcd.service;
sudo systemctl enable etcd.service;
etcdctl member add $ETCD_2 http://${ETCD_2}:2380;
echo "new member $ETCD_2 added to etcd_cluster"
etcdctl member add $ETCD_3 http://${ETCD_3}:2380;
echo "new member $ETCD_3 added to etcd_cluster"
echo "first step for $ETCD_1 done"
EOF

# ETCD_NODE 2

cat << EOF | ssh $ETCD_2 "cat > /home/postgres/etcd.conf"
#[Member]
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
ETCD_NAME="$ETCD_2"
ETCD_HEARTBEAT_INTERVAL="1000"
ETCD_ELECTION_TIMEOUT="5000"
#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://${ETCD_2}:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://${ETCD_2}:2379"
ETCD_INITIAL_CLUSTER="${ETCD_1}=http://${ETCD_1}:2380,${ETCD_2}=http://${ETCD_2}:2380,${ETCD_3}=http://${ETCD_3}:2380"
ETCD_INITIAL_CLUSTER_TOKEN="dba"
ETCD_INITIAL_CLUSTER_STATE="existing"
\
EOF
ssh -T $ETCD_2 << EOF
sudo cp /home/postgres/etcd.conf /etc/etcd/etcd.conf;
sudo systemctl stop etcd.service;
sudo systemctl start etcd.service;
sudo systemctl enable etcd.service;
echo "first start $ETCD_2"
EOF

# ETCD_NODE 3

cat << EOF | ssh $ETCD_3 "cat > /home/postgres/etcd.conf"
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
ETCD_NAME="$ETCD_3"
ETCD_HEARTBEAT_INTERVAL="1000"
ETCD_ELECTION_TIMEOUT="5000"
#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://${ETCD_3}:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://${ETCD_3}:2379"
ETCD_INITIAL_CLUSTER="${ETCD_1}=http://${ETCD_1}:2380,${ETCD_2}=http://${ETCD_2}:2380,${ETCD_3}=http://${ETCD_3}:2380"
ETCD_INITIAL_CLUSTER_TOKEN="dba"
ETCD_INITIAL_CLUSTER_STATE="existing"
\
EOF
ssh -T $ETCD_3 << EOF
sudo cp /home/postgres/etcd.conf /etc/etcd/etcd.conf;
sudo systemctl stop etcd.service;
sudo systemctl start etcd.service;
sudo systemctl enable etcd.service;
EOF

# ETCD_NODE 2

cat << EOF | ssh $ETCD_2 "cat > /home/postgres/etcd.conf"
#[Member]
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
ETCD_NAME="$ETCD_2"
ETCD_HEARTBEAT_INTERVAL="1000"
ETCD_ELECTION_TIMEOUT="5000"
#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://${ETCD_2}:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://${ETCD_2}:2379"
ETCD_INITIAL_CLUSTER="${ETCD_1}=http://${ETCD_1}:2380,${ETCD_2}=http://${ETCD_2}:2380,${ETCD_3}=http://${ETCD_3}:2380"
ETCD_INITIAL_CLUSTER_TOKEN="dba"
ETCD_INITIAL_CLUSTER_STATE="existing"
\
EOF
ssh -T $ETCD_2 << EOF
sudo cp /home/postgres/etcd.conf /etc/etcd/etcd.conf;
sudo systemctl stop etcd.service;
sudo systemctl start etcd.service;
EOF

# ETCD_NODE 1

cat << EOF | ssh $ETCD_1 "cat > /home/postgres/etcd.conf"
#[Member]
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
ETCD_NAME="$ETCD_1"
ETCD_HEARTBEAT_INTERVAL="1000"
ETCD_ELECTION_TIMEOUT="5000"
#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://${ETCD_1}:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://${ETCD_1}:2379"
ETCD_INITIAL_CLUSTER="${ETCD_1}=http://${ETCD_1}:2380,${ETCD_2}=http://${ETCD_2}:2380,${ETCD_3}=http://${ETCD_3}:2380"
ETCD_INITIAL_CLUSTER_TOKEN="dba"
ETCD_INITIAL_CLUSTER_STATE="existing"
\
EOF
ssh -T $ETCD_1 << EOF
sudo cp /home/postgres/etcd.conf /etc/etcd/etcd.conf;
sudo systemctl stop etcd.service;
sudo systemctl start etcd.service;
touch /home/postgres/work_done.txt;
EOF
else
echo "the script has already run before";
fi


