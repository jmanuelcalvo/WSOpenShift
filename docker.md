# Crear una aplicacion en docker lista para ejecutarse en OpenShift

1. Cree una cuentas en hub.docker.com

2. Valide que tenga una cuenta en un servidor de repositorios git
http://gogs.apps.2775.example.opentlc.com
user01  - redhat01
user02  - redhat01
user03  - redhat01
user04  - redhat01
user05  - redhat01
O si ya cuenta con una en GitHub
github.com

3. Cree un repo desde al interfase web llamado app01
IMPORTANTE: al momento de crear el repo, seleccione:
Initialize this repositorio with selected files and templates

![Ref](img/projects.png)

4. Dentro de la maquina bastion descargue su repositorio
```
ssh user0X@bastion.2775.example.opentlc.com.     -    password redhat01
git clone http://gogs.apps.2775.example.opentlc.com/jmanuel/app01.git
cd app01
```

5. Cree una archivo Dockerfile con el contenido del software que desea instalar
```
cat << EOF > Dockerfile
FROM centos:7

MAINTAINER Jose Manuel Calvo <jcalvo@redhat.com>

LABEL description="A basic Apache container on RHEL 7"

RUN yum -y install -y httpd && \
    yum clean all && \
    echo "Hello from the httpd container!" > /var/www/html/index.html

EXPOSE 8080

CMD  ["httpd", "-D", "FOREGROUND"]
EOF
```
NOTA1 : Es importante que el contenedor al momento de su ejecucion llame al comando CMD el cual garantiza cual va a ser el proceso de inicio del servicio, en caso que este parametro no se encuentre seteado, la ejecucion del contenedor va a fallar al momento del deploy dentro de OpenShift
NOTA2:  El puerto de exposicion de la imagen sea mayor a 1024, ya que de lo contrario requiere privilegios de ejecucion el en cluster de OpenShift


6. Compile su imagen de contenedor
```
docker build -t docker.io/jmanuelcalvo/app01 .
```

7. Valide que esta image quedo creada correctamente
docker images

8. Realícele las pruebas locales
sudo docker run -d -p 8080:8080 --name=app01 docker.io/jmanuelcalvo/app01

9. Ingrese al contenedor y valide que todo esta funcionando de la forma deseada
sudo docker exec -it app01 bash
exit
sudo docker stop apache01
sudo docker rm apache01

10. En este momento las imagen se encuentra en el cache de su maquina local, publique su imagen de contenedor en su servidor de registro

NOTA: 
 Garantice que su IP p FQDN de registro este permitida por docker para publicar su registro

cat /etc/docker/daemon.json
{
"insecure-registries" : [ "docker-registry-default.apps.2775.example.opentlc.com", "docker.io" ]


docker login docker.io.

sudo docker push docker.io/jmanuelcalvo/app01

Valide en el portal web de su servidor de registro o hub.docker.com que la nueva imagen se encuentre creada

11. No olvide también guardar los cambios de su imagen Dockerfile en el repositorio de git
git config --global user.name "Jose Manuel Calvo
git config --global user.email jmanuel@example.com
git add Dockerfile
git commit -m "Primera version de archivo Dockerfile"
git push

Valide en el portal web del Gogs los archivos de su repositorio








Oc login -u user0X https://loadbalancer.2775.internal:443
