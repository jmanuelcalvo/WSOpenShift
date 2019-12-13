# Despliegue de aplicaciones varias y utiles sobre OpenShift

## 1. Gogs - Go Git Service
Esta ese es un servidor de git similar a github o gitlab, que se puede desplegar sobre OpenShift a traves de una plantilla, de la siguiente forma:

* Cree el proyecto donde se instalara la aplicacion
```
[root@bastion ~]# oc new-project gitproject
Now using project "gitproject" on server "https://loadbalancer.2775.internal:443".

You can add applications to this project with the 'new-app' command. For example, try:

    oc new-app centos/ruby-25-centos7~https://github.com/sclorg/ruby-ex.git

to build a new example application in Ruby.
```

* Importe el la plantilla del proyecto Gogs a sus templates
```
[root@bastion ~]# oc create -f https://raw.githubusercontent.com/OpenShiftDemos/gogs-openshift-docker/master/openshift/gogs-persistent-template.yaml
template.template.openshift.io/gogs created
```
NOTA en caso que no exista la plantilla puede descargar una copia de mi repositorio
```
[root@bastion ~]# oc create -f https://raw.githubusercontent.com/jmanuelcalvo/WSOpenShift/master/gogs-persistent-template.yaml
```
* Desde la interfase web, ingrese al proyecto y busque dentro de las aplicaciones la palabra gogs
![Ref](img/gogs1.png)

* Proceda con el proceso de despliegue
![Ref](img/gogs2.png)

* Por ultimo, debe concer cual es su dominio Wildcard, ya que este debe ser asociado en los parametros de configuracion
![Ref](img/gogs3.png)

* Una vez haga click en el boton create, y espere mientras se finaliza correctamente la creacion de los pods
![Ref](img/gogs4.png)