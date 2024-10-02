#!/bin/bash
. /home/postgres/project_ha/env/vars.txt

for H in $(cat $PATRONI_HOSTS);
do cat $PATRONI_YML | sed -e "s|NODE_NAME|$H|g" | sed -e "s|NODE_HOST|$H|g" | sed -e "s|ETCD_HOST|${ETCD_HOSTS}|g" | awk -v pg_hba="$PG_HBA" '{sub(/PG_HBA/,pg_hba); print}' | sed -e "s|DIR_CONF|${PGDATA}|g" | sed -e "s|BIN_DIR|${BIN_DIR}|g" | sed -e "s|PGDATA|${PGDATA}|g" > /home/postgres/project_ha/env/${H}_patroni.yml; done
