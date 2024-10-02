#!/bin/bash
. /home/postgres/project_ha/env/vars.txt
# pg_hba in patroni.yml format

echo " - local   all             postgres                                trust
 - host    all             all             127.0.0.1/32            md5" > $PG_HBA_CONF;
for H in $(cat $PATRONI_HOSTS); do
for IP in $(cat $PATRONI_IP | grep "$H" | awk -F ' ' '{print $1}'); do
echo " - host    all             postgres        $IP/32       md5" >> $PG_HBA_CONF;
done
done
echo " - host    all             all             ::1/128                 md5
 - local   replication     all                                     trust
 - host    replication     all             127.0.0.1/32            md5" >> $PG_HBA_CONF;
for H in $(cat $PATRONI_HOSTS); do
for IP in $(cat $PATRONI_IP | grep "$H" | awk -F ' ' '{print $1}'); do
echo " - host    replication     postgres        $IP/32       md5" >> $PG_HBA_CONF;
done
done
echo " - host    replication     all             ::1/128                 md5" >> $PG_HBA_CONF;
