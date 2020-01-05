1. Ingrese al portal lab.opentlc.com

2. Solicite el laboratorio: Services -> Catalogs -> All Services -> OPENTLC OpenShift Labs -> OpenShift HA Lab

3. Una vez cuente con los datos en el correo ingrese a la maquina bastion
```
ssh jcalvo-redhat.com@bastion.0bf3.example.opentlc.com
The authenticity of host 'bastion.0bf3.example.opentlc.com (3.215.65.147)' can't be established.
ECDSA key fingerprint is SHA256:V+kgu+3Hz4FTqYgPB7uU7Pz+TBQPdgKyuZKumuE0QFc.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added 'bastion.0bf3.example.opentlc.com,3.215.65.147' (ECDSA) to the list of known hosts.
Creating home directory for jcalvo-redhat.com.

```
4. Cambiese al usuario root
```
[jcalvo-redhat.com@bastion ~]$ sudo su -
```

5. Descargue el contenido del WorkShop
```
[root@bastion ~]# git clone https://github.com/jmanuelcalvo/WSOpenShift.git
Cloning into 'WSOpenShift'...
remote: Enumerating objects: 7, done.
remote: Counting objects: 100% (7/7), done.
remote: Compressing objects: 100% (6/6), done.
remote: Total 799 (delta 1), reused 5 (delta 1), pack-reused 792
Receiving objects: 100% (799/799), 8.48 MiB | 0 bytes/s, done.
Resolving deltas: 100% (401/401), done.
```
Ingrese a la carpeta
```
[root@bastion ~]# cd WSOpenShift/
```

6. Identifique su ID del laboratorio, este puede estar en el correo que llega de OpenTLC o a traves del nombre de la maquina: EJ 0bf3
```
[root@bastion WSOpenShift]# hostname
bastion.0bf3.example.opentlc.com
```

7. Con este ID, ingrese al script de instalacion y cambie la variable
```
[root@bastion WSOpenShift]# vim install.sh
GUID=193d
por su nuevo ID ejemplo
GUID=0bf3
```
8. Por ultimo edite el archivo hosts y cambien por su usuario y token
```
oreg_auth_user=""
oreg_auth_password=""
```
En caso de no contar con usuario, el archivo encriptado key contiene mis datos, contecteme para darle al contraseña
```
vim key
```
9. Todo listo para inciar la instalacion, ejecute el scriopt 
```
[root@bastion WSOpenShift]# sh install.sh
Validando que las maquinas este OK
```
Tenga en cuenta que este script espera 2 Enter o Ctrl + C luego de hacer unos pasos de validaciones previas 
