#!/bin/bash
. /home/postgres/project_ha/env/vars.txt

cat $HAPROXY_DEF_CONF > $HAPROXY_CONF;
for H in $(cat $PATRONI_HOSTS); do
echo " server $H $H:5432 maxconn 100 check port 8008" >> $HAPROXY_CONF;
done
