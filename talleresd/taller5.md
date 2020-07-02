[Talleres de Despliegue](../despliegue.md)

OpenShift cuenta con la implementacion de multiples proyectos implementados dentro del mismo Cluster de OpenShift los cuales permiten realizar temas como Monitoreo y  auditoria de logs entre otros.

# Metricas del cluster 
El proyecto llamado `openshift-infra` el cual esta compuesto por 3 componentes:
* Heapster
* Hawkular
* Cassandra 

![Ref](metricas01 .png)


El agente kubelet expone métricas que Heapster puede recopilar y almacenar en back-end, Hawkular Metrics actua como un motor de métricas que almacena los datos de forma persistente en una base de datos Cassandra

Cuando se ingresa las primera veces a la interfase web de OpenShift se podra visualizar un mensaje como este: an error ocurred getting metrics

![Ref](metricas02 .png)

Esto se debe a que el componente Hawkular esta desplegado por HTTPS con un certificado autofirmado, para ello se debe aceptar el certificado digital en el navegador de la siguiente forma:

![Ref](metricas03 .png)

![Ref](metricas04 .png)

y una vez aceptado el certificado deberiamos visualizar el logo del proyecto Hawkular

![Ref](metricas05 .png)

De ser asi, se debe volver a la interfase web de OpenShift y recargar la interfase (F5) y ahora se deberia poder conocer la informacion de uso de los contenedores de una forma visual

![Ref](metricas05 .png)


