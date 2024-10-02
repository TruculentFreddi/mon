#!/bin/bash
. /home/postgres/project_ha/env/vars.txt

for H in $(cat $PATRONI_HOSTS); do
ssh -T $H << EOF
sudo mkdir -p $PGDATA;
sudo chown -R postgres:postgres /dbhome/;
initdb -D $PGDATA -g >/dev/null;
echo "PGDATA=$PGDATA" > postgrespro-std-${PG_VER}; 
sudo cp postgrespro-std-${PG_VER} /etc/default/;
EOF
done
