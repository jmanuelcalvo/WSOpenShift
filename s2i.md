# Crear una imagen base S2I (Source to Image) para ejecutarse en OpenShift

Source-to-Image (S2I) is una conjunto de herramientas y un flujo de trabajo para construir imagenes de contenedor que permiten la inyeccion dinamica de codigo fuente dentro de un contenedor al momento de su ejecucion creando un contenedor auto-ensamblado

OpenShift cuenta con multiples imagenes de tipo S2I con los princiales lenguajes de programacion, en algunos casos se utiliza una imagen personalizada por el cliente en los casos en que se desaa que la base S2I contenga algo mas que solo el lenguaje o el framework instalado, para este procedimiento tenga en cuenta los siguientes pasos:


![Ref](talleresd/s2i.png)


1. En Red Hat / CentOS instale habilite el repositiorio s2i
**Red Hat**
Habilitar el repositorio rhel-server-rhscl-7-rpms

**CentOS**
Instalar los paquetes
```
[root@centos ~]# yum install centos-release-scl
[root@centos ~]# yum install source-to-image
```

2. Ingrese a la terminal de la maquina bastion con su usuario de terminal
```
[localhost ~]$ ssh user0X@bastion.2775.example.opentlc.com
```

3. Cree la estrucrtura de datos de S2I (source to image)
s2i create image_name directory
```
[user0X@bastion ~]$ s2i create s2i-test0X s2i-test0X/
```

4. Valide los archivos creados por el comando S2I
```
[user19@bastion ~]$ cd s2i-test0X/
[user19@bastion s2i-test0X]$ tree
.
|-- Dockerfile
|-- Makefile
|-- README.md
|-- .s2i
|   -- bin
|       |-- assemble
|       |-- run
|       |-- save-artifacts
|       `-- usage
`-- test
    |-- run
    -- test-app
        -- index.html
4 directories, 10 files
```

El archivo Dockerfile contiene al igual que en Docker los parametros de instalacion de las aplicaciones

Deje el contenido del archivo Dockerfile similar al siguiente:

```
[user19@bastion s2i-test0X]$ vim Dockerfile
# s2i-test
FROM centos:7

LABEL maintainer="Jose Maneul <jcalvo@redhat.com>"

LABEL io.k8s.description="Platform for building xyz" \
      io.k8s.display-name="builder x.y.z" \
      io.openshift.expose-services="8080:http" \
      io.openshift.s2i.scripts-url="image:///usr/libexec/s2i" \
      io.openshift.tags="builder,webserver,apache,http,html"

ADD httpd.conf.local /tmp/

RUN yum -y install -y httpd && \
    yum clean all &&  \
    groupadd -g 1001 webuser &&  adduser -u 1001 -g 1001 webuser && \
    cp /tmp/httpd.conf.local /etc/httpd/conf/httpd.conf && \
    chown -R 1001:1001 /var/log/httpd && chown -R 1001:1001 /run/httpd && chown -R 1001:1001 /var/www/html/ &&\
    chgrp -R 0 /run && chmod -R g=u /run

COPY ./.s2i/bin/ /usr/libexec/s2i

USER 1001

EXPOSE 8080

CMD ["/usr/libexec/s2i/usage"]

```
Observe con detalle los valores de ***LABEL*** y ***COPY***

Tenga en cuenta tambien que en el ejemplo se esta adicionando un archivo llamado  httpd.conf.local el cual contiene la configuracion del servicio de apache, (definicio de puertos y usuario con quien se ejecutara el servicio)

Observe tambien que se esta adicionando ***ADD*** un archivo **httpd.conf.local** el cual los parametros de configuracion del apache con el nuevo usuario y puerto de ejecucion

Cree el archivo httpd.conf.local con el siguiente contenido


```
[user19@bastion s2i-test0X]$ vim httpd.conf.local
Listen 8080
User webuser
Group webuser

ServerRoot "/etc/httpd"
Include conf.modules.d/*.conf
ServerAdmin root@localhost
<Directory />
    AllowOverride none
    Require all denied
</Directory>
DocumentRoot "/var/www/html"
<Directory "/var/www">
    AllowOverride None
    Require all granted
</Directory>
<Directory "/var/www/html">
    Options Indexes FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>

<IfModule dir_module>
    DirectoryIndex index.html
</IfModule>

<Files ".ht*">
    Require all denied
</Files>

ErrorLog "logs/error_log"

LogLevel warn

<IfModule log_config_module>
    LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
    LogFormat "%h %l %u %t \"%r\" %>s %b" common
    <IfModule logio_module>
      LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" %I %O" combinedio
    </IfModule>
    CustomLog "logs/access_log" combined
</IfModule>

<IfModule alias_module>
    ScriptAlias /cgi-bin/ "/var/www/cgi-bin/"
</IfModule>

<Directory "/var/www/cgi-bin">
    AllowOverride None
    Options None
    Require all granted
</Directory>

<IfModule mime_module>
    TypesConfig /etc/mime.types
    AddType application/x-compress .Z
    AddType application/x-gzip .gz .tgz
    AddType text/html .shtml
    AddOutputFilter INCLUDES .shtml
</IfModule>

AddDefaultCharset UTF-8

<IfModule mime_magic_module>
    MIMEMagicFile conf/magic
</IfModule>

EnableSendfile on

IncludeOptional conf.d/*.conf
```

## Scripts de S2I

La construccion de imagenes con s2i cuenta con 3 scripts especiales que son:

**.s2i/bin/assemble** Este script se encarga de inyectar los datos desde una fuente a una ruta especifica del contenedor

```
[user19@bastion s2i-test0X]$ vim .s2i/bin/assemble
#!/bin/bash -e
#
# S2I assemble script for the 's2i-test' image.
# The 'assemble' script builds your application source so that it is ready to run.
#
# For more information refer to the documentation:
#	https://github.com/openshift/source-to-image/blob/master/docs/builder_image.md
#

# If the 's2i-test' assemble script is executed with the '-h' flag, print the usage.
if [[ "$1" == "-h" ]]; then
	exec /usr/libexec/s2i/usage
fi

# Restore artifacts from the previous build (if they exist).
#
if [ "$(ls /tmp/artifacts/ 2>/dev/null)" ]; then
  echo "---> Restoring build artifacts..."
  mv /tmp/artifacts/. ./
fi

echo "---> Installing application source..."

cp -Rf /tmp/src/. /var/www/html

echo "---> Building application from source..."
# TODO: Add build steps for your application, eg npm install, bundle install, pip install, etc.
````

**NOTA** Presete especial atencion a la linea que realiza el copiado de la informacion a la carpeta de datos del apache **/var/www/html**


Cuando esta imagen es utilizada en OpenShift el git clone con el codigo fuente es descargado en un contenedor temporal en la carpeta /tmp/src/ y enviado al contendor definitivo a la carpeta /var/www/html.


**.s2i/bin/run** Este script es llamado de forma automatica una vez la imagen sea ejecutada como contenedor, este script es quien debe inciar el servicio, similar al CMD dentro del los archivos Dockerfile

```
#!/bin/bash -e
#
# S2I run script for the 's2i-test' image.
# The run script executes the server that runs your application.
#
# For more information see the documentation:
#	https://github.com/openshift/source-to-image/blob/master/docs/builder_image.md
#

exec httpd -D FOREGROUND
```
Indique cual es el comando de inicio de servicio de http

***Makefile*** El archivo make contiene los comandos relacionados con el docker build, por lo que para la compilacion de la imagen puede usar el comando docker build usado en los talleres de docker o simplemente ejecutar el comando make

```
IMAGE_NAME = s2i-test0X

build:
	docker build -t $(IMAGE_NAME) .

.PHONY: test
test:
	docker build -t $(IMAGE_NAME)-candidate .
	IMAGE_NAME=$(IMAGE_NAME)-candidate test/run
```  



5. Compilacion de la imagen.
Dentro de la carpeta s2i-test0X ejecute el comando **make**

```
[user19@bastion s2i-test0X]$ make
docker build -t s2i-test0X .
Sending build context to Docker daemon 17.41 kB
Step 1/9 : FROM centos:7
 ---> 5e35e350aded
Step 2/9 : LABEL maintainer "Jose Maneul <jcalvo@redhat.com>"
 ---> Running in 50e2bec7c376
 ---> 9abf463f39b9
Removing intermediate container 50e2bec7c376
Step 3/9 : LABEL io.k8s.description "Platform for building xyz" io.k8s.display-name "builder x.y.z" io.openshift.expose-services "8080:http" io.openshift.s2i.scripts-url "image:///usr/libexec/s2i" io.openshift.tags "builder,webserver,apache,http,html"
 ---> Running in 146440db1088
 ---> e18734663d63
...
...
...
Removing intermediate container 0634bcf1a39b
Step 8/9 : EXPOSE 8080
 ---> Running in 4e1f57c229eb
 ---> 02b2109f4eab
Removing intermediate container 4e1f57c229eb
Step 9/9 : CMD /usr/libexec/s2i/usage
 ---> Running in ee764db523d1
 ---> 026a39defc60
Removing intermediate container ee764db523d1
Successfully built 026a39defc60
```

Este comando genera una nueva imagen de Docker


```
[user19@bastion s2i-test0X]$ docker images
REPOSITORY                                                                     TAG                 IMAGE ID            CREATED              SIZE
s2i-test0X                                                                     latest              026a39defc60        About a minute ago   260 MB
```


6. Realizacion de pruebas locales de inyectar codigo a la nueva imagen.

```
[user0X@bastion s2i-test]$ echo "Codigo" > test/test-app/index.html
s2i build test/test-app s2i-test0X s2i-test0X
I1217 01:24:32.241433 22615 install.go:251] Using "assemble" installed from "image:///usr/libexec/s2i/assemble"
I1217 01:24:32.241624 22615 install.go:251] Using "run" installed from "image:///usr/libexec/s2i/run"
I1217 01:24:32.241642 22615 install.go:251] Using "save-artifacts" installed from "image:///usr/libexec/s2i/save-artifacts"
---> Installing application source...
---> Building application from source...
```
Ejecutar el contenedor y validar por dentro el codigo
```
[user0X@bastion s2i-test]$ docker run -it -p 8080:8080 http-test bash
[webuser@65531d48772c /]$ cd /var/www/html/
[webuser@65531d48772c html]$ ls
index.html
[webuser@65531d48772c html]$ cat index.html
Codigo
```

7. En caso que la imagen s2i funcione de acuerdo a lo esperado, los siguientes pasos seran, cargarla al repositorio de docker para posteriormente ser cargada como imagen base a openshift


```
[user19@bastion s2i-test0X]$ docker tag s2i-test0X docker.io/jmanuelcalvo/s2i-test0X:latest
```
Recuerde estar logueado en Docker
```
[user19@bastion s2i-test0X]$ docker login docker.io
Login with your Docker ID to push and pull images from Docker Hub. If you don't have a Docker ID, head over to https://hub.docker.com to create one.
Username: jmanuelcalvo
Password:
Login Succeeded
[user19@bastion s2i-test0X]$ docker push docker.io/jmanuelcalvo/s2i-test0X:latest
The push refers to a repository [docker.io/jmanuelcalvo/s2i-test0X]
737b54fff43f: Pushed
d72a99aa43e7: Pushed
4dc0b923d868: Pushed
a255d8ff5a53: Pushed
adfdc6f3d57b: Pushed
77b174a6a187: Pushed
latest: digest: sha256:ab51e7fab4ec641f54a1973ead0495606f276799e0a6a5fdec3cab3370da0b35 size: 1570
```
8. Importar la imagen a OpenShift
Garantice que este logueado sobre OpenShift y sobre el proyecto que desea importar dicha imagen.

**NOTA:** Recuerde que en caso de querer que la imagen sea visualizada por todos los proyectos y usuarios de OpenShift, la imagen se debe importar en el  proyecto/namespace openshift.

```
[root@bastion ~]$ oc login -u user0X https://loadbalancer.2775.internal:443

[user0X@bastion ~]$ oc whoami
user19

[user19@bastion s2i-test0X]$ oc new-project s2i-test0X
Now using project "s2i-test0X" on server "https://loadbalancer.2775.internal:443".

You can add applications to this project with the 'new-app' command. For example, try:

    oc new-app centos/ruby-25-centos7~https://github.com/sclorg/ruby-ex.git

to build a new example application in Ruby.

[user19@bastion s2i-test0X]$ oc import-image s2i-test0X --from docker.io/jmanuelcalvo/s2i-test0X:latest --confirm --insecure=true
imagestream.image.openshift.io/s2i-test0X imported

[user19@bastion s2i-test0X]$ oc get is
NAME         DOCKER REPO                                              TAGS      UPDATED
s2i-test0X   docker-registry.default.svc:5000/s2i-test0X/s2i-test0X   latest    25 seconds ago
```

9. Por ultimo cree una aplicacion utilizando su nueva imagen

```
[user0X@bastion ~]$ oc new-app s2i-test0X~https://github.com/jmanuelcalvo/app.git --name=app0X
```
