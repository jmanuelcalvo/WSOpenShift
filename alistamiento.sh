#! /bin/bash

echo "Crecion de usuarios de OpenShift y SO"


for i in {1..10}; do ansible masters -m shell -a "htpasswd -b /etc/origin/master/htpasswd user$i redhat01"; adduser user$i; echo redhat01 | passwd --stdin user$i; done

