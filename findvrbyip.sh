#!/bin/sh
alias cloudmonkey='cloudmonkey -c /root/.cloudmonkey/confignoc'
NETID=`mysql cloud -e "select network_id from user_ip_address where public_ip_address=\"$1\";"|grep -v network_id`
NETUUID=`mysql cloud -e "select uuid from networks where id=\"$NETID\";"|grep -v uuid`
cloudmonkey list routers listall=true networkid=$NETUUID|grep -B 60 MASTER|grep -E "^name|^account|^hostname|^linklocalip"
exit 0
