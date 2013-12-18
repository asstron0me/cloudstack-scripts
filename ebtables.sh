#!/bin/bash
# (c) sukaslayer, 2012, slayer@telegraf.by
if [ $# -eq 3 ]; then
    echo "starting ebtables fix on `hostname` at `date`"
else
    echo "Incorrect usage."
    echo "Usage: $0 <vmname> <macaddress> <ipaddress>"
    exit 1
fi
VM_NAME=`virsh list|grep $1|grep -oE "i-([0-9]*)-([0-9]*)"`
if [ $? -eq 0 ]; then
    echo "found vm $VM_NAME"
else 
   VM_NAME=`virsh list|grep $1|grep -oE "[svr]-([0-9]*)"`
   if [ $? -eq 0 ]; then
   	echo "found system vm $VM_NAME"
   else 
   	echo "vm $1 not found"
   	exit 1
   fi
fi



VM_MAC=`echo $2|grep -E "(([0-9a-f]{2}(:|$)){6})"`
if [ $? -eq 0 ]; then
    echo "mac address $2 seems to be valid"
else 
    echo "$2 does not look like valid mac address"
    exit 1
fi

for i in `echo $3|tr "," "\n"`
do
VM_IP=`echo $i|grep -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"`
if [ $? -eq 0 ]; then
    echo "ip address $i seems to be valid"
else
    echo "$i does not look like valid ip address"
    exit 1
fi
done

echo list all interfaces on $VM_NAME:
virsh dumpxml $VM_NAME-VM |tr -d "\n"|awk -F "interface" '{print $2,$3,$4,$5,$6,$7,$8,$9,$10}'|awk -F "serial" '{print $1}'|sed -e "s/<\/ >/\n/g"|grep bridge|sed -r "s@^(.*)<  type@type@g" |grep address|cut -d\< -f2,4|tr -d "<>/'" |tr  "=" " "|awk '{print $3,$6}'

VNET_NO_TMP=`virsh dumpxml $VM_NAME-VM |tr -d "\n"|awk -F "interface" '{print $2,$3,$4,$5,$6,$7,$8,$9,$10}'|awk -F "serial" '{print $1}'|sed -e "s/<\/ >/\n/g"|grep bridge|sed -r "s@^(.*)<  type@type@g" |grep address|cut -d\< -f2,4|tr -d "<>/'" |tr  "=" " "|awk '{print $3,$6}'|grep $VM_MAC`

if [ $? -eq 0 ]; then
    VNET_NO=`virsh dumpxml $VM_NAME-VM |tr -d "\n"|awk -F "interface" '{print $2,$3,$4,$5,$6,$7,$8,$9,$10}'|awk -F "serial" '{print $1}'|sed -e "s/<\/ >/\n/g"|grep bridge|sed -r "s@^(.*)<  type@type@g" |grep address|cut -d\< -f2,4|tr -d "<>/'" |tr  "=" " "|awk '{print $3,$6}'|grep $VM_MAC|awk '{print $2}'`
    echo "found vnet interface $VNET_NO for vm $VM_NAME"
else
    echo "there is no interface with mac $VM_MAC on $VM_NAME"
    exit 1
fi
echo "creating eb/ip tables rules for $VNET_NO/$VM_MAC/$VM_IP"
#ebtables -t nat -L PREROUTING | grep $VM_NAME-VM         
#ebtables -t nat -L POSTROUTING | grep $VM_NAME-VM         
ebtables -t nat -F $VM_NAME-VM-$VNET_NO-in            
ebtables -t nat -F $VM_NAME-VM-$VNET_NO-out            
#iptables -N $VM_NAME-VM              
#iptables -N $VM_NAME-VM-eg              
#iptables -N $VM_NAME-def              
#WTF?iptables -D BF-cloudbr0-OUT -m physdev --physdev-is-bridged --physdev-out $VNET_NO -j $VM_NAME-def
#WTF?iptables -D BF-cloudbr0-IN -m physdev --physdev-is-bridged --physdev-in $VNET_NO -j $VM_NAME-def
#iptables -D $VM_NAME-def -m state --state RELATED,ESTABLISHED -j ACCEPT
#iptables -D $VM_NAME-def -m physdev --physdev-is-bridged --physdev-in $VNET_NO -p udp --dport 67 --sport 68 -j ACCEPT
#iptables -D $VM_NAME-def -m physdev --physdev-is-bridged --physdev-out $VNET_NO -p udp --dport 68 --sport 67 -j ACCEPT
#iptables -D $VM_NAME-def -m physdev --physdev-is-bridged --physdev-in $VNET_NO --source $VM_IP -p udp --dport 53 -j RETURN
#iptables -D $VM_NAME-def -m physdev --physdev-is-bridged --physdev-in $VNET_NO --source $VM_IP -j $VM_NAME-VM-eg
#iptables -D $VM_NAME-def -m physdev --physdev-is-bridged --physdev-out $VNET_NO -j $VM_NAME-VM
#iptables -D $VM_NAME-VM -j DROP
#WTF?iptables -A BF-cloudbr0-OUT -m physdev --physdev-is-bridged --physdev-out $VNET_NO -j $VM_NAME-def       
#WTF?iptables -A BF-cloudbr0-IN -m physdev --physdev-is-bridged --physdev-in $VNET_NO -j $VM_NAME-def       
#iptables -A $VM_NAME-def -m state --state RELATED,ESTABLISHED -j ACCEPT        
#iptables -A $VM_NAME-def -m physdev --physdev-is-bridged --physdev-in $VNET_NO -p udp --dport 67 --sport 68 -j ACCEPT 
#iptables -A $VM_NAME-def -m physdev --physdev-is-bridged --physdev-out $VNET_NO -p udp --dport 68 --sport 67 -j ACCEPT 
#iptables -A $VM_NAME-def -m physdev --physdev-is-bridged --physdev-in $VNET_NO --source $VM_IP -p udp --dport 53 -j RETURN 
#iptables -A $VM_NAME-def -m physdev --physdev-is-bridged --physdev-in $VNET_NO --source $VM_IP -j $VM_NAME-VM-eg     
#iptables -A $VM_NAME-def -m physdev --physdev-is-bridged --physdev-out $VNET_NO -j $VM_NAME-VM       
#iptables -A $VM_NAME-VM -j DROP            
ebtables -t nat -N $VM_NAME-VM-$VNET_NO-in            
ebtables -t nat -N $VM_NAME-VM-$VNET_NO-out            
ebtables -t nat -D PREROUTING -i $VNET_NO -j $VM_NAME-VM-$VNET_NO-in
ebtables -t nat -D POSTROUTING -o $VNET_NO -j $VM_NAME-VM-$VNET_NO-out
ebtables -t nat -A PREROUTING -i $VNET_NO -j $VM_NAME-VM-$VNET_NO-in        
ebtables -t nat -A POSTROUTING -o $VNET_NO -j $VM_NAME-VM-$VNET_NO-out        
ebtables -t nat -A $VM_NAME-VM-$VNET_NO-in -s ! $VM_MAC -j DROP       
for VM_IP in `echo $3|tr "," "\n"`
do
  ebtables -t nat -A $VM_NAME-VM-$VNET_NO-in -p IPv4 --ip-src  $VM_IP -j ACCEPT
done
ebtables -t nat -A $VM_NAME-VM-$VNET_NO-in -p IPv4 -j DROP
ebtables -t nat -A $VM_NAME-VM-$VNET_NO-in -p ARP -s ! $VM_MAC -j DROP     
ebtables -t nat -A $VM_NAME-VM-$VNET_NO-in -p ARP --arp-mac-src ! $VM_MAC -j DROP
for VM_IP in `echo $3|tr "," "\n"`
do
  ebtables -t nat -A $VM_NAME-VM-$VNET_NO-in -p ARP --arp-ip-src  $VM_IP -j ACCEPT
done
ebtables -t nat -A $VM_NAME-VM-$VNET_NO-in -p ARP -j DROP     
ebtables -t nat -A $VM_NAME-VM-$VNET_NO-in -p ARP --arp-op Request -j ACCEPT      
ebtables -t nat -A $VM_NAME-VM-$VNET_NO-in -p ARP --arp-op Reply -j ACCEPT      
ebtables -t nat -A $VM_NAME-VM-$VNET_NO-in -p ARP -j DROP        
ebtables -t nat -A $VM_NAME-VM-$VNET_NO-out -p ARP --arp-op Reply --arp-mac-dst ! $VM_MAC -j DROP
for VM_IP in `echo $3|tr "," "\n"`
do
  ebtables -t nat -A $VM_NAME-VM-$VNET_NO-out -p ARP --arp-ip-dst  $VM_IP -j ACCEPT
done
ebtables -t nat -A $VM_NAME-VM-$VNET_NO-out -p ARP -j DROP     
ebtables -t nat -A $VM_NAME-VM-$VNET_NO-out -p ARP --arp-op Request -j ACCEPT      
ebtables -t nat -A $VM_NAME-VM-$VNET_NO-out -p ARP --arp-op Reply -j ACCEPT      
ebtables -t nat -A $VM_NAME-VM-$VNET_NO-out -p ARP -j DROP        
#iptables -F $VM_NAME-VM              
#iptables -F $VM_NAME-VM-eg              
#iptables -I $VM_NAME-VM -p icmp --icmp-type any -j ACCEPT        
#iptables -I $VM_NAME-VM -p tcp -m tcp --dport 1:65535 -m state --state NEW -j ACCEPT  
#iptables -I $VM_NAME-VM -p udp -m udp --dport 1:65535 -m state --state NEW -j ACCEPT  
#iptables -I $VM_NAME-VM-eg -p icmp --icmp-type any -j RETURN        
#iptables -I $VM_NAME-VM-eg -p tcp -m tcp --dport 1:65535 -m state --state NEW -j RETURN  
#iptables -I $VM_NAME-VM-eg -p udp -m udp --dport 1:65535 -m state --state NEW -j RETURN  
#iptables -A $VM_NAME-VM-eg -j DROP            
#iptables -A $VM_NAME-VM -j DROP            
