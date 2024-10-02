#!/bin/bash
. /home/postgres/project_ha/env/vars.txt

set -- $(cat $PATRONI_HOSTS);
export IP_1=$(cat $PATRONI_IP | grep $1 | awk -F ' ' '{print $1}');
export IP_2=$(cat $PATRONI_IP | grep $2 | awk -F ' ' '{print $1}');
export IP_3=$(cat $PATRONI_IP | grep $3 | awk -F ' ' '{print $1}');

cat > ${1}_keepalived.conf << EOF
vrrp_instance VI_1 {
    state MASTER
    interface $NET_INT
    virtual_router_id 33
    priority 200
    unicast_src_ip $IP_1
    unicast_peer {
        $IP_2
        $IP_3
    }
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
         $IP_VIP dev $NET_INT label ${NET_INT}:2
    }
}
EOF

cat > ${2}_keepalived.conf << EOF
vrrp_instance VI_1 {
    state BACKUP
    interface $NET_INT
    virtual_router_id 33
    priority 100
    unicast_src_ip $IP_2
    unicast_peer {
        $IP_1
        $IP_3
    }
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
         $IP_VIP dev $NET_INT label ${NET_INT}:2
    }
}
EOF

cat > ${3}_keepalived.conf << EOF
vrrp_instance VI_1 {
    state BACKUP
    interface $NET_INT
    virtual_router_id 33
    priority 100
    unicast_src_ip $IP_3
    unicast_peer {
        $IP_1
        $IP_2
    }
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
         $IP_VIP dev $NET_INT label ${NET_INT}:2
    }
}
EOF
