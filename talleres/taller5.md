# Talleres
[Inicio](../Inicio.md)

# Backup OpenShift

Informacion oficial del proceso de backup y restauracion de OCP
https://docs.openshift.com/dedicated/3/admin_guide/assembly_backing-up-restoring-project-application.html

### NOTA para este taller se crea un nuevo proyecto y se crea una nueva aplicacion

## Backup de Proyectos
Existe un procedimiento que se puede utilizar para realizar copias de seguridad de proyectos. El comando de exportación oc se utiliza para hacer una copia de seguridad de los objetos a nivel de proyecto. Ejecute el comando para cada objeto que se guardará. Por ejemplo, para hacer una copia de seguridad del archivo de configuración de implementación front-end llamado frontend como dc-frontend en formato YAML, ejecute el siguiente comando:

```
[user@master ~]$ oc export dc frontend -o yaml > dc-frontend.yaml
```
Backup de un proyecto entero.
Valide el proyecto en el que se encuentra actualmente
```
[user01@bastion ~]$ oc new-project user0X-backup
[user01@bastion ~]$ oc project
Using project "user0X-backup" on server "https://loadbalancer.1b84.example.opentlc.com:443".
```
Cree una nueva aplicacion
```
[user01@bastion ~]$ oc new-app php~https://github.com/jmanuelcalvo/app.git --name=backup
[user10@bastion backup]$ oc expose  svc backup
```

Cree una carpeta donde almacenara los backups
```
[user01@bastion ~]$ mkdir backup
[user01@bastion ~]$ cd backup/
[user01@bastion backup]$ oc get -o yaml --export all > project.yaml
```
Exporte los role bindings, secrets, service accounts, y persistent volume claims del proyecto
```
$ for object in rolebindings serviceaccounts secrets imagestreamtags cm egressnetworkpolicies rolebindingrestrictions limitranges resourcequotas pvc templates cronjobs statefulsets hpa deployments replicasets poddisruptionbudget endpoints
do
  oc get -o yaml --export $object > $object.yaml
done
```

Verifique el contenido del archivo generado
```
[user01@bastion backup]$ more project.yaml
```

## Application Data Backup
Use el comando oc rsync para hacer una copia de seguridad de los datos de la aplicación cuando rsync está instalado dentro de un contenedor. También puede usar soluciones de almacenamiento como Cinder, Gluster y NFS.

Verifique los pods que se encuentran creados
```
[user01@bastion ~]$ oc get pod
NAME             READY     STATUS      RESTARTS   AGE
backup-1-build   0/1       Completed   0          6m
backup-1-sstcd   1/1       Running     0          5m
```
Ingrese a ellos y ubique la carpeta donde se encuentran los datos
Para las imagenes con PHP la carpeta de datos es
/opt/app-root/src

Para las imagenes con MySQL la carpeta de datos es:
/var/lib/mysql/data
```
[user01@bastion backup]$ oc rsh backup-1-sstcd
sh-4.2$ pwd
/opt/app-root/src


```
Descargue a la carpeta local los datos a traves de rsync
```
[user01@bastion backup]$ oc rsync backup-1-sstcd:/opt/app-root/src .
```

## Project Restore
Para restaurar un proyecto, debe volver a crear todo el proyecto y todos los objetos que se exportaron durante el procedimiento de copia de seguridad. Use el comando oc create para restaurar los objetos que se guardaron.

Elimine el proyecto
```
[user01@bastion backup]$ oc delete project user0X-backup
project.project.openshift.io "user0X-backup" deleted
```
Cree nuevamente el proyecto 
###NOTA: El nombre del proyecto debe ser igual al anterior
```
[user01@bastion backup]$ oc new-project  user0X-backup
Already on project "user0X-backup" on server "https://loadbalancer.1b84.example.opentlc.com:443".

You can add applications to this project with the 'new-app' command. For example, try:

    oc new-app centos/ruby-25-centos7~https://github.com/sclorg/ruby-ex.git

to build a new example application in Ruby.
```

Verifique que no exista ningun recurso
```
[user01@bastion backup]$ oc get all
No resources found.
```
Cargue los recursos de nuevo proyecto
```diff
- NOTA: Tenga en cuenta que este comando muestra algunos errores, haga caso omiso
```
```
[user01@bastion backup]$  oc create -f secret.yaml
[user01@bastion backup]$  oc create -f serviceaccount.yaml
[user01@bastion backup]$  oc create -f pvc.yaml
[user01@bastion backup]$  oc create -f rolebindings.yaml
[user01@bastion backup]$ oc create -f project.yaml
[user01@bastion ~]$ oc get pod
NAME             READY     STATUS      RESTARTS   AGE
backup-1-build   0/1       Completed   0          6m
backup-1-sstcd   1/1       Running     0          5m

```

En nuestro caso, la aplicacion fue creada a partir de un proceso del build, por lo que se debe indicar al OpenShift que cree una nueva imagen a partir del proceso S2I

```
[user10@bastion backup]$ oc start-build backup
```

Para validar que el proyecto se restauro de forma correcta, valide la ruta con el comando e intente conectarse desde el navegador o con el cliente cURL
```
[user10@bastion backup]$ oc get route
```

```
[user10@bastion backup]$ curl -k https://backup-user0X-backup.apps.b91b.example.opentlc.com
```
