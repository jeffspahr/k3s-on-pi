#!/bin/bash
#https://askubuntu.com/questions/156771/run-a-script-only-at-the-very-first-boot

/usr/sbin/netplan apply

# Delete me
rm $0
