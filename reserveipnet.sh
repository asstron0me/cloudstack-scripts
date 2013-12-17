#!/bin/sh
mysql cloud -e "update user_ip_address set state='Reserved' where public_ip_address like '77.72.135.%' and state='Free';"
mysql cloud -e "update user_ip_address set allocated=now() where public_ip_address like '77.72.135.%' and state='Reserved';"
