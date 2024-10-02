#!/bin/bash
. /home/postgres/project_ha/env/vars.txt

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
ETCD_INITIAL_CLUSTER="etcd_1=http://${ETCD_1}:2380"
ETCD_INITIAL_CLUSTER_TOKEN="dba"
ETCD_INITIAL_CLUSTER_STATE="new"
\
EOF

