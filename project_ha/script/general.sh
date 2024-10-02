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


# main
for H in $(cat $PATRONI_HOSTS); do                      
scp -r $POSTGRES_RPM $H:/home/postgres/ >/dev/null;     
scp -r $PATRONI_RPM $H:/home/postgres/ >/dev/null;      
scp -r $HAPROXY_RPM $H:/home/postgres/ >/dev/null;      
scp -r $KEEPALIVED_RPM $H:/home/postgres/ >/dev/null;   
scp /home/postgres/project_ha/env/${H}_patroni.yml $H:/home/postgres >/dev/null;     
scp /home/postgres/project_ha/env/${H}_keepalived.conf $H:/home/postgres >/dev/null; 
scp $HAPROXY_CONF $H:/home/postgres >/dev/null;
echo "COPY_WORK: END for $H";                                     
ssh -T $H << EOF
sudo yum -y install /home/postgres/patroni_rpm/*.rpm >/dev/null;
sudo yum -y install /home/postgres/pgpro_${PG_VER}_rpm/*.rpm >/dev/null;
sudo yum -y install /home/postgres/haproxy_rpm/*.rpm >/dev/null;
sudo yum -y install /home/postgres/keepalived_rpm/*.rpm >/dev/null;
echo "INSTAL_WORL: END for $H";
sudo mkdir -p $PGDATA;
sudo mkdir -p $LOG_DIR;
sudo chown -R postgres:postgres /dbhome/;
sudo chmod -R 0700 /dbhome/;
echo "PGDATA=$PGDATA" > postgrespro-std-${PG_VER};
sudo cp postgrespro-std-${PG_VER} /etc/default/;
echo "PREPARE_WORK_PG: END for $H";
sudo systemctl stop patroni.service postgrespro-std-${PG_VER} haproxy.service keepalived.service;
sudo firewall-cmd --zone=public --permanent --add-port={5432,5000,8008}/tcp;
sudo setenforce 0;
sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config;
sudo firewall-cmd --reload;
sudo cp /home/postgres/${H}_patroni.yml /etc/patroni/patroni.yml;
sudo mv /etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf_;
sudo cp /home/postgres/${H}_keepalived.conf /etc/keepalived/keepalived.conf;
sudo mv /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.conf.def;
sudo cp /home/postgres/haproxy.cfg /etc/haproxy/;
sudo systemctl start patroni.service haproxy.service keepalived.service;
sudo systemctl enable patroni.service haproxy.service keepalived.service;
EOF
done

