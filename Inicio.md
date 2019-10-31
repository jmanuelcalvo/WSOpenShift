# Acceso Cluster OpenShift Workshop Ecuador

## Arquitectura de referencia

![Ref](Base OpenShift Diagram - Arch Pods.png)


## Por Navegador
```
https://loadbalancer.1b84.example.opentlc.com/
```

## Acceso por SSH a la maquina Bastion
```
ssh user40@bastion.1b84.example.opentlc.com
oc login https://loadbalancer.1b84.internal:443 -u user40 -p redhatXX
```


## Facilitador / Consultor Red Hat
Jose Manuel Calvo I


# Laboratorios
[Taller 1](talleres/taller1.md) - Iniciando con OpenShift - Comandos, creacion de recursos (proyectos, apps, svc, routes)

[Taller 2](talleres/taller2.md) - Volumenes Persistentes, ConfigMap y Secrets

[Taller 3](talleres/taller3.md) - Aplicaciones complejas (FrontEnd + BD + Datos Persistentes) 

[Taller 4](talleres/taller4.md) - Trabajo con contenedores Docker

[Taller 5](talleres/taller5.md) - Backup de OpenShift

[Taller 6](talleres/taller6.md) - Tareas automatizadas con Ansible, Primeros pasos




# Almacenamiento

* Creacion de configMap
* Creacion de Secret
### Ver taller 2

# Backup OpenShift
### Ver taller 5

Informacion oficial del proceso de backup y restauracion de OCP
https://docs.openshift.com/dedicated/3/admin_guide/assembly_backing-up-restoring-project-application.html

# Operacion Cluster OpenShift - Varios
Procedimiento de apagado/mantenimiento de un nodo de OpenShift
https://docs.openshift.com/container-platform/3.11/admin_guide/manage_nodes.html
```
[root@bastion ~]# oc adm manage-node node3.1b84.internal --schedulable=false
[root@bastion ~]# oc adm drain node3.1b84.internal --delete-local-data --ignore-daemonsets
[root@bastion ~]# ssh  node3.1b84.internal reboot
```
Cuando el nodo vuelva a estar disponible, se debe poner nuevamente en status schedulable
```
[root@bastion ~]# oc adm manage-node node3.1b84.internal --schedulable=true
```

## Red Hat Insights
https://access.redhat.com/products/red-hat-insights/#getstarted




