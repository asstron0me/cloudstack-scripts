#!/bin/bash

VMNAME=$1
ENCPASS=`mysql -e "select vnc_password from cloud.vm_instance where instance_name = \"$VMNAME\""|grep -v vnc`
java -cp /usr/share/cloudstack-common/lib/jasypt-1.9.0.jar  org.jasypt.intf.cli.JasyptPBEStringDecryptionCLI  input="$ENCPASS"  password="password"
