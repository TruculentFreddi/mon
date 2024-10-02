#!/bin/bash
. /home/postgres/project_ha/env/vars.txt;

for H in $(cat $PATRONI_HOSTS); do
ssh -T $H << EOF
sudo yum -y install /home/postgres/patroni_rpm/*.rpm >/dev/null;
sudo yum -y install /home/postgres/pgpro_${PG_VER}_rpm/*.rpm >/dev/null;
sudo yum -y install /home/postgres/haproxy_rpm/*.rpm >/dev/null;
sudo yum -y install /home/postgres/keepalived_rpm/*.rpm >/dev/null;
EOF
done
