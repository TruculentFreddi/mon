#!/bin/bash
. /home/postgres/project_ha/env/vars.txt

for H in $(cat $PATRONI_HOSTS); do ssh -T $H << EOF
sudo systemctl stop postgrespro-std-${PG_VER}.service patroni.service haproxy.service keepalived.service; 
sudo firewall-cmd --zone=public --permanent --add-port={5432,5000,8008}/tcp;
sudo cp /home/postgres/${H}_patroni.yml /etc/patroni/patroni.yml;
sudo mv /etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf_;
sudo cp /home/postgres/${H}_keepalived.conf /etc/keepalived/keepalived.conf;
sudo mv /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.conf.def;
sudo cp /home/postgres/haproxy.cfg /etc/haproxy/;
sudo systemctl start postgrespro-std-${PG_VER}.service patroni.service haproxy.service keepalived.service;
sudo systemctl enable postgrespro-std-${PG_VER}.service patroni.service haproxy.service keepalived.service;
EOF
done
