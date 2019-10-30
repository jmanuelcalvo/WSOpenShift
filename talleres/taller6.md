# Talleres
[Inicio](../ComandosOpenShift.md)

### NOTA:
Antes de iniciar a trabajar con Ansible, garantice que las maquinas con las que se va a conectar tengan realcion de confianza por ssh.

# Trabajando con Ansible

Creacion de archivos de inventario agrupando servidores en masters, infra, apps, nfs

```
[user01@bastion ~]$ cat << EOF > hosts
[masters]
master1.1b84.internal
master2.1b84.internal
master3.1b84.internal
[infra]
infranode1.1b84.internal
infranode2.1b84.internal
[apps]
node1.1b84.internal
node2.1b84.internal
node3.1b84.internal
[nfs]
support1.1b84.internal
[loadbalancer]
loadbalancer.1b84.internal
EOF
```

## Extructura comando ansible



| commando  |  grupo de servidores | -i archivo hosts | accion |
| --------- | --------- | --------- | --------- |
| ansible  |  masters | -i hosts | --list-hosts |
| ansible  |  infras | -i hosts | --list-hosts |
| ansible  |  all | -i hosts | --list-hosts |

### Ejemplo
```
[user01@bastion ~]$ ansible all -i hosts  --list-hosts
  hosts (10):
    infranode1.1b84.internal
    infranode2.1b84.internal
    support1.1b84.internal
    node1.1b84.internal
    node2.1b84.internal
    node3.1b84.internal
    loadbalancer.1b84.internal
    master1.1b84.internal
    master2.1b84.internal
    master3.1b84.internal
```

## Comandos Ad-hoc usando Modulos
Una vez indentificados los servidores, podemos trabajar con los diferentes modulos de la siguiente forma


| commando | grupo de servidores | -i archivo hosts | modulos | argumentos |
| --------- | --------- | --------- | --------- | --------- |
| ansible  |  masters | -i hosts | -m ping | |
| ansible  |  masters | -i hosts | -m shell | -a hostname |
| ansible  |  masters | -i hosts | -m shell | -a ls /tmp |
| ansible  |  infra | -i hosts | -m shell | -a "ip addr show eth0 |
| ansible  |  all | -i hosts | -m file | -a 'path=/var/tmp/ansible_test.txt state=touch'|
| ansible  |  all | -i hosts | -m file | -a 'path=/var/tmp/ansible_test.txt state=absent'|
| ansible  |  apps | -i hosts | -m copy | -a 'src=/etc/hosts dest=/etc/hosts.jmanuel'|



## Documentacion adicional
un usurio que queira aprender de ansible, lo puede hacer con su documentacion local, todos los modulos tiene sus propios ejemplos

Visualizar todos los manuales
```
[user01@bastion ~]$ ansible-doc -l
```

Visualizar un manual especifico
```
[user01@bastion ~]$ ansible-doc copy
```



Una vez creado el archivo, podemos realizar las verificacion de estos grupos
