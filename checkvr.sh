#!/bin/sh
alias cloudmonkey='cloudmonkey -c /root/.cloudmonkey/confignoc'
for i in `cloudmonkey list networks |grep -E "^id = "|awk '{print $3}'`
do
  count=`mysql cloud -e "select
  count(distinct host_id)
  from
  vm_instance
  where vm_type='DomainRouter' and state='Running'
  and id in (select router_id from router_network_ref where network_id=(select id from networks where uuid='$i'));"|grep -v count`
  if [ "$count" -eq "0" ]; then
    echo ERROR, no routers are running for network $i
  elif [ "$count" -eq "1" ]; then
    echo ERROR, 2 routers are running on the same node for network $i
  elif [ "$count" -eq "2" ]; then
    echo OK, routers are running on different nodes for network $i
  fi
done
