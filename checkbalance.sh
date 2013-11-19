#!/bin/sh
alias cloudmonkey='cloudmonkey -c /root/.cloudmonkey/confignoc'
AD111ID=`cloudmonkey -c /root/.cloudmonkey/confignoc list hosts name=ad111.colobridge.net |grep -B1 -E "^name"|grep -oE "[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}"`
AD112ID=`cloudmonkey -c /root/.cloudmonkey/confignoc list hosts name=ad112.colobridge.net |grep -B1 -E "^name"|grep -oE "[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}"`
AD206ID=`cloudmonkey -c /root/.cloudmonkey/confignoc list hosts name=ad206.colobridge.net |grep -B1 -E "^name"|grep -oE "[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}"`
NUMVMSON111=`cloudmonkey -c /root/.cloudmonkey/confignoc list virtualmachines state=Running listall=true hostid=${AD111ID}|grep -B1 -E "^name"|grep -oE "[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}"|wc -l`
NUMVMSON112=`cloudmonkey -c /root/.cloudmonkey/confignoc list virtualmachines state=Running listall=true hostid=${AD112ID}|grep -B1 -E "^name"|grep -oE "[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}"|wc -l`
NUMVMSON206=`cloudmonkey -c /root/.cloudmonkey/confignoc list virtualmachines state=Running listall=true hostid=${AD206ID}|grep -B1 -E "^name"|grep -oE "[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}"|wc -l`
let TOTALVMS=NUMVMSON111+NUMVMSON112+NUMVMSON206
if [ $TOTALVMS -lt "5" ]; then
  echo "not enough vms total to start balancing"
  rm -rf migrate.list
  exit 0
fi
let PROCAD111=100*NUMVMSON111/TOTALVMS
let PROCAD112=100*NUMVMSON112/TOTALVMS
let PROCAD206=100*NUMVMSON206/TOTALVMS
echo NUMVMSON111: $NUMVMSON111
echo NUMVMSON112: $NUMVMSON112
echo TOTALVMS: $TOTALVMS
echo PROCAD111: $PROCAD111
echo PROCAD112: $PROCAD112
if [ $PROCAD111 -lt "30" ]; then
  echo "will start rebalancing on ad111"
  NUM2MIGRATE=`echo "1+${TOTALVMS}*(31-${PROCAD111})/100"|bc`
  echo need to migrate at least $NUM2MIGRATE
  cloudmonkey -c /root/.cloudmonkey/confignoc list virtualmachines state=Running listall=true hostid=${AD112ID}|grep -B1 -E "^name"|grep -oE "[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}" > migrate.list
  cloudmonkey -c /root/.cloudmonkey/confignoc list virtualmachines state=Running listall=true hostid=${AD206ID}|grep -B1 -E "^name"|grep -oE "[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}" >> migrate.list
  for i in `cat migrate.list|sort -R|head -n $NUM2MIGRATE`; do
    echo migrating vm $i to ad111
    cloudmonkey migrate virtualmachine virtualmachineid=$i hostid=$AD111ID
  done
  rm -rf migrate.list
  exit 0
fi
if [ $PROCAD112 -lt "30" ]; then
  echo "will start rebalancing on ad112"
  NUM2MIGRATE=`echo "1+${TOTALVMS}*(31-${PROCAD112})/100"|bc`
  echo need to migrate at least $NUM2MIGRATE
  cloudmonkey -c /root/.cloudmonkey/confignoc list virtualmachines state=Running listall=true hostid=${AD111ID}|grep -B1 -E "^name"|grep -oE "[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}" > migrate.list
  cloudmonkey -c /root/.cloudmonkey/confignoc list virtualmachines state=Running listall=true hostid=${AD206ID}|grep -B1 -E "^name"|grep -oE "[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}" >> migrate.list
  for i in `cat migrate.list|sort -R|head -n $NUM2MIGRATE`; do
     echo migrating vm $i to ad112
     cloudmonkey migrate virtualmachine virtualmachineid=$i hostid=$AD112ID
  done
  rm -rf migrate.list
  exit 0
fi

if [ $PROCAD206 -lt "30" ]; then
  echo "will start rebalancing on ad206"
  NUM2MIGRATE=`echo "1+${TOTALVMS}*(31-${PROCAD206})/100"|bc`
  echo need to migrate at least $NUM2MIGRATE
  cloudmonkey -c /root/.cloudmonkey/confignoc list virtualmachines state=Running listall=true hostid=${AD111ID}|grep -B1 -E "^name"|grep -oE "[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}" > migrate.list
  cloudmonkey -c /root/.cloudmonkey/confignoc list virtualmachines state=Running listall=true hostid=${AD112ID}|grep -B1 -E "^name"|grep -oE "[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}" >> migrate.list
  for i in `cat migrate.list|sort -R|head -n $NUM2MIGRATE`; do
     echo migrating vm $i to ad206
     cloudmonkey migrate virtualmachine virtualmachineid=$i hostid=$AD206ID
  done
  rm -rf migrate.list
  exit 0
fi
