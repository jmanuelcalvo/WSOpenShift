# Crear una aplicacion en docker lista para ejecutarse en OpenShift

**NOTA** Antes de iniciar
1. Cree una cuentas en hub.docker.com

**NOTA:** Tenga en cuenta que los ejempos y salidas de comeando se realizan con el usuario del repositorio de cada alumno, reemplace la palabra *docker-repo** este por el nombre de su usuario, en mi caso ejemplo el usuario es jmanuelcalvo

2. Valide que tenga una cuenta en un servidor de repositorios git

http://git.apps.b91b.example.opentlc.com/

* user01  - redhat01
* user02  - redhat01
* user03  - redhat01
* user04  - redhat01
* user05  - redhat01

O si ya cuenta con una en GitHub github.com

3. Cree un repo desde al interfase web llamado app01
**IMPORTANTE**: al momento de crear el repo, seleccione:

***Initialize this repositorio with selected files and templates***

![Ref](img/app01.png)

4. Dentro de la maquina bastion descargue su repositorio
```
[user0X@bastion ~]$ ssh user0X@bastion.b91b.example.opentlc.com     -    password redhat01
[user0X@bastion ~]$ git clone http://gogs.apps.$GUID.example.opentlc.com/user0X/app0X.git
[user0X@bastion ~]$ cd app0X
```

5. Cree una archivo Dockerfile con el contenido del software que desea instalar, reemplace los datos del **MAINTAINER** por su nombre y comando **Hello** por su mensaje personalizado

```
[user0X@bastion ~]$ vi Dockerfile
FROM centos:7

MAINTAINER Jose Manuel Calvo <jcalvo@redhat.com>

LABEL description="A basic Apache container on RHEL 7"

RUN yum -y install -y httpd && \
    yum clean all && \
    sed 's/^Listen 80/Listen 8080/g' /etc/httpd/conf/httpd.conf > /etc/httpd/conf/httpd.conf.1 && \
    cp /etc/httpd/conf/httpd.conf.1 /etc/httpd/conf/httpd.conf \
RUN echo "Hello from the httpd container!" > /var/www/html/index.html

EXPOSE 8080

CMD  ["httpd", "-D", "FOREGROUND"]
EOF
```

***NOTA1*** : Es importante que el contenedor al momento de su ejecucion llame al comando CMD el cual garantiza cual va a ser el proceso de inicio del servicio, en caso que este parametro no se encuentre seteado, la ejecucion del contenedor va a fallar al momento del deploy dentro de OpenShift.

***NOTA2***:  El puerto de exposicion de la imagen sea mayor a 1024, ya que de lo contrario requiere privilegios de ejecucion el en cluster de OpenShift.


6. Compile su imagen de contenedor
```
[user0X@bastion ~]$ sudo docker build -t docker.io/docker-repo/app01 .
```

7. Valide que esta image quedo creada correctamente
```
[user0X@bastion ~]$ sudo docker images
```

8. Realícele las pruebas locales
```
[user0X@bastion ~]$ sudo docker run -d -p 80XX:8080 --name=app0X docker.io/docker-repo/app01
```

9. Ingrese al contenedor y valide que todo esta funcionando de la forma deseada
```
[user0X@bastion ~]$ sudo docker exec -it app0X bash
exit
[user0X@bastion ~]$ sudo docker stop app0X
[user0X@bastion ~]$ sudo docker rm app0X
```

10. En este momento las imagen se encuentra en el cache de su maquina local, publique su imagen de contenedor en su servidor de registro

NOTA:
 Garantice que su IP p FQDN de registro este permitida por docker para publicar su registro
```
[user0X@bastion ~]$ cat /etc/docker/daemon.json
{
"insecure-registries" : [ "docker-registry-default.apps.2775.example.opentlc.com", "docker.io" ]
```
En caso de contar realizar las pruebas con un servidor de registro alterno, indique por favor al facilitador para adicionarlo en la lista de servidores de registro autoriados

```
[user0X@bastion ~]$ sudo docker login docker.io
[user0X@bastion ~]$ sudo docker push docker.io/docker-repo/app0X
```
Valide en el portal web de su servidor de registro o hub.docker.com que la nueva imagen se encuentre creada

![Ref](img/app02.png)


11. No olvide también guardar los cambios de su imagen Dockerfile en el repositorio de git
```
[user10@bastion ~]$ git config --global user.email "jcalvo@redhat.com"
[user10@bastion ~]$ git config --global user.name "Jose Manuel Calvo"
[user0X@bastion ~]$ git add Dockerfile
[user0X@bastion ~]$ git commit -m "Primera version de archivo Dockerfile"
[user0X@bastion ~]$ git push
```

Valide en el portal web del Gogs los archivos de su repositorio

12. Loguese al OpenShift e intente desplegar la aplicacion a partir de un contenedor

```
[user0X@bastion ~]$ oc login -u user0X https://loadbalancer.2775.internal:443
[user0X@bastion ~]$ oc new-project app0X
Now using project "app0X" on server "https://loadbalancer.2775.internal:443".

You can add applications to this project with the 'new-app' command. For example, try:

    oc new-app centos/ruby-25-centos7~https://github.com/sclorg/ruby-ex.git

to build a new example application in Ruby.
```

Teniendo en cuenta que el contenedor de Apache requiere privilegios de root para iniciar el servicio, como usuario admin, se asignaran privilegios de ejecucion sobre los contenedores.

NOTA: esto **NO** es lo mas recomendado, en los siguientes ejercicios se revisara en mayor detalle

Logueese como usuario admin y permita la creacion de contenedore dentro de OpenShift como usuario root
```
[user0X@bastion ~]$ oc login -u admin1 -p redhat01

[user0X@bastion ~]$ oc adm policy add-scc-to-user anyuid -z default

[user0X@bastion ~]$ oc login -u user0X
Logged into "https://loadbalancer.2775.internal:443" as "user0X" using existing credentials.

You have access to the following projects and can switch between them with 'oc project <projectname>':

  * app01
    etherpad

Using project "app01".
```
Ahora ejecute una contenedor en OpenShift desde dockerhub

```
[user0X@bastion ~]$ oc new-app --name app01 --insecure-registry --docker-image="docker.io/docker-repo/app01:latest"
--> Found Docker image 5d8ddbd (2 hours old) from docker.io for "docker.io/docker-repo/app01:latest"

    * An image stream tag will be created as "app01:latest" that will track this image
    * This image will be deployed in deployment config "app01"
    * Port 80/tcp will be load balanced by service "app01"
      * Other containers can access this service through the hostname "app01"
    * WARNING: Image "docker.io/docker-repo/app01:latest" runs as the 'root' user which may not be permitted by your cluster administrator

--> Creating resources ...
    imagestream.image.openshift.io "app01" created
    deploymentconfig.apps.openshift.io "app01" created
    service "app01" created
--> Success
    Application is not exposed. You can expose services to the outside world by executing one or more of the commands below:
     'oc expose svc/app01'
    Run 'oc status' to view your app.

[user0X@bastion ~]$ oc get pod
NAME            READY     STATUS    RESTARTS   AGE
app01-1-hsz5n   1/1       Running   0          6s

```

13. Exponga la ruta y conectese al servicio

```
[user0X@bastion ~]$ oc get svc
NAME      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
app01     ClusterIP   172.30.100.94   <none>        80/TCP    1m

[user0X@bastion ~]$ oc expose svc app01
route.route.openshift.io/app01 exposed

[user0X@bastion ~]$ oc get route
NAME      HOST/PORT                                   PATH      SERVICES   PORT      TERMINATION   WILDCARD
app01     app01-app01.apps.2775.example.opentlc.com             app01      80-tcp                  None

[user0X@bastion ~]$ curl  app01-app01.apps.2775.example.opentlc.com
Hola from the httpd container!
```
