#!/bin/bash
. /home/postgres/project_ha/env/vars.txt;

# gen_hba
sh /home/postgres/project_ha/script/pg_hba_gen.sh;

# gen yml
sh /home/postgres/project_ha/script/patroni_gen.sh;

# gen haproxy
sh /home/postgres/project_ha/script/haproxy_gen.sh;

# gen keepalived
sh /home/postgres/project_ha/script/keepalived_gen.sh;

for H in $(cat $PATRONI_HOSTS); do
scp -r $POSTGRES_RPM $H:/home/postgres/ >/dev/null;
scp -r $PATRONI_RPM $H:/home/postgres/ >/dev/null;
scp -r $HAPROXY_RPM $H:/home/postgres/ >/dev/null;
scp -r $KEEPALIVED_RPM $H:/home/postgres/ >/dev/null;
scp /home/postgres/project_ha/env/${H}_patroni.yml $H:/home/postgres >/dev/null;
scp /home/postgres/project_ha/env/${H}_keepalived.conf $H:/home/postgres >/dev/null;
scp $HAPROXY_CONF $H:/home/postgres >/dev/null;
done
