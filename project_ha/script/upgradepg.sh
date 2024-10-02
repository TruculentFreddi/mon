#!/bin/bash version 0.3
#########################################################
#
#Скриптвыполняется из под рута!!!
#
#########################################################
PGSID=son_14
OLDVER=13 
NEWVER=14
#!!!!Внимание!!! размер wal сегмента должен быть идентичен таковому на текущем кластере, который будет подвергаться 
#апгрейду!!!!
WALSEGSIZE=16
########################################################
#set_repo()
#{ 
#echo "Setting PgPro repository" cat << EOF >> /etc/yum.repos.d/pgpro.repo 
#[PostgresProSTD] 
#name=PostgresProSTD$VER 
#baseurl = repo_URL:3000/repository/linux-repo-postgrespro/std-$VER/rhel/$OSVER/os/x86_64/rpms 
#sslverify=0 
#timeout=300 
#gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release 
#enabled = 1 
#gpgcheck = 0 
#EOF
#}

set_repo()
{
cat << EOF >> /etc/yum.repos.d/postgrespro-std-$NEWVER.repo
[postgrespro-std-$NEWVER]
name=PostgresPro Standard $NEWVER] for rhel
baseurl=http://repo.postgrespro.ru/std/std-${NEWVER}/rhel/$releasever/os/$basearch/rpms
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-POSTGRESPRO
EOF
}

#######################################################
set_repo 

sudo yum -y install postgrespro-std-$NEWVER-server postgrespro-std-$NEWVER-client postgrespro-std-$NEWVER-contrib postgrespro-std-$NEWVER-libs postgrespro-std-$NEWVER-server-debuginfo postgrespro-std-$NEWVER-contrib-debuginfo postgrespro-std-$NEWVER-libs-debuginfo postgrespro-std-$NEWVER-devel pgpro-controldata pgpro-pgbadger pgpro-pwr-std-$NEWVER pgpro-stats-std-$NEWVER pgpro-stats-std-$NEWVER-debuginfo mamonsu;

#########################################################
systemctl stop postgrespro-std-$OLDVER.service 
systemctl disable $OLDVER.service 
systemctl status $OLDVER.service 
read -p "Services 
stopped. Press Enter."
#########################################################
#root 
NEWVER=14; 
OLDVER=13;
cp /etc/default/postgrespro-std-$OLDVER /etc/default/postgrespro-std-$OLDVER.bckp 
mv /etc/default/postgrespro-std-$OLDVER /etc/default/postgrespro-std-$NEWVER 
read -p 
"/etc/default/postrgespro-std-$OLDVER is changed to /etc/default/postrgespro-std-$NEWVER"

#NEWVER=14; OLDVER=13; rm -rf /lib/systemd/system.$PGSID.service 
#PGSID=pgsid; NEWVER=14; OLDVER=13; 
#sed -i "s/$PGSID.service/postgrespro-std-$NEWVER.service/p" /etc/systemd/system/$PGSID.service && read -p "/etc/systemd/system/$PGSID.service modified" || read -p "Please stop script"

sed -i "s/postgrespro-std-$OLDVER.service/postgrespro-std-$NEWVER.service/p" /etc/systemd/system/postgrespro-std-$OLDVER.service && read -p "/etc/systemd/system/postgrespro-$OLDVER.service modified" || read -p "Please stop script"
#PG

sudo -s -u postgres << EOF
#OLDVER=13;
cp /home/postgres/.bash_profile /home/postgres/.bash_profile.bckp sed -i s/std-$OLDVER/std-$NEWVER/g /home/pg/.bash_profile

#OLDVER=13;
mv /pgdata/$PGSID /pgdata/$PGSID-$OLDVER && mkdir /pgdata/$PGSID

#OLDVER=13;
mv /pgdata/$PGSID/pg_wal /pgdata/$PGSID-$OLDVER/pg_wal; mkdir -p /pgdata/$PGSID/pg_wal/
#OLDVER=13;
rm -f /pgdata/$PGSID-$OLDVER/pg_wal && ln -s /pgdata/$PGSID-$OLDVER/pg_wal /pgdata/$PGSID-$OLDVER/pg_wal
#OLDVER=13;
#mkdir -p /log/$PGSID/diag/old mv /log/$PGSID/diag/$PGSID* /log/$PGSID/diag/old
#echo $?

EOF

#pg
# 1. initdb
sudo -s -u pg mkdir -p /log/$PGSID/init 
cd /log/$PGSID/init 
sudo -s -u pg << EOF /opt/pgpro/std-$NEWVER/bin/initdb -d /pgdata/$PGSID -g -k -W -X /pgdata/$PGSID/pg_wal --wal-segsize=$WALSEGSIZE > $PGSID-initdb-14.log 2>&1; echo $? 
printf  "$(head -50 $PGSID-initdb-$NEWVER.log)\n... skip ...\n$(tail -30 $PGSID-initdb-$NEWVER.log)\n" 
mkdir /pgdata/$PGSID/usr 
cp /pgdata/$PGSID-$OLDVER/usr/* /pgdata/$PGSID/usr 
EOF

#
#check
#OLDVER=13;

sudo -s -u pg << EOF 
mkdir -p /log/$PGSID/upgrade/$NEWVER 
cd /log/$PGSID/upgrade/$NEWVER 
/opt/pgpro/std-$NEWVER/bin/pg_upgrade --check --old-bindir=/opt/pgpro/std-$OLDVER/bin --new-bindir=/opt/pgpro/std-$NEWVER/bin --old-datadir=/pgdata/$PGSID-$OLDVER --new-datadir=/pgdata/$PGSID --old-port=5432 --new-port=5432 --username=pg --jobs=4 --link
EOF

# After start cluster!!! ./delete_old_cluster.sh
echo Now will be run: /opt/pgpro/std-$NEWVER/bin/pg_upgrade --retain --old-bindir=/opt/pgpro/std-$OLDVER/bin --new-bindir=/opt/pgpro/std-$NEWVER/bin --old-datadir=/pgdata/$PGSID-$OLDVER --new-datadir=/pgdata/$PGSID --old-port=5432 --new-port=5432 --username=pg --jobs=4 --link read -p "If you want RUN upgrade - press Enter, else - press Ctrl-C"

#upgrade OLDVER=13 ;
sudo -s -u pg << EOF cd /log/$PGSID/upgrade/$NEWVER pwd /opt/pgpro/std-$NEWVER/bin/pg_upgrade --retain --old-bindir=/opt/pgpro/std-$OLDVER/bin --new-bindir=/opt/pgpro/std-$NEWVER/bin --old-datadir=/pgdata/$PGSID-$OLDVER --new-datadir=/pgdata/$PGSID --old-port=5432 --new-port=5432 --username=pg --jobs=4 --link EOF
#################
