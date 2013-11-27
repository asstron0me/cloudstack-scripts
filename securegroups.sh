#!/bin/sh
alias cloudmonkey='cloudmonkey -c /root/.cloudmonkey/confignoc'
for listhypervisors in  `mysql cloud -e "select id,private_ip_address from host where hypervisor_type='KVM' and status='Up';"|grep -v address|awk '{print $1","$2}'`
do
  HVID=`echo $listhypervisors|cut -d, -f1`
  HVIP=`echo $listhypervisors|cut -d, -f2`
  echo "found HV with id $HVID and ip $HVIP"
  echo "searching for VMS..."
  for listvms in `mysql cloud -e "select id,instance_name from vm_instance where hypervisor_type='KVM' and host_id=$HVID and state='Running' and type='User';"|grep -v instance_name|awk '{print $1","$2}'`
  do
    VMID=`echo $listvms|cut -d, -f1`
    VMNAME=`echo $listvms|cut -d, -f2`
    echo "  found VM $VMNAME with id $VMID"
    for listvmnics in `mysql cloud -e "select id,mac_address,ip4_address,secondary_ip,CONVERT(SUBSTRING_INDEX(broadcast_uri,'//',-1),UNSIGNED INTEGER) as vlanid from nics where CONVERT(SUBSTRING_INDEX(broadcast_uri,'//',-1),UNSIGNED INTEGER)  < '999' and state !='Deallocating' and mode='Dhcp' and instance_id=$VMID;"|grep -v vlanid|awk '{print $1","$2","$3","$4","$5}'`
    do
      VMNICID=`echo $listvmnics|cut -d, -f1`
      VMNICMAC=`echo $listvmnics|cut -d, -f2`
      VMNICIP=`echo $listvmnics|cut -d, -f3`
      VMNICSEC=`echo $listvmnics|cut -d, -f4`
      VMNICVLAN=`echo $listvmnics|cut -d, -f5`
      echo "    VM $VMID NIC $VNMICID $VMNICMAC in vlan $VMNICVLAN with primary ip $VMNICIP sec=$VMNICSEC"
      if [ "$VMNICSEC" -eq "1" ]; then
        echo "    searching for secondary ips..."
        for secip in `mysql cloud -e "select ip4_address  from nic_secondary_ips where vmId=$VMID and nicId=$VMNICID;"|grep -v address`
        do
          echo "      found sec ip $secip"
          VMNICIP="$VMNICIP,$secip"
        done
      fi
      echo "i will run ssh root@$HVIP 'ebtables.sh $VMNAME $VMNICMAC $VMNICIP'"
    done
  done
done
