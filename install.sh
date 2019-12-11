#! /bin/bash
# Instalacion de un OpenShift en OpenTLC

GUID=2775
cp /etc/ansible/hosts /etc/ansible/hosts.default
sed "s/2775/$GUID/g" hosts > /etc/ansible/hosts

echo "Validando que las maquinas este OK"
ansible all -m ping

if [ "$?" == "0" ]
then
  yum -y install atomic-openshift-clients openshift-ansible
  cd /usr/share/ansible/openshift-ansible/ 
  time ansible-playbook playbooks/prerequisites.yml
else
  echo "Las maquinas no estan lista o el GUID no esta bien configurado, verifique"
fi


if [ "$?" == "0" ]
then
  echo "Realizando la instalacion de OpenShift"
  sleep 30
  cd /usr/share/ansible/openshift-ansible
  time ansible-playbook playbooks/deploy_cluster.yml
else
  echo "el playbook de pre-requisitos no finalizo de forma correcta, verificar"
fi

ansible masters[0] -b -m fetch -a "src=/root/.kube/config dest=/root/.kube/config flat=yes"
oc get projects

echo "Crecion de usuarios de OpenShift y SO"
for i in {1..9}; do ansible masters -m shell -a "htpasswd -b /etc/origin/master/htpasswd user0$i redhat01"; adduser user0$i; echo redhat01 | passwd --stdin user0$i; done
for i in {10..20}; do ansible masters -m shell -a "htpasswd -b /etc/origin/master/htpasswd user$i redhat01"; adduser user$i; echo redhat01 | passwd --stdin user$i; done



echo "Habilitando acceso por ssh desde ssh"
ansible localhost -m lineinfile -a 'path=/etc/ssh/sshd_config regexp="PasswordAuthentication no" line="PasswordAuthentication yes" backrefs=yes'
systemctl restart sshd




scp nfs.sh support1.$GUID.internal:/tmp
ssh support1.$GUID.internal sudo sh /tmp/nfs.sh

# Crear los PV
export volsize="5Gi"
mkdir /root/pvs
for volume in pv{1..50} ; do
cat << EOF > /root/pvs/${volume}
{
  "apiVersion": "v1",
  "kind": "PersistentVolume", 
  "metadata": {
    "name": "${volume}"
  },
  "spec": { "capacity": {
  "storage": "${volsize}"
   },
  "accessModes": [ "ReadWriteOnce" ],
  "nfs": {
    "path": "/srv/nfs/user-vols/${volume}",
    "server": "support1.${GUID}.internal"
  },
  "persistentVolumeReclaimPolicy": "Recycle" 
 }
}
EOF
echo "Created def file for ${volume}"; done;



export volsize="10Gi"
for volume in pv{51..100} ; do 
cat << EOF > /root/pvs/${volume} 
{
  "apiVersion": "v1",
  "kind": "PersistentVolume", 
  "metadata": {
    "name": "${volume}" 
  },
  "spec": { 
    "capacity": {
      "storage": "${volsize}" 
    },
    "accessModes": [ "ReadWriteMany" ], 
    "nfs": {
      "path": "/srv/nfs/user-vols/${volume}",
      "server": "support1.${GUID}.internal" 
    },
    "persistentVolumeReclaimPolicy": "Retain" 
  }
}
EOF
echo "Created def file for ${volume}"; 
done;

cat /root/pvs/* | oc create -f -
