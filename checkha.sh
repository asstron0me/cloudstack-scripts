#!/bin/sh
alias cloudmonkey='cloudmonkey -c /root/.cloudmonkey/confignoc'
#for i in `cloudmonkey list virtualmachines listall=true state=Stopped|grep -B1 -E "^name"|grep -oE "[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}"`;do 
#  cloudmonkey list virtualmachines listall=true id=$i|grep -q host
#  if [ "$?" -eq  "1" ]; then
#    echo "vm $i has no parent host, starting it.."
#    cloudmonkey start virtualmachine id=$i
#  fi
#done
for i in `mysql cloud -e 'select uuid from vm_instance where state="Stopped" and ha_enabled=1;'|grep -v uuid`;do
  echo "vm $i is HA enabled and is down, starting it.."
  cloudmonkey start virtualmachine id=$i
done
