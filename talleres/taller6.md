# Talleres
[Inicio](../Inicio.md)

### NOTA:
Antes de iniciar a trabajar con Ansible, garantice que las maquinas con las que se va a conectar tengan realcion de confianza por ssh.

# Trabajando con Ansible

Creacion de archivos de inventario agrupando servidores en masters, infra, apps, nfs

```
[user01@bastion ~]$ cat << EOF > hosts
[masters]
master1.b91b.internal
master2.b91b.internal
master3.b91b.internal
[infra]
infranode1.b91b.internal
infranode2.b91b.internal
[apps]
node1.b91b.internal
node2.b91b.internal
node3.b91b.internal
[nfs]
support1.b91b.internal
[loadbalancer]
loadbalancer.b91b.internal
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
    infranode1.b91b.internal
    infranode2.b91b.internal
    support1.b91b.internal
    node1.b91b.internal
    node2.b91b.internal
    node3.b91b.internal
    loadbalancer.b91b.internal
    master1.b91b.internal
    master2.b91b.internal
    master3.b91b.internal
```

## Comandos Ad-hoc usando Modulos
Una vez indentificados los servidores, podemos trabajar con los diferentes modulos de la siguiente forma


| commando | grupo de servidores | -i archivo hosts | modulos | argumentos |
| --------- | --------- | --------- | --------- | --------- |
| ansible  |  masters | -i hosts | -m ping | |
| ansible  |  masters | -i hosts | -m shell | -a hostname |
| ansible  |  masters | -i hosts | -m shell | -a ls /tmp |
| ansible  |  infra | -i hosts | -m shell | -a "ip addr show eth0 |
| ansible  |  all | -i hosts | -m file | -a 'path=/tmp/ansible_jmanuel.txt state=touch'|
| ansible  |  all | -i hosts | -m file | -a 'path=/tmp/ansible_jmanuel.txt state=absent'|
| ansible  |  apps | -i hosts | -m copy | -a 'src=/etc/hosts dest=/tmp/hosts.jmanuel'|
| ansible  |  masters | -i hosts | -m copy | -a 'content="# Hola Mundo" dest=/tmp/hosts.jmanuel'|

Crear un archivo
```
[user01@bastion ~]$ ansible all -i hosts -m file -a 'path=/tmp/ansible_jmanuel.txt state=touch'
[user01@bastion ~]$ ansible all -i hosts -m shell -a 'ls /tmp/ansible_jmanuel.txt'
```
Escribir contenido en el archivo
```
[user01@bastion ~]$ ansible masters -i hosts -m copy -a 'content="# Hola Mundo" dest=/tmp/hosts.jmanuel'
[user01@bastion ~]$ ansible masters -i hosts -m shell -a "cat /tmp/hosts.jmanuel"
```


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

## Creacion de playbooks
A diferencia de los comandos ad-hoc, un usuario puede crear un libro de jugadas (playbooks) con todas las instrucciones que desea llamar

```

[user01@bastion ~]$ cat << copiar.yaml >
---
- name: Mi primer playbook
  hosts: masters
  tasks:
  - name: Crear un archivo con contenido
    copy:
      content: 'Este es mi archivo de configuracion'
      dest: /tmp/jmanuel.conf'
EOF
```

Teniendo en cuenta que la sinstaxis de los archivos yaml es tan delicada con la identacion de los espacios, se debe recomienda hacer la validacion previa

```
[user01@bastion ~]$ ansible-playbook --syntax-check copiar.yaml

playbook: copiar.yaml
```
 ```diff
 - NOTA IMPORTANTE:
 Los espacios en el archivo yaml NO PUEDEN SER TABULADOR, DEBEN SER ESPACIOS
 ```
Ejecutar el playbook
```
[user01@bastion ~]$ ansible-playbook -i hosts copiar.yaml

PLAY [Mi primer playbook] *********************************************************************************************

TASK [Gathering Facts] ************************************************************************************************
ok: [master3.1b84.internal]
ok: [master1.1b84.internal]
ok: [master2.1b84.internal]

TASK [Copy using the 'content' for inline data] ***********************************************************************
changed: [master3.1b84.internal]
changed: [master2.1b84.internal]
changed: [master1.1b84.internal]

PLAY RECAP ************************************************************************************************************
master1.1b84.internal      : ok=2    changed=1    unreachable=0    failed=0
master2.1b84.internal      : ok=2    changed=1    unreachable=0    failed=0
master3.1b84.internal      : ok=2    changed=1    unreachable=0    failed=0
```

El playbook se puede usar varias veces, Ansible es idempotente, lo que quiere decir que si ya se ejecuto la tarea, no se repite

Validar el archivo creado

```
[user01@bastion ~]$ ansible masters -i hosts -m shell -a "cat /tmp/jmanuel.conf"
master3.1b84.internal | SUCCESS | rc=0 >>
# This file was moved to /etc/other.conf

master2.1b84.internal | SUCCESS | rc=0 >>
# This file was moved to /etc/other.conf

master1.1b84.internal | SUCCESS | rc=0 >>
# This file was moved to /etc/other.conf
```









# NOTA:
NO REALIZAR ESTOS PASOS.
De esta forma se alisto el servidor para este ultimo taller
```
[user01@bastion ~]$ cat install-httpd.yaml
- name: Instalar httpd en un servidor
  hosts: loadbalancer.1b84.internal
  tasks:
  - name: Instar el paquete
    yum:
      name: httpd
      state: latest


  - name: Configurar el puerto
    lineinfile:
      dest: /etc/httpd/conf/httpd.conf
      regexp: "^Listen 80"
      line: "Listen 81"
      state: present

  - name: Abrir puerto en el firewall
    firewalld:
      port: 81/tcp
      permanent: true
      state: enabled

  - name: Reiniciar servicio de firewalld
    service:
      name: firewalld
      state: restarted

  - name: Iniciar el servicios
    service:
      name: httpd
      state: started

  - name: Crear carpeta para poner archivos web
    file:
      path: /var/www/html/users/
      state: directory
      mode: 0755
```




# Tarea
Animese a crear un archivo con contenido web en el servidor: loadbalancer.1b84.internal sobre la carpeta /var/www/html/users/ con su nombre .html (ej jmanuel.html) sobre un playbook, utilice los modulos:

* copy 
* template
* file

y una vez ejecute su playbook la forma de validar que su contenido quedo creado sera:
```
[user01@bastion ~]$ elinks  http://loadbalancer.1b84.internal:81/users/jmanuel.html
```
o 
```
[user01@bastion ~]$ curl  http://loadbalancer.1b84.internal:81/users/jmanuel.html
```
