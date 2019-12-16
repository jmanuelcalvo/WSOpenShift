# Crear una imagen base S2I (Source to Image) para ejecutarse en OpenShift

Source-to-Image (S2I) is una conjunto de herramientas y un flujo de trabajo para construir imagenes de contenedor que permiten la inyeccion dinamica de codigo fuente dentro de un contenedor al momento de su ejecucion creando un contenedor auto-ensamblado

OpenShift cuenta con multiples imagenes de tipo S2I con los princiales lenguajes de programacion, en algunos casos se utiliza una imagen personalizada por el cliente en los casos en que se desaa que la base S2I contenga algo mas que solo el lenguaje o el framework instalado, para este procedimiento tenga en cuenta los siguientes pasos:


![Ref](talleresd/s2i.png)


1. En Red Hat / CentOS instale habilite el repositiorio s2i
Red Hat
habilitar el repositorio rhel-server-rhscl-7-rpms
Instalar el paquete
yum install source-toimage


2. Ingrese a la terminal de la maquina bastion con su usuario

3. Cree la estrucrtura de datos de S2I
s2i create image_name directory
```
[user0X@bastion ~]$ s2i create s2i-test s2i-test/
```

4. Valide los archivos creados por el comando S2I
```
tree
.
|-- Dockerfile
|-- Makefile
|-- README.md
|-- s2i
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

```
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

COPY ./s2i/bin/ /usr/libexec/s2i

USER 1001

EXPOSE 8080

CMD ["/usr/libexec/s2i/usage"]
```
Observe con detalle los valores de ***LABEL*** y ***COPY***

Tenga en cuenta tambien que en el ejemplo se esta adicionando un archivo llamado  httpd.conf.local el cual contiene la configuracion del servicio de apache, (definicio de puertos y usuario con quien se ejecutara el servicio)

## Scripts de S2I

La construccion de imagenes con s2i cuenta con 3 scripts especiales que son:

**s2i/bin/assemble** Este script se encarga de inyectar los datos desde una fuente a una ruta especifica del contenedor

```
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
Cuando esta imagen es utilizada en OpenShift el git clone con el codigo fuente es descargado en un contenedor temporal en la carpeta /tmp/src/ y enviado al contendor definitivo a la carpeta /var/www/html.


**s2i/bin/run** Este script es llamado de forma automatica una vez la imagen sea ejecutada como contenedor, este script es quien debe inciar el servicio, similar al CMD dentro del los archivos Dockerfile

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
***Makefile*** El archivo make contiene los comandos relacionados con el docker build, por lo que para la compilacion de la imagen puede usar el comando docker build usado en los talleres de docker o simplemente ejecutar el comando make

```
IMAGE_NAME = s2i-test

.PHONY: build
build:
	docker build -t $(IMAGE_NAME) .

.PHONY: test
test:
	docker build -t $(IMAGE_NAME)-candidate .
	IMAGE_NAME=$(IMAGE_NAME)-candidate test/run
```  



5. Compilacion de la imagen.
Ingrese a la carpeta s2i-test y ejecute el comando make

```
[user0X@bastion ~]$ cd s2i-test
[user0X@bastion s2i-test]$ make
docker build -t s2i-test .
Sending build context to Docker daemon  22.02kB
Step 1/8 : FROM centos:7
 ---> 5e35e350aded
Step 2/8 : LABEL maintainer="Jose Maneul <jcalvo@redhat.com>"
 ---> Running in 427292e9db1a
Removing intermediate container 427292e9db1a
 ---> e5c643e19673
Step 3/8 : LABEL io.k8s.description="Platform for building xyz"       io.k8s.display-name="builder x.y.z"       io.openshift.expose-services="8080:http"       io.openshift.tags="builder,x.y.z,etc."
 ---> Running in c43a9983e9bb
Removing intermediate container c43a9983e9bb
 ---> 52ec83463cd5
Step 4/8 : RUN yum -y install -y httpd &&     yum clean all &&      sed 's/^Listen 80/Listen 8080/g' /etc/httpd/conf/httpd.conf > /etc/httpd/conf/httpd.conf.new  &&      cp /etc/httpd/conf/httpd.conf.new  /etc/httpd/conf/httpd.conf
 ---> Running in a275333dba2a
Loaded plugins: fastestmirror, ovl
Determining fastest mirrors
...
...
...
Removing intermediate container 243222d32300
 ---> 70421821177e
Step 8/8 : CMD ["/usr/libexec/s2i/usage"]
 ---> Running in b3891094810a
# s2i-test
Removing intermediate container b3891094810a
 ---> 1d7a093f3f3a
Successfully built 1d7a093f3f3a
````

Este comando genera una nueva imagen de Docker


```
[user0X@bastion s2i-test]$  docker images
REPOSITORY                  TAG                 IMAGE ID            CREATED              SIZE
s2i-test                    latest              1d7a093f3f3a        About a minute ago   260MB
nginx-test                  latest              6f171ecf1892        10 minutes ago       248MB
```


6. Realizacion de pruebas locales de inyectar codigo a la nueva imagen.

```
[user0X@bastion s2i-test]$ s2i build test/test-app s2i-test http-test
---> Installing application source...
---> Building application from source...
Build completed successfully
```
Ejecutar el contenedor y validar por dentro el codigo
```
[user0X@bastion s2i-test]$ docker run -it -p 8080:8080 http-test bash
[webuser@3f5606855b68 /]$ cd /var/www/html/
[webuser@3f5606855b68 html]$ ls
index.html
[webuser@3f5606855b68 html]$ cat index.html
<!doctype html>
<html>
	<head>
		<title>Hello World!</title>
	</head>
	<body>
		<h1>Hello World!</h1>
	</body>
</html>
```

7. En caso que la imagen s2i funcione de acuerdo a lo esperado, los siguientes pasos seran, cargarla al repositorio de docker para posteriormente ser cargada como imagen base a openshift


```
[user0X@bastion s2i-test]$ docker tag s2i-test:latest docker.io/jmanuelcalvo/s2i-test:latest
[user0X@bastion s2i-test]$ docker push docker.io/jmanuelcalvo/s2i-test:latest
```
8. Importar la imagen a OpenShift
Garantice que este logueado sobre OpenShift y sobre el proyecto que desea importar dicha imagen.

**NOTA:** Recuerde que en caso de querer que la imagen sea visualizada por todos los proyectos y usuarios de OpenShift, la imagen se debe importar en el  proyecto/namespace openshift.

```
[user0X@bastion ~]$ oc whoami

[user0X@bastion ~]$ oc import-image s2i-test --from docker.io/jmanuelcalvo/s2i-test/s2i-test --confirm --insecure=true

[user0X@bastion ~]$ oc get is
```

9. Por ultimo cree una aplicacion utilizando su nueva imagen

```
[user0X@bastion ~]$ oc new-app http-test~https://github.com/jmanuelcalvo/app.git --name=app0X
```
